import type { Metadata } from "next";
import Link from "next/link";
import { requirePublisher } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { TYPE_LABEL, type ContentType, type Performance } from "@/lib/publish";
import { ApiDown, ArrowLeft } from "@/components/ui";

export const metadata: Metadata = { title: "My performance" };

export default async function PerformancePage() {
  await requirePublisher("/publish/performance");
  const p = await apiData<Performance>("/publisher/performance");
  const max = p ? Math.max(1, ...Object.values(p.by_type)) : 1;
  const stats = p
    ? [
        ["Posts", p.total_submissions],
        ["Live", p.published],
        ["Removed", p.removed],
        ["Drafts", p.drafts],
        ["Estimated views", p.estimated_views],
        ["Engagement", `${Math.round(p.engagement_percent)}%`],
      ]
    : [];

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/publish" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Publisher dashboard
      </Link>
      <h1 className="display mt-8 text-[clamp(3rem,8vw,6.25rem)]">My performance</h1>
      <div className="mt-12">
        {!p ? (
          <ApiDown />
        ) : (
          <>
            <dl className="grid gap-x-8 gap-y-10 sm:grid-cols-2 lg:grid-cols-3">
              {stats.map(([k, v]) => (
                <div key={k} className="border-t border-line pt-5">
                  <dt className="text-mute">{k}</dt>
                  <dd className="tnum display text-6xl">{v}</dd>
                </div>
              ))}
            </dl>
            <h2 className="display-soft mt-16 text-3xl">Posts by type</h2>
            <ul className="mt-6 max-w-2xl space-y-4">
              {(Object.entries(p.by_type) as [ContentType, number][]).map(([t, n]) => (
                <li key={t}>
                  <div className="tnum flex justify-between text-[0.95rem]">
                    <span className="font-semibold">{TYPE_LABEL[t] ?? t}</span>
                    <span className="text-mute">{n}</span>
                  </div>
                  <div className="mt-1.5 h-2.5 overflow-hidden rounded-full bg-line">
                    <div className="h-full rounded-full bg-blue" style={{ width: `${(n / max) * 100}%` }} />
                  </div>
                </li>
              ))}
            </ul>
          </>
        )}
      </div>
    </div>
  );
}
