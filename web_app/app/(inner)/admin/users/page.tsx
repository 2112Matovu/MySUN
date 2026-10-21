import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin, ROLE_LABEL, type Role, type User } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { RoleSelect } from "@/components/admin-actions";
import { ApiDown, ArrowLeft, FilterPills } from "@/components/ui";

export const metadata: Metadata = { title: "User management" };

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ role?: string; q?: string }>;
}) {
  const me = await requireAdmin("/admin/users", true);
  const { role, q = "" } = await searchParams;
  const users = await apiData<User[]>(`/admin/users${role ? `?role=${encodeURIComponent(role)}` : ""}`);
  const term = q.trim().toLowerCase();
  const shown = (users ?? []).filter((u) => !term || u.name.toLowerCase().includes(term) || u.email.toLowerCase().includes(term));

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/admin" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Admin
      </Link>
      <div className="mt-8 flex flex-wrap items-end justify-between gap-6">
        <h1 className="display text-[clamp(3rem,8vw,6.25rem)]">Users</h1>
        <a href="/admin/users/export" className="inline-flex min-h-11 items-center rounded-full border border-line bg-paper px-6 py-2.5 font-semibold hover:border-night/40">
          Export CSV
        </a>
      </div>

      <div className="mt-8 space-y-5">
        <FilterPills
          basePath="/admin/users"
          param="role"
          options={(["student", "publisher", "minor_admin", "admin"] as Role[]).map((r) => ({ value: r, label: ROLE_LABEL[r] }))}
          active={role}
          section="events"
        />
        <form role="search" className="flex max-w-xl gap-3">
          {role && <input type="hidden" name="role" value={role} />}
          <input
            name="q"
            defaultValue={q}
            placeholder="Search by name or email"
            aria-label="Search users"
            className="min-w-0 flex-1 rounded-full border border-line bg-paper px-5 py-3 focus:border-blue focus:outline-none focus:ring-4 focus:ring-blue/15"
          />
          <button className="rounded-full bg-night px-6 py-3 font-semibold text-white hover:bg-blue">Search</button>
        </form>
      </div>

      <div className="mt-10">
        {users === null ? (
          <ApiDown />
        ) : shown.length === 0 ? (
          <p className="border-y border-line py-10 text-mute">No users match.</p>
        ) : (
          <>
            <p className="tnum mb-4 text-mute">{shown.length} {shown.length === 1 ? "user" : "users"}</p>
            <ul className="border-t border-line">
              {shown.map((u) => (
                <li key={u.id} className="grid gap-3 border-b border-line py-5 md:grid-cols-[1fr_auto] md:items-center">
                  <div className="min-w-0">
                    <p className="display-soft truncate text-2xl">{u.name}</p>
                    <p className="truncate text-mute">{u.email}{u.faculty ? ` · ${u.faculty}` : ""}</p>
                  </div>
                  <RoleSelect userId={u.id} role={u.role} self={u.id === me.id} />
                </li>
              ))}
            </ul>
          </>
        )}
      </div>
    </div>
  );
}
