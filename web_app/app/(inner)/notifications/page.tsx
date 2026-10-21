import type { Metadata } from "next";
import Link from "next/link";
import { requireUser } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import type { AppNotification } from "@/lib/me";
import { relativeDay } from "@/lib/format";
import { ApiDown, EmptyState } from "@/components/ui";
import { MarkAllRead, NotificationLink } from "@/components/notifications";

export const metadata: Metadata = { title: "Alerts" };

function hrefFor(n: AppNotification): string | null {
  if (!n.related_id) return null;
  const t = n.type.toLowerCase();
  if (t.includes("announcement")) return `/announcements/${n.related_id}`;
  if (t.includes("event") || t.includes("reminder")) return `/events/${n.related_id}`;
  if (t.includes("booking") || t.includes("transport")) return "/bookings";
  return null;
}

export default async function NotificationsPage() {
  await requireUser("/notifications");
  const items = await apiData<AppNotification[]>("/notifications");
  const unread = (items ?? []).filter((n) => !n.is_read);

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <div className="flex flex-wrap items-end justify-between gap-6">
        <div>
          <span className="block h-1.5 w-14 rounded-full bg-gold" aria-hidden />
          <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">Alerts</h1>
          <p className="prose-tight mt-5 text-lg text-mute">
            Announcements, event reminders and ride updates. Choose which ones you get in{" "}
            <Link href="/profile#notifications" className="font-semibold text-blue hover:underline">your settings</Link>.
          </p>
        </div>
        {unread.length > 0 && <MarkAllRead ids={unread.map((n) => n.id)} />}
      </div>

      <div className="mt-12">
        {items === null ? (
          <ApiDown />
        ) : items.length === 0 ? (
          <EmptyState section="announcements" title="No notifications" body="Alerts about announcements, events and rides land here." />
        ) : (
          <ul className="border-t border-line">
            {items.map((n) => (
              <li key={n.id} className="border-b border-line">
                <NotificationLink id={n.id} href={hrefFor(n)} read={Boolean(n.is_read)}>
                  <span className={`mt-2.5 h-2.5 w-2.5 shrink-0 rounded-full ${n.is_read ? "bg-transparent" : "bg-red"}`} aria-label={n.is_read ? undefined : "Unread"} />
                  <span className="min-w-0 flex-1">
                    <span className={`display-soft block text-[1.4rem] ${n.is_read ? "text-ink/70" : ""}`}>{n.title}</span>
                    <span className="mt-1 block text-mute">{n.body}</span>
                    <span className="mt-1 block text-sm text-mute/80">{relativeDay(n.created_at)}</span>
                  </span>
                </NotificationLink>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
