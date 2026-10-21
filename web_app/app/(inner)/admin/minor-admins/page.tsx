import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin, type User } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { RoleSelect } from "@/components/admin-actions";
import { ApiDown, ArrowLeft } from "@/components/ui";

export const metadata: Metadata = { title: "Minor admins" };

export default async function MinorAdminsPage() {
  const me = await requireAdmin("/admin/minor-admins", true);
  const items = await apiData<User[]>("/admin/users?role=minor_admin");
  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/admin" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Admin
      </Link>
      <div className="mt-8 flex flex-wrap items-end justify-between gap-6">
        <h1 className="display text-[clamp(3rem,8vw,6.25rem)]">Minor admins</h1>
        <Link href="/admin/grant-access?role=minor_admin" className="inline-flex min-h-11 items-center rounded-full bg-night px-6 py-2.5 font-semibold text-white hover:bg-blue">
          Add minor admin
        </Link>
      </div>
      <p className="prose-tight mt-5 text-lg text-mute">Minor admins can review and remove content. They can&rsquo;t manage users or see analytics.</p>
      <div className="mt-12">
        {items === null ? (
          <ApiDown />
        ) : items.length === 0 ? (
          <p className="border-y border-line py-10 text-mute">No minor admins yet.</p>
        ) : (
          <ul className="border-t border-line">
            {items.map((u) => (
              <li key={u.id} className="grid gap-3 border-b border-line py-5 md:grid-cols-[1fr_auto] md:items-center">
                <div>
                  <p className="display-soft text-2xl">{u.name}</p>
                  <p className="text-mute">{u.email}</p>
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
