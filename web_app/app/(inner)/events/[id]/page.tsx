import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getEvent } from "@/lib/api";
import { getUser } from "@/lib/auth";
import { myBookmarks, myRegistrations } from "@/lib/me";
import { clock, dayParts, isPast, longDate, relativeDay } from "@/lib/format";
import { BookmarkButton, CopyLinkButton, RegisterButton } from "@/components/interactive";
import { ImageLightbox } from "@/components/ImageLightbox";
import { EventImage } from "@/components/EventImage";
import { ArrowLeft } from "@/components/ui";

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const e = await getEvent((await params).id);
  return e ? { title: e.title, description: e.description.slice(0, 160) } : { title: "Event" };
}

export default async function EventPage({ params }: Props) {
  const { id } = await params;
  const e = await getEvent(id);
  if (!e) notFound();
  const user = await getUser();
  const [marks, regs] = user ? await Promise.all([myBookmarks(), myRegistrations()]) : [[], []];
  const saved = marks.some((b) => b.content_type === "event" && b.content_id === id);
  const registered = regs.includes(id);

  const d = dayParts(e.date_time);
  const past = isPast(e);
  const registeredCount = e.registered_count ?? 0;
  const full = e.capacity != null && registeredCount >= e.capacity;
  const pct = e.capacity ? Math.min(100, Math.round((registeredCount / e.capacity) * 100)) : null;

  return (
    <>
      <section data-dark className="bg-night text-white">
        <div className="mx-auto max-w-[76rem] px-5 pb-16 pt-10 sm:px-8 sm:pt-14">
          <Link href="/events" className="inline-flex items-center gap-2 font-semibold text-white/70 hover:text-white">
            <ArrowLeft className="h-5 w-5" /> All events
          </Link>

          <div className="mt-10 grid gap-10 lg:grid-cols-[auto_1fr_20rem] lg:items-start lg:gap-14">
            <div className="tnum flex h-fit w-fit flex-col items-center rounded-3xl bg-white px-8 py-6 text-night">
              <span className="text-sm font-semibold text-red-deep">{d.weekday}</span>
              <span className="display text-7xl">{d.day}</span>
              <span className="text-sm font-semibold">{d.month} {d.year}</span>
            </div>

            <div>
              <p className="text-sm font-semibold text-[#ff8a80]">
                {e.category}
                {e.is_featured && !past && " · Featured"}
              </p>
              <h1 className="display mt-3 text-[clamp(2.6rem,6vw,5rem)]">{e.title}</h1>
              <p className="mt-5 text-lg text-white/80">
                {longDate(e.date_time)}, {clock(e.date_time)}
                {e.end_date_time ? ` to ${clock(e.end_date_time)}` : ""}
              </p>
              <p className="text-lg text-white/80">{e.venue}</p>
              <p className="mt-1 text-white/55">
                {past ? `Held ${relativeDay(e.date_time)}` : `Starts ${relativeDay(e.date_time)}`}
              </p>
            </div>

            <div className="space-y-5 rounded-3xl border border-white/15 p-6">
              {pct !== null && e.capacity ? (
                <div>
                  <div className="tnum flex justify-between text-sm text-white/75">
                    <span>{registeredCount} registered</span>
                    <span>{e.capacity} places</span>
                  </div>
                  <div className="mt-2 h-2 overflow-hidden rounded-full bg-white/15" role="img" aria-label={`${pct}% of places taken`}>
                    <div className="h-full rounded-full bg-[#ff8a80]" style={{ width: `${pct}%` }} />
                  </div>
                </div>
              ) : (
                <p className="tnum text-white/75">{registeredCount} registered</p>
              )}
              <RegisterButton id={e.id} registered={registered} full={full} past={past} signedIn={Boolean(user)} />
            </div>
          </div>
        </div>
      </section>

      <div className="mx-auto grid max-w-[76rem] gap-12 px-5 pb-28 pt-14 sm:px-8 lg:grid-cols-[1fr_20rem]">
        <div>
          {e.image_url && (
            <ImageLightbox src={e.image_url} alt={`Poster for ${e.title}`} className="mb-10">
              <EventImage src={e.image_url} title={e.title} priority className="aspect-[16/10] w-full rounded-3xl" />
            </ImageLightbox>
          )}
          <h2 className="display-soft text-3xl">About this event</h2>
          <p className="prose-tight mt-5 whitespace-pre-line text-[1.15rem] leading-[1.75]">{e.description}</p>
          
        </div>
        <aside className="h-fit space-y-6">
          <div className="flex flex-wrap gap-3">
            <BookmarkButton type="event" id={e.id} saved={saved} signedIn={Boolean(user)} />
            <CopyLinkButton />
            <a
              href={`/events/${e.id}/calendar.ics`}
              className="inline-flex min-h-11 items-center gap-2 rounded-full border border-line bg-paper px-5 py-2.5 text-[0.95rem] font-semibold transition hover:border-night/40"
            >
              Add to calendar
            </a>
          </div>
          <dl className="space-y-4 border-t border-line pt-6 text-[0.95rem]">
            <div>
              <dt className="text-mute">Organiser</dt>
              <dd className="font-semibold">{e.organizer_name}</dd>
            </div>
            <div>
              <dt className="text-mute">Venue</dt>
              <dd className="font-semibold">{e.venue}</dd>
            </div>
          </dl>
        </aside>
      </div>
    </>
  );
}
