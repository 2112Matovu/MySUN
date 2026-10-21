import type { Metadata } from "next";
import Link from "next/link";
import { requirePublisher } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { TYPE_LABEL, type Submission } from "@/lib/publish";
import { DiscardButton } from "@/components/submission-actions";
import { ArrowLeft, EmptyState } from "@/components/ui";
import { relativeDay } from "@/lib/format";

export const metadata: Metadata = { title: "Drafts" };

export default async function DraftsPage() {
  await requirePublisher("/publish/drafts");
  const drafts = (await apiData<Submission[]>("/publisher/drafts")) ?? [];
  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/publish" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Publisher dashboard
      </Link>
      <h1 className="display mt-8 text-[clamp(3rem,8vw,6.25rem)]">Drafts</h1>
      <div className="mt-10">
        {drafts.length === 0 ? (
          <EmptyState section="announcements" title="No drafts" body="Use Save draft on any form and it will wait for you here." />
        ) : (
          <ul className="border-t border-line">
            {drafts.map((d) => (
              <li key={d.id} className="grid gap-4 border-b border-line py-6 md:grid-cols-[1fr_auto] md:items-center">
                <div>
                  <p className="display-soft text-2xl">{d.title}</p>
                  <p className="text-mute">{TYPE_LABEL[d.type]} · saved {relativeDay(d.updated_at)}</p>
                </div>
                <div className="flex gap-2">
                  <Link href={`/publish/new/${d.type}?draft=${d.id}`} className="inline-flex min-h-10 items-center rounded-full bg-night px-4 py-2 text-[0.9rem] font-semibold text-white hover:bg-blue">
                    Continue
                  </Link>
                  <DiscardButton id={d.id} />
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
