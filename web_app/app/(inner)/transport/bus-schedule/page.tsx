import type { Metadata } from "next";
import Link from "next/link";
import { getBusSchedule } from "@/lib/api";
import { ApiDown, ArrowLeft, EmptyState, PageHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Bus schedule",
  description: "Departure times for buses serving Soroti University.",
};

/** "07:30:00" or "07:30" to "7:30 am". */
function time(t: string) {
  const [h, m] = t.split(":").map(Number);
  if (Number.isNaN(h)) return t;
  return `${h % 12 === 0 ? 12 : h % 12}:${String(m ?? 0).padStart(2, "0")} ${h < 12 ? "am" : "pm"}`;
}

export default async function BusSchedulePage() {
  const all = await getBusSchedule();
  const rows = [...(all ?? [])].sort((a, b) => a.departure_time.localeCompare(b.departure_time));
  return (
    <>
      <PageHeader section="transport" />
      <div className="mx-auto max-w-[76rem] px-5 pb-28 sm:px-8">
        <Link href="/transport" className="mb-8 inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
          <ArrowLeft className="h-5 w-5" /> Boda stages
        </Link>
        <h2 className="display-soft text-4xl">Bus schedule</h2>
        <div className="mt-8">
          {all === null ? (
            <ApiDown />
          ) : rows.length === 0 ? (
            <EmptyState section="transport" title="No buses scheduled" body="Departure times appear here once the transport office publishes them." />
          ) : (
            <ul className="border-t border-line">
              {rows.map((b) => (
                <li key={b.id} className="grid gap-3 border-b border-line py-7 md:grid-cols-[9rem_1fr_auto] md:items-center md:gap-10">
                  <p className="tnum display-soft text-3xl">{time(b.departure_time)}</p>
                  <div>
                    <h3 className="display-soft text-2xl">{b.route_name}</h3>
                    <p className="mt-1 text-mute">
                      {b.departure_point} to {b.destination} · about {b.estimated_duration_minutes} min
                    </p>
                    <p className="text-mute">{b.operating_days}</p>
                    {b.notes && <p className="mt-2 text-[0.95rem]">{b.notes}</p>}
                  </div>
                  {b.status && b.status.toLowerCase() !== "on_time" && b.status.toLowerCase() !== "on time" && (
                    <p className="w-fit rounded-full bg-gold/20 px-3.5 py-1 text-sm font-semibold text-gold-deep">{b.status.replace(/_/g, " ")}</p>
                  )}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </>
  );
}
