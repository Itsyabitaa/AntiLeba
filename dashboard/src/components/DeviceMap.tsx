import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet';
import L from 'leaflet';
import { useEffect } from 'react';

import type { DashboardDevice } from '../api/types';

const defaultIcon = L.icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl:
    'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

L.Marker.prototype.options.icon = defaultIcon;

function FitBounds({ devices }: { devices: DashboardDevice[] }) {
  const map = useMap();

  useEffect(() => {
    const points = devices
      .map((device) => device.lastLocation)
      .filter(Boolean) as NonNullable<DashboardDevice['lastLocation']>[];

    if (points.length === 0) {
      map.setView([9.03, 38.74], 6);
      return;
    }

    const bounds = L.latLngBounds(
      points.map((point) => [point.latitude, point.longitude] as [number, number]),
    );
    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 15 });
  }, [devices, map]);

  return null;
}

interface Props {
  devices: DashboardDevice[];
  selectedDeviceId: string | null;
}

export function DeviceMap({ devices, selectedDeviceId }: Props) {
  const markers = devices.filter((device) => device.lastLocation);

  return (
    <div className="map-panel">
      <MapContainer center={[9.03, 38.74]} zoom={6} scrollWheelZoom>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <FitBounds devices={devices} />
        {markers.map((device) => {
          const loc = device.lastLocation!;
          const isSelected = device.id === selectedDeviceId;
          return (
            <Marker
              key={device.id}
              position={[loc.latitude, loc.longitude]}
              opacity={selectedDeviceId && !isSelected ? 0.45 : 1}
            >
              <Popup>
                <strong>{device.label}</strong>
                <br />
                Status: {device.status}
                <br />
                {loc.latitude.toFixed(5)}, {loc.longitude.toFixed(5)}
                <br />
                {new Date(loc.recordedAt).toLocaleString()}
              </Popup>
            </Marker>
          );
        })}
      </MapContainer>
    </div>
  );
}
