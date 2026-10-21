import Link from "next/link";
import { SkyHero } from "@/components/SkyHero";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { SunMark } from "@/components/SunMark";
import { ArrowRight, Check } from "@/components/ui";
import { BodaRow, HousingCard } from "@/components/listings";
import {
  getAccommodation,
  getAnnouncements,
  getEvents,
  getTransport,
  type Accommodation,
  type Announcement,
  type CampusEvent,
  type TransportProvider,
} from "@/lib/api";
import { getUser } from "@/lib/auth";
import { SECTIONS, SECTION_ORDER, type SectionKey } from "@/lib/sections";
import { clock, dayParts, isPast, relativeDay, ugx } from "@/lib/format";

// Hosted in the public Supabase Storage bucket "app-releases". Re-upload the same names to ship a new build.
const APK_BASE = "https://uvwouiknxcuzauxjnntn.supabase.co/storage/v1/object/public/app-releases";
const APK_URL = process.env.NEXT_PUBLIC_APK_URL ?? `${APK_BASE}/mysun-arm64.apk?download=MySun.apk`;
const APK_OLD_URL = `${APK_BASE}/mysun-armeabi.apk?download=MySun-older-phones.apk`;

export default async function Home() {
  const [announcements, events, housing, transport] = await Promise.all([
    getAnnouncements(),
    getEvents(),
    getAccommodation(),
    getTransport(),
  ]);

  const signedIn = Boolean(await getUser());
  const now = Date.now();
  const upcoming = (events ?? [])
    .filter((e) => !isPast(e, now))
    .sort((a, b) => +new Date(a.date_time) - +new Date(b.date_time));
  const recent = (events ?? [])
    .filter((e) => isPast(e, now))
    .sort((a, b) => +new Date(b.date_time) - +new Date(a.date_time));
  const spotlight =
    upcoming.find((e) => e.is_featured) ?? upcoming[0] ?? recent[0] ?? null;
  const spotlightIsPast = spotlight ? isPast(spotlight, now) : false;

  const notices = [...(announcements ?? [])]
    .sort(
      (a, b) =>
        Number(b.is_important) - Number(a.is_important) ||
        +new Date(b.published_at) - +new Date(a.published_at),
    )
    .slice(0, 3);

  const counts = {
    announcements: announcements?.length ?? 0,
    events: upcoming.length,
    accommodation: (housing ?? []).filter((h) => h.is_available).length,
    transport: transport?.length ?? 0,
  };

  const cheapest = (housing ?? []).reduce<number | null>(
    (min, h) => (min === null || h.price < min ? h.price : min),
    null,
  );

  const summaries: Record<SectionKey, string> = {
    announcements:
      counts.announcements > 0
        ? `${counts.announcements} live ${counts.announcements === 1 ? "notice" : "notices"}`
        : "Nothing posted yet",
    events:
      counts.events > 0
        ? `${counts.events} coming up`
        : recent.length > 0
          ? `${recent.length} recent, none scheduled`
          : "Nothing scheduled yet",
    accommodation:
      counts.accommodation > 0 && cheapest !== null
        ? `${counts.accommodation} available, from ${ugx(cheapest)}`
        : "No rooms listed yet",
    services: "Food, health, IT support and the library",
    transport:
      counts.transport > 0
        ? `${counts.transport} ${counts.transport === 1 ? "stage" : "stages"} on the map`
        : "No stages listed yet",
  };

  return (
    <>
      <SkyHero header={<SiteHeader overlay />}>
        <h1 className="display max-w-[14ch] text-[clamp(3.2rem,9vw,7.25rem)]">
          Soroti University, in one place.
        </h1>
        <p className="mt-7 max-w-[34rem] text-[clamp(1.1rem,2.2vw,1.35rem)] leading-relaxed opacity-90">
          Announcements, events, student housing and boda stages, posted by the people
          who run them.
        </p>
        <div className="mt-9 flex flex-wrap gap-3">
          <Link
            href="#get-app"
            className="rounded-full bg-gold px-7 py-3.5 text-[1.02rem] font-semibold text-night shadow-[0_10px_30px_-10px_rgba(245,179,24,0.8)] transition hover:-translate-y-0.5 hover:bg-white"
          >
            Get the Android app
          </Link>
          <Link
            href="#next"
            className="rounded-full border border-current/40 px-7 py-3.5 text-[1.02rem] font-semibold transition hover:bg-white/15"
          >
            See what&rsquo;s on
          </Link>
        </div>
      </SkyHero>

      {/* Next up: continues the hero's ground in night blue. */}
      <section id="next" data-dark className="scroll-mt-4 bg-night text-white">
        <div className="mx-auto grid max-w-[76rem] gap-14 px-5 pb-24 pt-8 sm:px-8 lg:grid-cols-[1.25fr_1fr] lg:gap-20">
          <div>
            <p className={`text-sm font-semibold ${SECTIONS.events.textOnDark}`}>
              {spotlight
                ? spotlightIsPast
                  ? "Most recent event"
                  : "Next event"
                : "Events"}
            </p>
            {spotlight ? (
              <SpotlightEvent event={spotlight} past={spotlightIsPast} now={now} />
            ) : (
              <div className="mt-6">
                <h2 className="display text-[clamp(2.4rem,6vw,4.5rem)]">
                  No events scheduled yet.
                </h2>
                <p className="mt-4 max-w-md text-white/70">
                  Publishers add events here the moment they are scheduled. Check back
                  soon, or get the app to be told when one goes up.
                </p>
              </div>
            )}
          </div>

          <div>
            <p className={`text-sm font-semibold ${SECTIONS.announcements.textOnDark}`}>
              Latest announcements
            </p>
            {notices.length > 0 ? (
              <ul className="mt-6 divide-y divide-white/12 border-y border-white/12">
                {notices.map((a) => (
                  <NoticeRow key={a.id} a={a} />
                ))}
              </ul>
            ) : (
              <p className="mt-6 border-y border-white/12 py-8 text-white/70">
                No announcements are live right now.
              </p>
            )}
            <Link
              href="/announcements"
              className="mt-6 inline-flex items-center gap-2 font-semibold text-gold transition hover:gap-3"
            >
              All announcements <ArrowRight className="h-5 w-5" />
            </Link>
          </div>
        </div>
      </section>

      {/* Index of the four sections. */}
      <section aria-labelledby="browse" className="mx-auto max-w-[76rem] px-5 py-24 sm:px-8">
        <h2 id="browse" className="display-soft max-w-[18ch] text-[clamp(2rem,4.5vw,3.25rem)]">
          Find what you need on campus
        </h2>
        <ul className="mt-12 border-t border-line">
          {SECTION_ORDER.map((key) => {
            const s = SECTIONS[key];
            return (
              <li key={key} className="border-b border-line">
                <Link
                  href={s.href}
                  className="group relative flex items-center gap-5 overflow-hidden py-7 sm:py-9"
                >
                  <span
                    aria-hidden
                    className={`absolute inset-y-0 left-0 w-0 ${s.bar} opacity-[0.12] transition-[width] duration-500 ease-out group-hover:w-full`}
                  />
                  <span className={`relative h-12 w-1.5 shrink-0 rounded-full ${s.bar}`} aria-hidden />
                  <span className="relative grid flex-1 gap-1 sm:grid-cols-[minmax(0,1fr)_1fr] sm:items-baseline sm:gap-8">
                    <span className="display-soft text-[clamp(1.9rem,5vw,3.4rem)]">
                      {s.label}
                    </span>
                    <span className="tnum text-mute">{summaries[key]}</span>
                  </span>
                  <ArrowRight className="relative h-8 w-8 shrink-0 text-ink transition-transform duration-300 group-hover:translate-x-1.5" />
                </Link>
              </li>
            );
          })}
        </ul>
      </section>

      {/* Housing */}
      <HousingSection items={(housing ?? []).filter((h) => h.is_available)} />

      {/* Boda stages */}
      <BodaSection items={transport ?? []} signedIn={signedIn} />

      {/* App */}
      <section id="get-app" data-dark className="scroll-mt-4 bg-night text-white">
        <div className="mx-auto grid max-w-[76rem] items-center gap-14 px-5 py-24 sm:px-8 lg:grid-cols-[1.2fr_1fr]">
          <div>
            <h2 className="display text-[clamp(2.8rem,7vw,5.5rem)]">
              Take MySun with you.
            </h2>
            <p className="mt-6 max-w-[34rem] text-lg leading-relaxed text-white/75">
              The Android app tells you the moment something important is posted, keeps
              your saved items, and still opens when the network doesn&rsquo;t.
            </p>
            <ul className="mt-8 grid max-w-[34rem] gap-x-8 gap-y-3 sm:grid-cols-2">
              {[
                "Push alerts for important notices",
                "Save events and listings",
                "Book rooms and rate boda stages",
                "Read offline",
              ].map((f) => (
                <li key={f} className="flex items-start gap-3 text-white/90">
                  <Check className="mt-1 shrink-0 text-teal" />
                  {f}
                </li>
              ))}
            </ul>
            <div className="mt-10">
              {APK_URL ? (
                <>
                  <a
                  href={APK_URL}
                  className="inline-flex items-center gap-3 rounded-full bg-gold px-8 py-4 text-lg font-semibold text-night transition hover:-translate-y-0.5 hover:bg-white"
                  >
                    Download for Android
                  </a>
                  <p className="mt-4 max-w-sm text-sm text-white/70">
                    Works on most Android phones. Installation may ask you to allow installs from your browser.{" "}
                    <a href={APK_OLD_URL} className="underline underline-offset-2 hover:text-white">
                      Older phone? Get the 32-bit version.
                    </a>
                  </p>
                </>
              ) : (
                <p className="max-w-sm rounded-2xl border border-white/20 px-5 py-4 text-white/80">
                  The download link is on its way. Until then, ask a publisher or
                  the MySun team for the APK.
                </p>
              )}
            </div>
          </div>
          <div className="relative mx-auto flex aspect-square w-full max-w-sm items-center justify-center" aria-hidden>
            <div className="absolute inset-0 rounded-full bg-[radial-gradient(circle,rgba(245,179,24,0.28),transparent_66%)]" />
            <SunMark size={280} lightRays className="relative" />
          </div>
        </div>
      </section>

      {/* Publishers */}
      <section className="mx-auto max-w-[76rem] px-5 py-24 sm:px-8">
        <div className="grid gap-10 lg:grid-cols-[1fr_1.2fr] lg:gap-20">
          <h2 className="display-soft text-[clamp(2rem,4.5vw,3.25rem)]">
            Running a department, club or hostel?
          </h2>
          <div className="prose-tight space-y-5 text-lg text-mute">
            <p>
              Publishers sign in on the app and post announcements, events, rooms and
              transport listings. Posts go live straight away, with no waiting for
              approval.
            </p>
            <p>
              Administrators can remove anything that breaks the rules, and the
              publisher is told why. Ask the MySun team to be made a publisher.
            </p>
          </div>
        </div>
      </section>

      <SiteFooter />
    </>
  );
}

