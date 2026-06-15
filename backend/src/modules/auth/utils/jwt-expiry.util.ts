/** Parse jsonwebtoken-style durations like `1d`, `15m`, `7d`. */
export function expiresAtFromConfig(expiresIn: string): Date {
  const match = /^(\d+)([smhd])$/.exec(expiresIn.trim());
  if (!match) {
    return new Date(Date.now() + 24 * 60 * 60 * 1000);
  }

  const amount = Number.parseInt(match[1]!, 10);
  const unitMs: Record<string, number> = {
    s: 1000,
    m: 60_000,
    h: 3_600_000,
    d: 86_400_000,
  };
  const ms = unitMs[match[2]!] ?? 86_400_000;
  return new Date(Date.now() + amount * ms);
}
