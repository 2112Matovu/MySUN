import Link from "next/link";
import { SunMark } from "./SunMark";
import { NavLinks } from "./NavLinks";
import { UserMenu } from "./UserMenu";
import { logout } from "@/app/actions/auth";
import { SECTIONS, SECTION_ORDER } from "@/lib/sections";
import { canPublish, getUser, isAdminLevel, ROLE_LABEL } from "@/lib/auth";
import { apiData } from "@/lib/server-api";

type Note = { is_read?: boolean };

/**
 * `overlay` sits on top of the hero sky and inherits its text colour;
 * otherwise it is a plain bar on the chalk background.
 */
export async function SiteHeader({ overlay = false }: { overlay?: boolean }) {
  const user = await getUser();
  const unread = user
    ? ((await apiData<Note[]>("/notifications")) ?? []).filter((n) => !n.is_read).length
    : 0;

  const accountLinks = user
    ? [
        { href: "/profile", label: "Profile and settings" },
        { href: "/bookmarks", label: "Saved items" },
        { href: "/bookings", label: "Boda bookings" },
        ...(canPublish(user.role) ? [{ href: "/publish", label: "Publisher dashboard" }] : []),
        ...(isAdminLevel(user.role) ? [{ href: "/admin", label: "Admin" }] : []),
      ]
    : [];

  return (
    <header
      className={
        overlay
          ? "absolute inset-x-0 top-0 z-30"
          : "relative z-30 border-b border-line bg-chalk/90"
      }
    >
      <div className="mx-auto flex h-[4.5rem] max-w-[76rem] items-center justify-between gap-6 px-5 sm:px-8">
        <Link href="/" className="flex items-center gap-2.5" aria-label="MySun home">
          <SunMark size={38} lightRays={overlay} />
          <span className="display-soft text-[1.55rem] font-bold tracking-tight">MySun</span>
        </Link>

        <nav aria-label="Main" className="hidden items-center gap-6 lg:flex">
          <NavLinks />
        </nav>

        <div className="flex items-center gap-2.5">
          <Link
            href="/search"
            aria-label="Search"
            className="flex h-11 w-11 items-center justify-center rounded-full transition hover:bg-current/10"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
              <circle cx="11" cy="11" r="7" />
              <path d="m20 20-3.5-3.5" />
            </svg>
          </Link>

          {user ? (
            <>
              <Link
                href="/notifications"
                aria-label={unread > 0 ? `Notifications, ${unread} unread` : "Notifications"}
                className="relative flex h-11 w-11 items-center justify-center rounded-full transition hover:bg-current/10"
              >
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  <path d="M6 9a6 6 0 1 1 12 0c0 6 2 7 2 7H4s2-1 2-7Z" />
                  <path d="M10 20a2 2 0 0 0 4 0" />
                </svg>
                {unread > 0 && (
                  <span className="absolute right-1 top-1 flex h-[1.15rem] min-w-[1.15rem] items-center justify-center rounded-full bg-red px-1 text-[0.7rem] font-bold leading-none text-white">
                    {unread > 9 ? "9+" : unread}
                  </span>
                )}
              </Link>
              <div className="hidden sm:block">
                <UserMenu
                  name={user.name}
                  email={user.email}
                  roleLabel={ROLE_LABEL[user.role]}
                  items={accountLinks}
                />
              </div>
            </>
          ) : (
            <>
              <Link
                href="/login"
                className="hidden rounded-full px-4 py-2.5 text-[0.95rem] font-semibold transition hover:bg-current/10 sm:inline-block"
              >
                Sign in
              </Link>
              <Link
                href="/#get-app"
                className="hidden rounded-full bg-night px-5 py-2.5 text-[0.95rem] font-semibold text-white transition hover:bg-blue sm:inline-block"
              >
                Get the app
              </Link>
            </>
          )}

          {/* Mobile menu: native <details>, no JavaScript needed. */}
          <details className="group relative lg:hidden">
            <summary
              className="flex h-11 w-11 cursor-pointer list-none items-center justify-center rounded-full border border-current/30 [&::-webkit-details-marker]:hidden"
              aria-label="Menu"
            >
              <span className="relative block h-3 w-5" aria-hidden>
                <span className="absolute inset-x-0 top-0 h-0.5 rounded bg-current transition-all group-open:top-1.5 group-open:rotate-45" />
                <span className="absolute inset-x-0 top-1.5 h-0.5 rounded bg-current transition group-open:opacity-0" />
                <span className="absolute inset-x-0 top-3 h-0.5 rounded bg-current transition-all group-open:top-1.5 group-open:-rotate-45" />
              </span>
            </summary>
            <div className="absolute right-0 top-14 w-72 rounded-2xl border border-line bg-paper p-2 text-ink shadow-[0_20px_50px_-20px_rgba(13,27,53,0.45)]">
              {SECTION_ORDER.map((key) => (
                <Link
                  key={key}
                  href={SECTIONS[key].href}
                  className="flex items-center gap-3 rounded-xl px-4 py-3 font-medium hover:bg-chalk"
                >
                  <span className={`h-2.5 w-2.5 rounded-full ${SECTIONS[key].bar}`} />
                  {SECTIONS[key].label}
                </Link>
              ))}
              <div className="mt-1 border-t border-line pt-1">
                {user ? (
                  <>
                    <p className="px-4 py-2 text-sm text-mute">
                      {user.name} · {ROLE_LABEL[user.role]}
                    </p>
                    {accountLinks.map((l) => (
                      <Link key={l.href} href={l.href} className="block rounded-xl px-4 py-3 font-medium hover:bg-chalk">
                        {l.label}
                      </Link>
                    ))}
                    <form action={logout}>
                      <button type="submit" className="block w-full rounded-xl px-4 py-3 text-left font-medium text-red-deep hover:bg-red/8">
                        Sign out
                      </button>
                    </form>
                  </>
                ) : (
                  <>
                    <Link href="/login" className="block rounded-xl px-4 py-3 font-medium hover:bg-chalk">
                      Sign in
                    </Link>
                    <Link href="/signup" className="mt-1 block rounded-xl bg-night px-4 py-3 text-center font-semibold text-white">
                      Create account
                    </Link>
                  </>
                )}
              </div>
            </div>
          </details>
        </div>
      </div>
    </header>
  );
}