function SpotlightEvent({
  event,
  past,
  now,
}: {
  event: CampusEvent;
  past: boolean;
  now: number;
}) {
  const d = dayParts(event.date_time);
  const pct =
    event.capacity && event.capacity > 0
      ? Math.min(100, Math.round((event.registered_count / event.capacity) * 100))
      : null;
  return (
    <div className="mt-6 grid gap-8 sm:grid-cols-[auto_1fr]">
      <div className="tnum flex h-fit w-fit flex-col items-center rounded-2xl bg-white px-6 py-5 text-night">
        <span className="text-sm font-semibold text-red-deep">{d.weekday}</span>
        <span className="display text-6xl">{d.day}</span>
        <span className="text-sm font-semibold">{d.month}</span>
      </div>
      <div>
        <h2 className="display text-[clamp(2.2rem,5vw,3.8rem)]">{event.title}</h2>
        <p className="mt-4 text-lg text-white/80">
          {clock(event.date_time)} · {event.venue}
        </p>
        <p className="mt-1 text-white/60">
          {past ? `Held ${relativeDay(event.date_time, now)}` : `Starts ${relativeDay(event.date_time, now)}`}
          {" · "}
          {event.organizer_name}
        </p>
        {pct !== null && event.capacity && (
          <div className="mt-6 max-w-sm">
            <div className="flex justify-between text-sm text-white/70">
              <span>{event.registered_count} registered</span>
              <span>{event.capacity} places</span>
            </div>
            <div className="mt-2 h-2 overflow-hidden rounded-full bg-white/15" role="img" aria-label={`${pct}% of places taken`}>
              <div className="h-full rounded-full bg-[#ff8a80]" style={{ width: `${pct}%` }} />
            </div>
          </div>
        )}
        <Link
          href="/events"
          className="mt-8 inline-flex items-center gap-2 font-semibold text-gold transition hover:gap-3"
        >
          All events <ArrowRight className="h-5 w-5" />
        </Link>
      </div>
    </div>
  );
}

