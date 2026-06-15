import { useCallback, useEffect, useState } from 'react';

import {
  fetchAlerts,
  fetchLocations,
  fetchOverview,
  fetchPhotos,
} from '../api/client';
import type {
  DashboardAlert,
  DashboardOverview,
  LocationRow,
  PhotoRow,
} from '../api/types';
import { useAuth } from '../auth/AuthContext';
import { AlertList } from '../components/AlertList';
import { DeviceMap } from '../components/DeviceMap';
import { LocationHistory } from '../components/LocationHistory';
import { PhotoGallery } from '../components/PhotoGallery';
import { StatsCards } from '../components/StatsCards';
import { TheftControls } from '../components/TheftControls';

const POLL_MS = 12_000;

export function DashboardPage() {
  const { user, logout } = useAuth();
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [alerts, setAlerts] = useState<DashboardAlert[]>([]);
  const [selectedDeviceId, setSelectedDeviceId] = useState<string | null>(null);
  const [locations, setLocations] = useState<LocationRow[]>([]);
  const [photos, setPhotos] = useState<PhotoRow[]>([]);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);

  const refresh = useCallback(async () => {
    try {
      const [nextOverview, nextAlerts] = await Promise.all([
        fetchOverview(),
        fetchAlerts(50),
      ]);
      setOverview(nextOverview);
      setAlerts(nextAlerts);
      setLastRefresh(new Date());
      setError(null);

      setSelectedDeviceId((current) => {
        if (current && nextOverview.devices.some((d) => d.id === current)) {
          return current;
        }
        return nextOverview.devices[0]?.id ?? null;
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load dashboard');
    }
  }, []);

  useEffect(() => {
    void refresh();
    const timer = window.setInterval(() => void refresh(), POLL_MS);
    return () => window.clearInterval(timer);
  }, [refresh]);

  useEffect(() => {
    if (!selectedDeviceId) {
      setLocations([]);
      setPhotos([]);
      return;
    }

    setDetailLoading(true);
    Promise.all([
      fetchLocations(selectedDeviceId, 100),
      fetchPhotos(selectedDeviceId, 40),
    ])
      .then(([nextLocations, nextPhotos]) => {
        setLocations(nextLocations);
        setPhotos(nextPhotos);
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : 'Failed to load device data');
      })
      .finally(() => setDetailLoading(false));
  }, [selectedDeviceId, lastRefresh]);

  const selectedDevice =
    overview?.devices.find((device) => device.id === selectedDeviceId) ?? null;

  return (
    <div className="dashboard">
      <header className="topbar">
        <div>
          <h1>Anti-Leba Dashboard</h1>
          <p className="muted">
            {user?.fullName ?? user?.email}
            {lastRefresh ? ` · updated ${lastRefresh.toLocaleTimeString()}` : ''}
          </p>
        </div>
        <button type="button" className="ghost" onClick={() => void logout()}>
          Sign out
        </button>
      </header>

      {error && <p className="error banner">{error}</p>}

      {overview ? (
        <>
          <StatsCards stats={overview.stats} />

          <section className="panel">
            <div className="panel-head">
              <h2>Live device map</h2>
              <select
                value={selectedDeviceId ?? ''}
                onChange={(e) => setSelectedDeviceId(e.target.value || null)}
              >
                {overview.devices.map((device) => (
                  <option key={device.id} value={device.id}>
                    {device.label} ({device.status})
                  </option>
                ))}
              </select>
            </div>
            <DeviceMap
              devices={overview.devices}
              selectedDeviceId={selectedDeviceId}
            />
          </section>

          <div className="two-col">
            <section className="panel">
              <h2>Alert history</h2>
              <AlertList alerts={alerts} />
            </section>

            <section className="panel">
              <h2>Theft mode controls</h2>
              <TheftControls device={selectedDevice} onUpdated={() => void refresh()} />
            </section>
          </div>

          <section className="panel">
            <h2>Location history</h2>
            <LocationHistory locations={locations} loading={detailLoading} />
          </section>

          <section className="panel">
            <h2>Evidence gallery</h2>
            <PhotoGallery photos={photos} loading={detailLoading} />
          </section>
        </>
      ) : (
        <p className="muted">Loading dashboard…</p>
      )}
    </div>
  );
}
