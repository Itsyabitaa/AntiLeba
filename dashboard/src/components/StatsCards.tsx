import type { DashboardStats } from '../api/types';

interface Props {
  stats: DashboardStats;
}

export function StatsCards({ stats }: Props) {
  const cards = [
    { label: 'Devices', value: stats.devices.total, hint: `${stats.devices.lost} lost` },
    { label: 'Locations', value: stats.locations, hint: 'stored fixes' },
    { label: 'Photos', value: stats.photos, hint: 'evidence files' },
    { label: 'Alerts (24h)', value: stats.alertsLast24h, hint: 'recent events' },
  ];

  return (
    <div className="stats-grid">
      {cards.map((card) => (
        <article key={card.label} className="stat-card">
          <span className="stat-label">{card.label}</span>
          <strong className="stat-value">{card.value}</strong>
          <span className="muted">{card.hint}</span>
        </article>
      ))}
    </div>
  );
}