function NoticeRow({ a }: { a: Announcement }) {
  return (
    <li className="relative py-5 pl-5">
      <span
        aria-hidden
        className={`absolute inset-y-5 left-0 w-1 rounded-full ${a.is_important ? "bg-gold" : "bg-white/20"}`}
      />
      <p className="text-sm text-white/60">
        {a.is_important && <span className="mr-2 font-semibold text-gold">Important</span>}
        {a.category} · {relativeDay(a.published_at)}
      </p>
      <p className="display-soft mt-1 text-[1.35rem]">{a.title}</p>
      <p className="mt-1 line-clamp-2 text-white/70">{a.description}</p>
    </li>
  );
}

function HousingSection({ items }: { items: Accommodation[] }) {
  if (items.length === 0) return null;
  const [lead, ...rest] = items;
  const shown = rest.slice(0, 2);
  const even = shown.length === 1;
  return (
    <section className="bg-paper">
      <div className="mx-auto max-w-[76rem] px-5 py-24 sm:px-8">
        <div className="flex flex-wrap items-end justify-between gap-6">
          <h2 className="display text-[clamp(2.4rem,6vw,4.5rem)]">Places to stay</h2>
          <Link href="/accommodation" className={`inline-flex items-center gap-2 font-semibold ${SECTIONS.accommodation.text}`}>
            All housing <ArrowRight className="h-5 w-5" />
          </Link>
        </div>
        <div className={`mt-12 grid gap-6 ${even ? "md:grid-cols-2" : shown.length > 1 ? "lg:grid-cols-[1.35fr_1fr]" : ""}`}>
          <HousingCard h={lead} large />
          {shown.length > 0 && (
            <div className="grid gap-6">
              {shown.map((h) => (
                <HousingCard key={h.id} h={h} large={even} />
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}

function BodaSection({ items, signedIn }: { items: TransportProvider[]; signedIn: boolean }) {
  if (items.length === 0) return null;
  const shown = [...items].sort((a, b) => Number(b.is_verified) - Number(a.is_verified)).slice(0, 3);
  return (
    <section className="mx-auto max-w-[76rem] px-5 py-24 sm:px-8">
      <div className="flex flex-wrap items-end justify-between gap-6">
        <h2 className="display text-[clamp(2.4rem,6vw,4.5rem)]">Getting around</h2>
        <Link href="/transport" className={`inline-flex items-center gap-2 font-semibold ${SECTIONS.transport.text}`}>
          All boda stages <ArrowRight className="h-5 w-5" />
        </Link>
      </div>
      <ul className="mt-10 border-t border-line">
        {shown.map((t) => (
          <BodaRow key={t.id} t={t} signedIn={signedIn} />
        ))}
      </ul>
    </section>
  );
}
