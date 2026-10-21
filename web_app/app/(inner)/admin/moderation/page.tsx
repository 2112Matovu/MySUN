import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { getTransport } from "@/lib/api";
import { TYPE_LABEL, type Submission } from "@/lib/publish";
import { RemoveContent, VerifyToggle } from "@/components/admin-actions";
import { ArrowLeft, EmptyState } from "@/components/ui";
import { relativeDay } from "@/lib/format";

export const metadata: Metadata = { title: "Content review" };

export default async function ModerationPage() {
  await requireAdmin("/admin/moderation");
  const [items, providers] = await Promise.all([apiData<Submission[]>("/admin/moderation"), getTransport()]);

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/admin" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Admin
      </Link>
      <h1 className="display mt-8 text-[clamp(3rem,8vw,6.25rem)]">Content review</h1>
      <p className="prose-tight mt-5 text-lg text-mute">
        Everything live or scheduled. Publishing needs no approval, so this is where you take down anything that breaks the rules.
      </p>

      <div className="mt-12">
        {!items || items.length === 0 ? (
          <EmptyState section="events" title="Nothing to review" body="Live and scheduled posts appear here." />
        ) : (
          <ul className="border-t border-line">
            {items.map((s) => (
              <li key={s.id} className="grid gap-4 border-b border-line py-6 md:grid-cols-[1fr_auto] md:items-center">
                <div>
                  <p className="text-sm font-semibold text-mute">{TYPE_LABEL[s.type]} · {s.status === "scheduled" ? "Scheduled" : "Live"}</p>
                  <p className="display-soft text-2xl">{s.title}</p>
                  <p className="text-mute">By {s.publisher_name ?? "unknown"} · updated {relativeDay(s.updated_at)}</p>
                </div>
                <RemoveContent id={s.id} title={s.title} />
              </li>
            ))}
          </ul>
        )}
      </div>

      {providers && providers.length > 0 && (
        <section className="mt-20">
          <h2 className="display-soft text-3xl">Boda verification</h2>
          <p className="prose-tight mt-3 text-mute">New listings start unverified. Verify a rider once you have checked them.</p>
          <ul className="mt-6 border-t border-line">
            {providers.map((p) => (
              <li key={p.id} className="flex flex-wrap items-center justify-between gap-4 border-b border-line py-5">
                <div>
                  <p className="display-soft text-2xl">{p.name}</p>
                  <p className="text-mute">{p.phone_number}</p>
                </div>
                <div className="flex items-center gap-3">
                  <VerifyToggle id={p.id} verified={Boolean(p.is_verified)} />
                </div>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
