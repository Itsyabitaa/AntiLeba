import { Logger, UnauthorizedException } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';

import { CommandsService } from './commands.service';
import { AckCommandDto } from './dto/ack-command.dto';
import type { WsAuthContext } from './ws-auth.service';
import { WsAuthService } from './ws-auth.service';
import { DevicesService } from '../devices/devices.service';

interface DeviceSocketData {
  auth?: WsAuthContext;
  deviceId?: string;
}

@WebSocketGateway({
  namespace: '/commands',
  cors: { origin: true, credentials: true },
})
export class CommandsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(CommandsGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly commands: CommandsService,
    private readonly devices: DevicesService,
    private readonly wsAuth: WsAuthService,
  ) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const auth = await this.wsAuth.authenticate(client);
      (client.data as DeviceSocketData).auth = auth;
    } catch (error) {
      const message =
        error instanceof UnauthorizedException
          ? error.message
          : 'Unauthorized';
      this.logger.warn(`WS rejected: ${message}`);
      client.emit('error', { message });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    const deviceId = (client.data as DeviceSocketData).deviceId;
    if (deviceId) {
      this.logger.debug(`Device disconnected from room device:${deviceId}`);
    }
  }

  @SubscribeMessage('device:register')
  async registerDevice(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { deviceId?: string },
  ): Promise<{ ok: boolean; pending: number }> {
    const auth = this.requireAuth(client);
    const deviceId = body?.deviceId;
    if (!deviceId) {
      throw new UnauthorizedException('deviceId is required');
    }

    await this.devices.findByIdForUser(deviceId, auth.userId);

    this.commands.assertDeviceConnection(
      auth.userId,
      deviceId,
      auth.sessionDeviceId,
    );

    (client.data as DeviceSocketData).deviceId = deviceId;
    await client.join(this.deviceRoom(deviceId));

    const pending = await this.commands.findPendingForDevice(deviceId);
    for (const command of pending) {
      await this.pushCommand(deviceId, command.id);
    }

    this.logger.log(`Device registered on WS: ${deviceId}`);
    return { ok: true, pending: pending.length };
  }

  @SubscribeMessage('command:ack')
  async ackCommand(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: AckCommandDto,
  ): Promise<{ ok: boolean }> {
    const auth = this.requireAuth(client);
    const boundDeviceId = (client.data as DeviceSocketData).deviceId;
    if (!boundDeviceId || boundDeviceId !== dto.deviceId) {
      throw new UnauthorizedException('Device not registered on this socket');
    }

    await this.commands.ack(auth.userId, dto);
    return { ok: true };
  }

  async deliverPending(deviceId: string, commandId: string): Promise<boolean> {
    return this.pushCommand(deviceId, commandId);
  }

  private async pushCommand(
    deviceId: string,
    commandId: string,
  ): Promise<boolean> {
    const room = this.deviceRoom(deviceId);
    const sockets = await this.server.in(room).fetchSockets();
    if (sockets.length === 0) {
      return false;
    }

    const command = await this.commands.markDelivered(commandId, deviceId);
    this.server.to(room).emit('command:execute', this.commands.toPayload(command));
    return true;
  }

  private requireAuth(client: Socket): WsAuthContext {
    const auth = (client.data as DeviceSocketData).auth;
    if (!auth) {
      throw new UnauthorizedException('Not authenticated');
    }
    return auth;
  }

  private deviceRoom(deviceId: string): string {
    return `device:${deviceId}`;
  }
}
