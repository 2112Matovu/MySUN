// All campus times are shown in Soroti local time (EAT, UTC+3) regardless of
// where the server or the visitor is.
const TZ = "Africa/Kampala";

const fmt = (opts: Intl.DateTimeFormatOptions) =>
  new Intl.DateTimeFormat("en-GB", { timeZone: TZ, ...opts });

export function dayParts(iso: string) {
  const d = new Date(iso);
  return {
    weekday: fmt({ weekday: "short" }).format(d),
    day: fmt({ day: "numeric" }).format(d),
    month: fmt({ month: "short" }).format(d),
    year: fmt({ year: "numeric" }).format(d),
  };
}

export const longDate = (iso: string) =>
  fmt({ weekday: "long", day: "numeric", month: "long", year: "numeric" }).format(new Date(iso));

export const shortDate = (iso: string) =>
  fmt({ day: "numeric", month: "short", year: "numeric" }).format(new Date(iso));

export const clock = (iso: string) =>
  fmt({ hour: "numeric", minute: "2-digit", hour12: true })
    .format(new Date(iso))
    .replace(" am", " am")
    .replace(" pm", " pm");

export function timeRange(start: string, end: string | null) {
  if (!end) return clock(start);
  return `${clock(start)} to ${clock(end)}`;
}

export const ugx = (n: number) => `UGX ${n.toLocaleString("en-US")}`;

export function relativeDay(iso: string, now = Date.now()) {
  const diff = new Date(iso).getTime() - now;
  const days = Math.round(diff / 86_400_000);
  const rtf = new Intl.RelativeTimeFormat("en", { numeric: "auto" });
  if (Math.abs(days) < 1) {
    const hours = Math.round(diff / 3_600_000);
    return Math.abs(hours) < 1 ? "just now" : rtf.format(hours, "hour");
  }
  if (Math.abs(days) < 60) return rtf.format(days, "day");
  return rtf.format(Math.round(days / 30), "month");
}

export const isPast = (e: { date_time: string; end_date_time: string | null }, now = Date.now()) =>
  new Date(e.end_date_time ?? e.date_time).getTime() < now;

/** Phone number for a tel: link. */
export const telHref = (p: string) => `tel:${p.replace(/[^\d+]/g, "")}`;
