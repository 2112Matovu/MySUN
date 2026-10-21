import type { Metadata } from "next";
import { isAdminLevel, requireUser, ROLE_LABEL } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { DeleteAccount, MfaSetup, NotificationPrefsForm } from "@/components/account";
import { logout } from "@/app/actions/auth";

export const metadata: Metadata = { title: "Profile and settings" };

type Prefs = { announcements: boolean; events: boolean; reminders: boolean; transport: boolean };
type Mfa = { enrolled: boolean; verified_this_session: boolean; required: boolean };

function Section({ id, title, children }: { id: string; title: string; children: React.ReactNode }) {
  return (
    <section id={id} className="scroll-mt-8 border-t border-line py-12 lg:grid lg:grid-cols-[16rem_1fr] lg:gap-14">
      <h2 className="display-soft mb-6 text-3xl lg:mb-0">{title}</h2>
      <div>{children}</div>
    </section>
  );
}

export default async function ProfilePage() {
  const user = await requireUser("/profile");
  const [prefs, mfa] = await Promise.all([
    apiData<Prefs>("/notifications/preferences"),
    isAdminLevel(user.role) ? apiData<Mfa>("/auth/mfa/status") : Promise.resolve(null),
  ]);

  const rows: [string, string | null][] = [
    ["Name", user.name],
    ["Email", user.email],
    ["Account type", ROLE_LABEL[user.role]],
    ["Student ID", user.student_id],
    ["Faculty", user.faculty],
    ["Programme", user.program],
  ];

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <span className="block h-1.5 w-14 rounded-full bg-gold" aria-hidden />
      <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">Profile and settings</h1>

      <div className="mt-14">
        <Section id="account" title="Account">
          <dl className="grid gap-x-8 gap-y-6 sm:grid-cols-2">
            {rows
              .filter(([, v]) => v)
              .map(([k, v]) => (
                <div key={k}>
                  <dt className="text-sm text-mute">{k}</dt>
                  <dd className="text-lg font-semibold">{v}</dd>
                </div>
              ))}
          </dl>
        </Section>

        {prefs && (
          <Section id="notifications" title="Notifications">
            <NotificationPrefsForm initial={prefs} />
          </Section>
        )}

        {mfa && (
          <Section id="security" title="Two-factor sign-in">
            <MfaSetup enrolled={mfa.enrolled} verified={mfa.verified_this_session} />
          </Section>
        )}

        <Section id="data" title="Your data">
          <p className="prose-tight text-mute">
            Download a copy of everything MySun holds about you, or delete your account and all of it.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <a
              href="/profile/export"
              className="inline-flex min-h-11 items-center rounded-full border border-line bg-paper px-6 py-2.5 font-semibold transition hover:border-night/40"
            >
              Download my data
            </a>
            <DeleteAccount />
          </div>
        </Section>

        <Section id="session" title="Session">
          <form action={logout}>
            <button className="inline-flex min-h-12 items-center rounded-full bg-night px-7 py-3 font-semibold text-white transition hover:bg-blue">
              Sign out
            </button>
          </form>
        </Section>
      </div>
    </div>
  );
}
