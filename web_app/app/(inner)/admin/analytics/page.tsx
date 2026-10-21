import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { ApiDown, ArrowLeft } from "@/components/ui";
import { CopyReport } from "@/components/admin-actions";
import type { Analytics } from "../page";
import { longDate } from "@/lib/format";

export const metadata: Metadata = { title: "Analytics" };

function Meter({ label, value, good = true }: { label: string; value: number; good?: boolean }) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div>
      <div className="tnum flex justify-between">
        <span className="font-semibold">{label}</span>
        <span className="text-mute">{Math.round(pct)}%</span>
      </div>
      <div className="mt-2 h-2.5 overflow-hidden rounded-full bg-line" role="img" aria-label={`${label} ${Math.round(pct)} percent`}>
        <div className={`h-full rounded-full ${good ? "bg-teal" : "bg-gold"}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export default async function AnalyticsPage() {
  await requireAdmin("/admin/analytics", true);
  const a = await apiData<Analytics>("/admin/analytics");

  const report = a
    ? [
        `MySun admin report, ${longDate(new Date().toISOString())}`,
        `Total users: ${a.total_users}`,
        `Daily active users: ${a.daily_active_users}`,
        `Monthly active users: ${a.monthly_active_users}`,
        `Publishers: ${a.publisher_count}`,
        `Announcements live: ${a.announcements_published}`,
        `Events live: ${a.events_created}`,
        `Average engagement: ${Math.round(a.avg_engagement_percent)}%`,
      ].join("\n")
    : "";

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/admin" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Admin
      </Link>
      <div className="mt-8 flex flex-wrap items-end justify-between gap-6">
        <h1 className="display text-[clamp(3rem,8vw,6.25rem)]">Analytics</h1>
        {a && <CopyReport text={report} />}
      </div>

      <div className="mt-12">
        {!a ? (
          <ApiDown />
        ) : (
          <>
            <dl className="grid gap-x-8 gap-y-10 sm:grid-cols-2 lg:grid-cols-3">
              {[
                ["Total users", a.total_users],
                ["Daily active users", a.daily_active_users],
                ["Monthly active users", a.monthly_active_users],
                ["Publishers", a.publisher_count],
                ["Announcements live", a.announcements_published],
                ["Events live", a.events_created],
              ].map(([k, v]) => (
                <div key={k} className="border-t border-line pt-5">
                  <dt className="text-mute">{k}</dt>
                  <dd className="tnum display text-6xl">{v}</dd>
                </div>
              ))}
            </dl>

            <h2 className="display-soft mt-16 text-3xl">System</h2>
            <div className="mt-6 grid max-w-2xl gap-6">
              <p className="flex items-center gap-3 font-semibold">
                <span className={`h-3 w-3 rounded-full ${a.api_online === false ? "bg-red" : "bg-teal"}`} aria-hidden />
                API {a.api_online === false ? "offline" : "online"}
              </p>
              <Meter label="Average engagement" value={a.avg_engagement_percent} />
              {a.database_health_percent !== undefined && <Meter label="Database health" value={a.database_health_percent} />}
              {a.storage_used_percent !== undefined && <Meter label="Storage used" value={a.storage_used_percent} good={a.storage_used_percent < 80} />}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
