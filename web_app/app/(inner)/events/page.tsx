import type { Metadata } from "next";
import Link from "next/link";
import { getEvents, type CampusEvent } from "@/lib/api";
import { ApiDown, EmptyState, FilterPills, PageHeader } from "@/components/ui";
import { EventImage } from "@/components/EventImage";
import { clock, dayParts, isPast, longDate, relativeDay } from "@/lib/format";

export const metadata: Metadata = {
  title: "Events",
  description: "What is on at Soroti University: lectures, career fairs, sports and more.",
};

export default async function EventsPage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string }>;
}) {
  const { category } = await searchParams;
  const all = await getEvents();
  const now = Date.now();
  const categories = [...new Set((all ?? []).map((e) => e.category))].sort();
  const filtered = (all ?? []).filter((e) => !category || e.category === category);
  const upcoming = filtered
    .filter((e) => !isPast(e, now))
    .sort((a, b) => +new Date(a.date_time) - +new Date(b.date_time));
  const earlier = filtered
    .filter((e) => isPast(e, now))
    .sort((a, b) => +new Date(b.date_time) - +new Date(a.date_time));

  return (
    <>
      <PageHeader
        section="events"
        count={all ? `${upcoming.length} coming up` : undefined}
      >
        {categories.length > 1 && (
          <FilterPills
            basePath="/events"
            param="category"
            options={categories.map((c) => ({ value: c, label: c }))}
            active={category}
            section="events"
          />
        )}
      </PageHeader>

      <div className="mx-auto max-w-[76rem] px-5 pb-28 sm:px-8">
        {all === null ? (
          <ApiDown />
        ) : (
          <>
            <h2 className="display-soft text-3xl">Coming up</h2>
            {upcoming.length === 0 ? (
              <div className="mt-6">
                <EmptyState
                  section="events"
                  title="No events scheduled"
                  body="When a publisher schedules an event it shows up here. Get the app to be told as soon as one goes up."
                />
              </div>
            ) : (
              <ul className="mt-6 border-t border-line">
                {upcoming.map((e) => (
                  <EventRow key={e.id} e={e} now={now} />
                ))}
              </ul>
            )}

            {earlier.length > 0 && (
              <>
                <h2 className="display-soft mt-20 text-3xl text-mute">Earlier</h2>
                <ul className="mt-6 border-t border-line opacity-80">
                  {earlier.map((e) => (
                    <EventRow key={e.id} e={e} now={now} past />
                  ))}
                </ul>
              </>
            )}
          </>
        )}
      </div>
    </>
  );
}

function EventRow({ e, now, past = false }: { e: CampusEvent; now: number; past?: boolean }) {
  const d = dayParts(e.date_time);
  const pct =
    e.capacity && e.capacity > 0
      ? Math.min(100, Math.round((e.registered_count / e.capacity) * 100))
      : null;
  return (
    <li className="grid gap-6 border-b border-line py-9 md:grid-cols-[7.5rem_1fr_16rem] md:gap-10">
      <div className={`tnum flex w-fit flex-col items-center self-start rounded-2xl px-6 py-4 ${past ? "bg-line text-mute" : "bg-night text-white"}`}>
        <span className={`text-sm font-semibold ${past ? "" : "text-[#ff8a80]"}`}>{d.weekday}</span>
        <span className="display text-5xl">{d.day}</span>
        <span className="text-sm font-semibold">{d.month}</span>
      </div>

      <article>
        <p className="flex flex-wrap items-center gap-x-3 text-sm font-medium text-mute">
          <span>{e.category}</span>
          {e.is_featured && !past && (
            <span className="rounded-full bg-red/10 px-2.5 py-0.5 font-semibold text-red-deep">Featured</span>
          )}
        </p>
        <h3 className="display-soft mt-1 text-[clamp(1.7rem,3.4vw,2.5rem)]">
          <Link href={`/events/${e.id}`} className="hover:text-red-deep hover:underline decoration-2 underline-offset-4">{e.title}</Link>
        </h3>
        <p className="prose-tight mt-3 text-mute">{e.description}</p>
        {e.image_url && (
          <Link href={`/events/${e.id}`} className="mt-5 block" tabIndex={-1} aria-hidden>
            <EventImage src={e.image_url} title={e.title} className="aspect-[16/10] w-full max-w-xl" />
          </Link>
        )}
      </article>

      <div className="space-y-1 text-[0.98rem]">
        <p className="font-semibold">{longDate(e.date_time)}</p>
        <p className="tnum text-mute">
          {clock(e.date_time)}
          {e.end_date_time ? ` to ${clock(e.end_date_time)}` : ""}
        </p>
        <p className="text-mute">{e.venue}</p>
        <p className="text-mute">
          {past ? `Held ${relativeDay(e.date_time, now)}` : `Starts ${relativeDay(e.date_time, now)}`}
        </p>
        {pct !== null && e.capacity && (
          <div className="pt-3">
            <div className="tnum flex justify-between text-sm text-mute">
              <span>{e.registered_count} registered</span>
              <span>{e.capacity} places</span>
            </div>
            <div className="mt-1.5 h-2 overflow-hidden rounded-full bg-line" role="img" aria-label={`${pct}% of places taken`}>
              <div className="h-full rounded-full bg-red" style={{ width: `${pct}%` }} />
            </div>
          </div>
        )}
      </div>
    </li>
  );
}
