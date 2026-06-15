import type { LocationRow } from '../api/types';

interface Props {
  locations: LocationRow[];
  loading: boolean;
}

export function LocationHistory({ locations, loading }: Props) {
  if (loading) {
    return <p className="muted">Loading location history…</p>;
  }

  if (locations.length === 0) {
    return <p className="muted">No locations recorded for this device.</p>;
  }

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Latitude</th>
            <th>Longitude</th>
            <th>Accuracy</th>
          </tr>
        </thead>
        <tbody>
          {locations.map((row) => (
            <tr key={row.id}>
              <td>{new Date(row.recordedAt).toLocaleString()}</td>
              <td>{row.latitude.toFixed(5)}</td>
              <td>{row.longitude.toFixed(5)}</td>
              <td>{row.accuracy != null ? `${Math.round(row.accuracy)} m` : '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
