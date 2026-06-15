import { useState } from 'react';

import { issueCommand, updateDeviceStatus } from '../api/client';
import type { CommandType, DashboardDevice, DeviceStatus } from '../api/types';

interface Props {
  device: DashboardDevice | null;
  onUpdated: () => void;
}

const commands: { type: CommandType; label: string }[] = [
  { type: 'ACTIVATE_THEFT_MODE', label: 'Activate theft mode' },
  { type: 'REQUEST_LIVE_LOCATION', label: 'Request live location' },
  { type: 'TRIGGER_ALARM', label: 'Trigger alarm' },
  { type: 'CAPTURE_IMAGE', label: 'Capture image' },
];

export function TheftControls({ device, onUpdated }: Props) {
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  if (!device) {
    return <p className="muted">Select a device to manage theft controls.</p>;
  }

  const selected = device;

  async function run(action: string, fn: () => Promise<void>) {
    setBusy(action);
    setMessage(null);
    try {
      await fn();
      setMessage(`${action} sent successfully.`);
      onUpdated();
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Action failed');
    } finally {
      setBusy(null);
    }
  }

  async function setStatus(status: DeviceStatus, label: string) {
    await run(label, () => updateDeviceStatus(selected.id, status));
  }

  return (
    <div className="theft-controls">
      <div className="control-row">
        <span className="badge status">{selected.status}</span>
        <span className="muted">{selected.label}</span>
      </div>

      <div className="button-row">
        <button
          type="button"
          disabled={!!busy}
          onClick={() => setStatus('LOST', 'Mark LOST')}
        >
          Mark LOST
        </button>
        <button
          type="button"
          disabled={!!busy}
          onClick={() => setStatus('RECOVERED', 'Mark recovered')}
        >
          Mark recovered
        </button>
        <button
          type="button"
          disabled={!!busy}
          onClick={() => setStatus('ACTIVE', 'Mark active')}
        >
          Mark active
        </button>
      </div>

      <div className="button-row">
        {commands.map((cmd) => (
          <button
            key={cmd.type}
            type="button"
            disabled={!!busy}
            onClick={() =>
              run(cmd.label, () => issueCommand(selected.id, cmd.type))
            }
          >
            {cmd.label}
          </button>
        ))}
      </div>

      {message && <p className="muted">{message}</p>}
    </div>
  );
}
