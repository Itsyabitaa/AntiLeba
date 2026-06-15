export type DeviceStatus = 'ACTIVE' | 'LOST' | 'RECOVERED' | 'DISABLED';

export interface DashboardLocation {
  latitude: number;
  longitude: number;
  accuracy: number | null;
  recordedAt: string;
}

export interface DashboardDevice {
  id: string;
  label: string;
  status: DeviceStatus;
  manufacturer: string | null;
  model: string | null;
  simOperator: string | null;
  lastSeenAt: string | null;
  enrolledAt: string;
  lastLocation: DashboardLocation | null;
}

export interface DashboardStats {
  devices: {
    total: number;
    active: number;
    lost: number;
    recovered: number;
    disabled: number;
  };
  locations: number;
  photos: number;
  simChanges: number;
  commands: number;
  alertsLast24h: number;
}

export interface DashboardOverview {
  stats: DashboardStats;
  devices: DashboardDevice[];
  generatedAt: string;
}

export interface DashboardAlert {
  id: string;
  type: 'SIM_CHANGE' | 'REMOTE_COMMAND' | 'DEVICE_STATUS';
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message: string;
  deviceId: string;
  deviceLabel: string;
  occurredAt: string;
}

export interface LocationRow {
  id: string;
  deviceId: string;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  recordedAt: string;
}

export interface PhotoRow {
  id: string;
  deviceId: string;
  trigger: string;
  mimeType: string;
  fileSize: number;
  capturedAt: string;
}

export interface AuthUser {
  id: string;
  email: string;
  fullName: string;
  role: string;
}

export interface AuthResponse {
  accessToken: string;
  user: AuthUser;
}

export type CommandType =
  | 'ACTIVATE_THEFT_MODE'
  | 'REQUEST_LIVE_LOCATION'
  | 'TRIGGER_ALARM'
  | 'CAPTURE_IMAGE';
