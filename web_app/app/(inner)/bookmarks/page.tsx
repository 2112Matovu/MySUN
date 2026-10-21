import type { Metadata } from "next";
import Link from "next/link";
import { getAnnouncement, getEvent } from "@/lib/api";
import { requireUser } from "@/lib/auth";
import { myBookmarks } from "@/lib/me";
import { clock, dayParts, shortDate } from "@/lib/format";
import { EmptyState } from "@/components/ui";
import { BookmarkButton } from "@/components/interactive";

export const metadata: Metadata = { title: "Saved items" };

export default async function BookmarksPage() {
  await requireUser("/bookmarks");
  const rows = await myBookmarks();
  const [notices, events] = await Promise.all([
    Promise.all(rows.filter((r) => r.content_type === "announcement").map((r) => getAnnouncement(r.content_id))),
    Promise.all(rows.filter((r) => r.content_type === "event").map((r) => getEvent(r.content_id))),
  ]);
  const a = notices.filter((x) => x !== null);
  const e = events.filter((x) => x !== null);

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <span className="block h-1.5 w-14 rounded-full bg-gold" aria-hidden />
      <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">Saved items</h1>
      <p className="prose-tight mt-5 text-lg text-mute">Announcements and events you saved, kept on your account.</p>

      <div className="mt-12">
        {a.length === 0 && e.length === 0 ? (
          <EmptyState section="announcements" title="Nothing saved yet" body="Use Save on an announcement or event and it will show up here." />
        ) : (
          <div className="space-y-16">
            {e.length > 0 && (
              <section>
                <h2 className="display-soft text-3xl">Events</h2>
                <ul className="mt-6 border-t border-line">
                  {e.map((ev) => {
                    const d = dayParts(ev.date_time);
                    return (
                      <li key={ev.id} className="flex flex-wrap items-center gap-6 border-b border-line py-6">
                        <div className="tnum flex w-20 flex-col items-center rounded-2xl bg-night px-3 py-3 text-white">
                          <span className="text-xs font-semibold text-[#ff8a80]">{d.weekday}</span>
                          <span className="display text-3xl">{d.day}</span>
                          <span className="text-xs font-semibold">{d.month}</span>
                        </div>
                        <div className="min-w-0 flex-1">
                          <h3 className="display-soft text-2xl">
                            <Link href={`/events/${ev.id}`} className="hover:underline decoration-2 underline-offset-4">{ev.title}</Link>
                          </h3>
                          <p className="text-mute">{clock(ev.date_time)} · {ev.venue}</p>
                        </div>
                        <BookmarkButton type="event" id={ev.id} saved signedIn />
                      </li>
                    );
                  })}
                </ul>
              </section>
            )}
            {a.length > 0 && (
              <section>
                <h2 className="display-soft text-3xl">Announcements</h2>
                <ul className="mt-6 border-t border-line">
                  {a.map((n) => (
                    <li key={n.id} className="flex flex-wrap items-center gap-6 border-b border-line py-6">
                      <div className="min-w-0 flex-1">
                        <h3 className="display-soft text-2xl">
                          <Link href={`/announcements/${n.id}`} className="hover:underline decoration-2 underline-offset-4">{n.title}</Link>
                        </h3>
                        <p className="text-mute">{n.category} · {n.publisher_name} · {shortDate(n.published_at)}</p>
                      </div>
                      <BookmarkButton type="announcement" id={n.id} saved signedIn />
                    </li>
                  ))}
                </ul>
              </section>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
