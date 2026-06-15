import type { DashboardAlert } from '../api/types';

interface Props {
  alerts: DashboardAlert[];
}

function formatWhen(iso: string): string {
  return new Date(iso).toLocaleString();
}

export function AlertList({ alerts }: Props) {
  if (alerts.length === 0) {
    return <p className="muted">No alerts yet.</p>;
  }

  return (
    <ul className="alert-list">
      {alerts.map((alert) => (
        <li key={alert.id} className={`alert-item severity-${alert.severity}`}>
          <div className="alert-head">
            <strong>{alert.title}</strong>
            <span className="badge">{alert.type.replace('_', ' ')}</span>
          </div>
          <p>{alert.message}</p>
          <span className="muted">{formatWhen(alert.occurredAt)}</span>
        </li>
      ))}
    </ul>
  );
}
