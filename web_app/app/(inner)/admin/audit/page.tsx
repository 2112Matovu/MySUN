import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { ApiDown, ArrowLeft, EmptyState } from "@/components/ui";
import { clock, shortDate } from "@/lib/format";

export const metadata: Metadata = { title: "Audit log" };

type Entry = {
  id: string;
  actor_name?: string | null;
  action: string;
  target_type?: string | null;
  target_id?: string | null;
  detail?: Record<string, unknown>;
  created_at: string;
};

const ACTION: Record<string, string> = {
  content_removed: "Removed content",
  role_change: "Changed a role",
  verify_toggle: "Changed boda verification",
  users_exported: "Exported the user list",
  mfa_verified: "Passed two-factor",
};

function describe(e: Entry) {
  const d = e.detail ?? {};
  if (e.action === "role_change") return `${d.name ?? "A user"}: ${d.from} to ${d.to}`;
  if (e.action === "content_removed") return `“${d.title ?? "Untitled"}”: ${d.reason ?? ""}`;
  if (e.action === "verify_toggle") return d.is_verified ? "Marked verified" : "Verification removed";
  if (e.action === "users_exported") return `${d.count ?? "All"} users`;
  return "";
}

export default async function AuditPage() {
  await requireAdmin("/admin/audit", true);
  const rows = await apiData<Entry[]>("/admin/audit?limit=200");
  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/admin" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Admin
      </Link>
      <h1 className="display mt-8 text-[clamp(3rem,8vw,6.25rem)]">Audit log</h1>
      <p className="prose-tight mt-5 text-lg text-mute">The most recent 200 things administrators have done, newest first.</p>
      <div className="mt-12">
        {rows === null ? (
          <ApiDown />
        ) : rows.length === 0 ? (
          <EmptyState section="events" title="Nothing logged yet" body="Administrator actions are recorded here." />
        ) : (
          <ul className="border-t border-line">
            {rows.map((e) => (
              <li key={e.id} className="grid gap-2 border-b border-line py-5 md:grid-cols-[11rem_1fr] md:gap-8">
                <p className="tnum text-mute">{shortDate(e.created_at)}<br className="hidden md:block" /> <span className="md:block">{clock(e.created_at)}</span></p>
                <div>
                  <p className="display-soft text-xl">{ACTION[e.action] ?? e.action.replace(/_/g, " ")}</p>
                  <p className="text-mute">
                    by {e.actor_name ?? "unknown"}
                    {describe(e) && ` · ${describe(e)}`}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
