import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import type { Submission } from "@/lib/publish";
import { ArrowRight } from "@/components/ui";

export const metadata: Metadata = { title: "Admin" };

export type Analytics = {
  daily_active_users: number;
  monthly_active_users: number;
  total_users: number;
  publisher_count: number;
  announcements_published: number;
  events_created: number;
  avg_engagement_percent: number;
  api_online?: boolean;
  database_health_percent?: number;
  storage_used_percent?: number;
};

export default async function AdminHome() {
  const user = await requireAdmin("/admin");
  const superAdmin = user.role === "admin";
  const [live, stats] = await Promise.all([
    apiData<Submission[]>("/admin/moderation"),
    superAdmin ? apiData<Analytics>("/admin/analytics") : Promise.resolve(null),
  ]);

  const links = [
    { href: "/admin/moderation", title: "Content review", body: `${live?.length ?? 0} live items to review`, show: true },
    { href: "/admin/users", title: "User management", body: "Roles, access and a CSV export", show: superAdmin },
    { href: "/admin/analytics", title: "Analytics", body: "Activity, content and system health", show: superAdmin },
    { href: "/admin/audit", title: "Audit log", body: "Everything administrators have done", show: superAdmin },
    { href: "/admin/minor-admins", title: "Minor admins", body: "Admins who can review content only", show: superAdmin },
  ].filter((l) => l.show);

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <span className="block h-1.5 w-14 rounded-full bg-red" aria-hidden />
      <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">Admin</h1>
      <p className="prose-tight mt-5 text-lg text-mute">
        Signed in as {user.name}. Sessions end after 30 minutes without activity.
      </p>

      {stats && (
        <dl className="mt-12 grid gap-x-8 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
          {[
            ["Daily active users", stats.daily_active_users],
            ["Active publishers", stats.publisher_count],
            ["Total users", stats.total_users],
            ["Live content", stats.announcements_published + stats.events_created],
          ].map(([k, v]) => (
            <div key={k} className="border-t border-line pt-5">
              <dt className="text-mute">{k}</dt>
              <dd className="tnum display text-6xl">{v}</dd>
            </div>
          ))}
        </dl>
      )}

      <ul className="mt-14 border-t border-line">
        {links.map((l) => (
          <li key={l.href} className="border-b border-line">
            <Link href={l.href} className="group flex items-center gap-5 py-7">
              <span className="min-w-0 flex-1">
                <span className="display-soft block text-[clamp(1.7rem,4vw,2.6rem)]">{l.title}</span>
                <span className="text-mute">{l.body}</span>
              </span>
              <ArrowRight className="h-7 w-7 transition-transform group-hover:translate-x-1.5" />
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
