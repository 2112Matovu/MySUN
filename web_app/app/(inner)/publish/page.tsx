import type { Metadata } from "next";
import Link from "next/link";
import { requirePublisher } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { CONTENT_TYPES, TYPE_LABEL, type ContentType, type Submission } from "@/lib/publish";
import { RemoveButton, ScheduleMenu } from "@/components/submission-actions";
import { clock, shortDate } from "@/lib/format";

export const metadata: Metadata = { title: "Publisher dashboard" };

const STATUS = {
  draft: { label: "Draft", cls: "bg-line text-mute" },
  scheduled: { label: "Scheduled", cls: "bg-gold/20 text-gold-deep" },
  published: { label: "Live", cls: "bg-teal/15 text-teal-deep" },
  removed: { label: "Removed", cls: "bg-red/10 text-red-deep" },
} as const;

const COLOR: Record<ContentType, string> = {
  announcement: "bg-gold",
  event: "bg-red",
  accommodation: "bg-teal",
  transport: "bg-blue",
};

export default async function PublishDashboard() {
  const user = await requirePublisher("/publish");
  const subs = (await apiData<Submission[]>("/publisher/submissions")) ?? [];
  const drafts = subs.filter((s) => s.status === "draft");
  const recent = [...subs].sort((a, b) => +new Date(b.updated_at) - +new Date(a.updated_at)).slice(0, 12);

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <span className="block h-1.5 w-14 rounded-full bg-gold" aria-hidden />
      <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">Publish</h1>
      <p className="prose-tight mt-5 text-lg text-mute">
        Welcome back, {user.name}. Posts go live straight away, and administrators can remove anything that breaks the rules.
      </p>

      <ul className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {CONTENT_TYPES.map((t) => (
          <li key={t}>
            <Link
              href={`/publish/new/${t}`}
              className="group relative flex h-full min-h-40 flex-col justify-between overflow-hidden rounded-3xl border border-line bg-paper p-6 transition hover:-translate-y-0.5 hover:shadow-[0_20px_40px_-24px_rgba(13,27,53,0.5)]"
            >
              <span className={`h-1.5 w-12 rounded-full ${COLOR[t]}`} aria-hidden />
              <span>
                <span className="text-sm text-mute">New</span>
                <span className="display-soft block text-[1.6rem]">{TYPE_LABEL[t]}</span>
              </span>
            </Link>
          </li>
        ))}
      </ul>

      <div className="mt-6 flex flex-wrap gap-3">
        <Link href="/publish/drafts" className="inline-flex min-h-11 items-center rounded-full border border-line bg-paper px-6 py-2.5 font-semibold hover:border-night/40">
          Drafts{drafts.length > 0 && <span className="tnum ml-2 rounded-full bg-night px-2 text-sm text-white">{drafts.length}</span>}
        </Link>
        <Link href="/publish/performance" className="inline-flex min-h-11 items-center rounded-full border border-line bg-paper px-6 py-2.5 font-semibold hover:border-night/40">
          My performance
        </Link>
      </div>

      <section className="mt-16">
        <h2 className="display-soft text-3xl">Recent submissions</h2>
        {recent.length === 0 ? (
          <p className="mt-6 border-y border-line py-10 text-mute">Nothing yet. Start with a new announcement or event above.</p>
        ) : (
          <ul className="mt-6 border-t border-line">
            {recent.map((s) => (
              <li key={s.id} className="grid gap-4 border-b border-line py-6 md:grid-cols-[1fr_auto] md:items-center">
                <div>
                  <p className="flex flex-wrap items-center gap-3">
                    <span className={`h-2.5 w-2.5 rounded-full ${COLOR[s.type]}`} aria-hidden />
                    <span className="display-soft text-2xl">{s.title}</span>
                    <span className={`rounded-full px-3 py-0.5 text-sm font-semibold ${STATUS[s.status].cls}`}>{STATUS[s.status].label}</span>
                  </p>
                  <p className="mt-1 text-mute">
                    {TYPE_LABEL[s.type]} ·{" "}
                    {s.status === "scheduled" && s.publish_at
                      ? `goes live ${shortDate(s.publish_at)}, ${clock(s.publish_at)}`
                      : s.status === "removed" && s.removal_reason
                        ? `removed: ${s.removal_reason}`
                        : `updated ${shortDate(s.updated_at)}`}
                  </p>
                </div>
                <div className="flex flex-wrap gap-2">
                  {s.status === "draft" && (
                    <Link href={`/publish/new/${s.type}?draft=${s.id}`} className="inline-flex min-h-10 items-center rounded-full bg-night px-4 py-2 text-[0.9rem] font-semibold text-white hover:bg-blue">
                      Continue
                    </Link>
                  )}
                  {s.status === "scheduled" && <ScheduleMenu s={s} />}
                  {s.status === "published" && <RemoveButton id={s.id} title={s.title} />}
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
