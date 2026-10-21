import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin, ROLE_LABEL, type Role, type User } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { RoleSelect } from "@/components/admin-actions";
import { ApiDown, ArrowLeft } from "@/components/ui";

export const metadata: Metadata = { title: "Grant access" };

export default async function GrantAccessPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; role?: string }>;
}) {
  const me = await requireAdmin("/admin/grant-access", true);
  const { q = "", role } = await searchParams;
  const wanted = (["publisher", "minor_admin", "admin"] as Role[]).find((r) => r === role);
  const term = q.trim().toLowerCase();
  const users = term.length >= 2 ? await apiData<User[]>("/admin/users") : [];
  const matches = (users ?? []).filter((u) => u.name.toLowerCase().includes(term) || u.email.toLowerCase().includes(term)).slice(0, 12);

  return (
    <div className="mx-auto max-w-3xl px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/admin" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Admin
      </Link>
      <h1 className="display mt-8 text-[clamp(2.8rem,7vw,5rem)]">Grant access</h1>
      <p className="prose-tight mt-5 text-lg text-mute">
        Find the person, then choose their new role{wanted ? ` (suggested: ${ROLE_LABEL[wanted]})` : ""}. The change applies the next time they open MySun.
      </p>
      <form role="search" className="mt-8 flex gap-3">
        {wanted && <input type="hidden" name="role" value={wanted} />}
        <input
          name="q"
          defaultValue={q}
          autoFocus
          placeholder="Search by name or email"
          aria-label="Search users"
          className="min-w-0 flex-1 rounded-full border border-line bg-paper px-5 py-3 focus:border-blue focus:outline-none focus:ring-4 focus:ring-blue/15"
        />
        <button className="rounded-full bg-night px-6 py-3 font-semibold text-white hover:bg-blue">Search</button>
      </form>

      <div className="mt-10">
        {users === null ? (
          <ApiDown />
        ) : term.length < 2 ? (
          <p className="text-mute">Type at least two letters.</p>
        ) : matches.length === 0 ? (
          <p className="border-y border-line py-8 text-mute">No one matches “{q}”.</p>
        ) : (
          <ul className="border-t border-line">
            {matches.map((u) => (
              <li key={u.id} className="grid gap-3 border-b border-line py-5 sm:grid-cols-[1fr_auto] sm:items-center">
                <div className="min-w-0">
                  <p className="display-soft truncate text-2xl">{u.name}</p>
                  <p className="truncate text-mute">{u.email} · now {ROLE_LABEL[u.role]}</p>
                </div>
                <RoleSelect userId={u.id} role={u.role} self={u.id === me.id} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
