import type {
  AuthResponse,
  AuthUser,
  CommandType,
  DashboardAlert,
  DashboardOverview,
  DeviceStatus,
  LocationRow,
  PhotoRow,
} from './types';

const API_URL =
  import.meta.env.VITE_API_URL?.replace(/\/$/, '') ?? 'http://localhost:3000/api';

const TOKEN_KEY = 'anti_leba_dashboard_token';

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setStoredToken(token: string | null): void {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token);
  } else {
    localStorage.removeItem(TOKEN_KEY);
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const token = getStoredToken();
  const headers = new Headers(options.headers);
  headers.set('Content-Type', 'application/json');
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `Request failed (${response.status})`);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}

export async function login(
  email: string,
  password: string,
): Promise<AuthResponse> {
  return request<AuthResponse>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
}

export async function fetchMe(): Promise<AuthUser> {
  return request<AuthUser>('/auth/me');
}

export async function logout(): Promise<void> {
  await request<void>('/auth/logout', { method: 'POST' });
}

export async function fetchOverview(): Promise<DashboardOverview> {
  return request<DashboardOverview>('/dashboard/overview');
}

export async function fetchAlerts(limit = 50): Promise<DashboardAlert[]> {
  return request<DashboardAlert[]>(`/dashboard/alerts?limit=${limit}`);
}

export async function fetchLocations(
  deviceId: string,
  limit = 100,
): Promise<LocationRow[]> {
  return request<LocationRow[]>(
    `/locations?deviceId=${deviceId}&limit=${limit}`,
  );
}

export async function fetchPhotos(
  deviceId: string,
  limit = 50,
): Promise<PhotoRow[]> {
  return request<PhotoRow[]>(`/photos?deviceId=${deviceId}&limit=${limit}`);
}

export async function updateDeviceStatus(
  deviceId: string,
  status: DeviceStatus,
): Promise<void> {
  await request(`/devices/${deviceId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  });
}

export async function issueCommand(
  deviceId: string,
  type: CommandType,
): Promise<void> {
  await request('/commands', {
    method: 'POST',
    body: JSON.stringify({ deviceId, type }),
  });
}

export async function fetchPhotoBlob(photoId: string): Promise<string> {
  const token = getStoredToken();
  const response = await fetch(`${API_URL}/photos/${photoId}/file`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  if (!response.ok) {
    throw new Error('Failed to load photo');
  }
  const blob = await response.blob();
  return URL.createObjectURL(blob);
}

export { API_URL };
