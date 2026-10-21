import type { Metadata } from "next";
import Link from "next/link";
import { apiData } from "@/lib/server-api";
import type { SearchResults } from "@/lib/api";
import { dayParts, relativeDay, ugx } from "@/lib/format";
import { SECTIONS, type SectionKey } from "@/lib/sections";

export const metadata: Metadata = { title: "Search" };

function Group({ section, children, count }: { section: SectionKey; children: React.ReactNode; count: number }) {
  if (count === 0) return null;
  return (
    <section className="mt-14">
      <h2 className="flex items-center gap-3 display-soft text-3xl">
        <span className={`h-3 w-3 rounded-full ${SECTIONS[section].bar}`} aria-hidden />
        {SECTIONS[section].label}
        <span className="tnum text-lg font-medium text-mute">{count}</span>
      </h2>
      <ul className="mt-5 border-t border-line">{children}</ul>
    </section>
  );
}

const row = "block border-b border-line py-5 transition hover:bg-night/[0.03]";

export default async function SearchPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const q = ((await searchParams).q ?? "").trim();
  const res = q.length >= 2 ? await apiData<SearchResults>(`/search?q=${encodeURIComponent(q)}`) : null;
  const total = res ? res.announcements.length + res.events.length + res.accommodation.length + res.transport.length : 0;

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <h1 className="display text-[clamp(3rem,8vw,6.25rem)]">Search</h1>
      <form role="search" action="/search" className="mt-8 flex max-w-2xl gap-3">
        <input
          name="q"
          defaultValue={q}
          autoFocus={!q}
          placeholder="Announcements, events, housing, boda stages"
          aria-label="Search MySun"
          className="min-w-0 flex-1 rounded-full border border-line bg-paper px-6 py-3.5 text-[1.05rem] focus:border-blue focus:outline-none focus:ring-4 focus:ring-blue/15"
        />
        <button className="rounded-full bg-night px-7 py-3.5 font-semibold text-white transition hover:bg-blue">Search</button>
      </form>

      {q.length < 2 ? (
        <p className="mt-10 text-mute">Type at least two letters to search.</p>
      ) : res === null ? (
        <p role="alert" className="mt-10 text-red-deep">Search isn&rsquo;t available right now. Try again in a moment.</p>
      ) : total === 0 ? (
        <p className="mt-10 text-lg">Nothing matched “{q}”. Try a shorter word or a different spelling.</p>
      ) : (
        <>
          <p className="mt-8 text-mute">{total} {total === 1 ? "result" : "results"} for “{q}”</p>
          <Group section="announcements" count={res.announcements.length}>
            {res.announcements.map((a) => (
              <li key={a.id}>
                <Link href={`/announcements/${a.id}`} className={row}>
                  <span className="display-soft block text-2xl">{a.title}</span>
                  <span className="text-mute">{a.category} · {a.publisher_name} · {relativeDay(a.published_at)}</span>
                </Link>
              </li>
            ))}
          </Group>
          <Group section="events" count={res.events.length}>
            {res.events.map((e) => {
              const d = dayParts(e.date_time);
              return (
                <li key={e.id}>
                  <Link href={`/events/${e.id}`} className={row}>
                    <span className="display-soft block text-2xl">{e.title}</span>
                    <span className="text-mute">{d.weekday} {d.day} {d.month} {d.year} · {e.venue}</span>
                  </Link>
                </li>
              );
            })}
          </Group>
          <Group section="accommodation" count={res.accommodation.length}>
            {res.accommodation.map((h) => (
              <li key={h.id}>
                <Link href={`/accommodation/${h.id}`} className={row}>
                  <span className="display-soft block text-2xl">{h.name}</span>
                  <span className="text-mute">{h.location} · {ugx(h.price)} per {h.type === "hostel" ? "semester" : "month"}</span>
                </Link>
              </li>
            ))}
          </Group>
          <Group section="transport" count={res.transport.length}>
            {res.transport.map((t) => (
              <li key={t.id}>
                <Link href="/transport" className={row}>
                  <span className="display-soft block text-2xl">{t.name}</span>
                  <span className="text-mute">{t.operating_hours ?? "Hours not listed"} · {t.phone_number}</span>
                </Link>
              </li>
            ))}
          </Group>
        </>
      )}
    </div>
  );
}
