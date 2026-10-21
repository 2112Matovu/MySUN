"use client";

import { useState, useTransition } from "react";
import { Dialog } from "./Dialog";
import { Field, FormMessage } from "./forms";
import { deleteAccount, saveNotificationPrefs } from "@/app/actions/content";
import { finishMfaSetup, startMfaSetup, type MfaStart } from "@/app/actions/account";

type Prefs = { announcements: boolean; events: boolean; reminders: boolean; transport: boolean };

const LABELS: { key: keyof Prefs; title: string; body: string }[] = [
  { key: "announcements", title: "Announcements", body: "New notices, especially the important ones." },
  { key: "events", title: "Events", body: "When an event is published." },
  { key: "reminders", title: "Reminders", body: "A nudge before events you registered for." },
  { key: "transport", title: "Transport", body: "Replies to your boda requests." },
];

export function NotificationPrefsForm({ initial }: { initial: Prefs }) {
  const [prefs, setPrefs] = useState(initial);
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();

  const toggle = (key: keyof Prefs) => {
    const next = { ...prefs, [key]: !prefs[key] };
    setPrefs(next);
    setError(undefined);
    start(async () => {
      const r = await saveNotificationPrefs(next);
      if (!r.ok) {
        setPrefs(prefs);
        setError(r.message);
      }
    });
  };

  return (
    <div>
      <ul className="divide-y divide-line border-y border-line">
        {LABELS.map((l) => (
          <li key={l.key} className="flex items-center justify-between gap-6 py-5">
            <div>
              <p className="font-semibold">{l.title}</p>
              <p className="text-[0.95rem] text-mute">{l.body}</p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={prefs[l.key]}
              aria-label={l.title}
              onClick={() => toggle(l.key)}
              className={`relative h-8 w-14 shrink-0 rounded-full transition ${prefs[l.key] ? "bg-teal" : "bg-line"}`}
            >
              <span className={`absolute top-1 h-6 w-6 rounded-full bg-white shadow transition-all ${prefs[l.key] ? "left-7" : "left-1"}`} />
            </button>
          </li>
        ))}
      </ul>
      <p className="mt-3 min-h-5 text-sm text-mute" aria-live="polite">
        {error ? <span className="text-red-deep">{error}</span> : pending ? "Saving…" : "Changes save as you make them."}
      </p>
      <p className="text-sm text-mute">Notices about content you published, such as a removal, are always sent.</p>
    </div>
  );
}

export function MfaSetup({ enrolled, verified }: { enrolled: boolean; verified: boolean }) {
  const [setup, setSetup] = useState<Extract<MfaStart, { ok: true }>>();
  const [code, setCode] = useState("");
  const [msg, setMsg] = useState<{ ok: boolean; text: string }>();
  const [pending, start] = useTransition();

  if (enrolled && !setup) {
    return (
      <p className="rounded-2xl bg-teal/10 px-5 py-4 font-medium text-teal-deep">
        Two-factor is on{verified ? "." : ", but this session hasn't been verified yet."} You will be asked for a code each time you sign in.
      </p>
    );
  }

  if (!setup) {
    return (
      <div>
        <p className="prose-tight text-mute">
          Protect this admin account with an authenticator app such as Google Authenticator or Authy.
        </p>
        <button
          type="button"
          disabled={pending}
          className="mt-5 inline-flex min-h-12 items-center rounded-full bg-night px-7 py-3 font-semibold text-white transition hover:bg-blue disabled:opacity-60"
          onClick={() =>
            start(async () => {
              const r = await startMfaSetup();
              if (r.ok) setSetup(r);
              else setMsg({ ok: false, text: r.message });
            })
          }
        >
          {pending ? "Preparing…" : "Set up two-factor"}
        </button>
        {msg && <div className="mt-4"><FormMessage error={msg.ok ? undefined : msg.text} /></div>}
      </div>
    );
  }

  return (
    <div className="grid gap-8 sm:grid-cols-[12rem_1fr]">
      {setup.qr ? (
        <div
          className="h-48 w-48 rounded-2xl border border-line bg-white p-2 [&>svg]:h-full [&>svg]:w-full"
          role="img"
          aria-label="QR code for your authenticator app"
          dangerouslySetInnerHTML={{ __html: setup.qr }}
        />
      ) : null}
      <div className="space-y-4">
        <p className="text-mute">Scan the code with your authenticator app, or enter this key by hand:</p>
        <code className="block break-all rounded-xl bg-night px-4 py-3 text-sm tracking-wider text-white">{setup.secret}</code>
        <Field label="Code from the app" inputMode="numeric" maxLength={7} value={code} onChange={(e) => setCode(e.target.value)} />
        <FormMessage error={msg && !msg.ok ? msg.text : undefined} notice={msg?.ok ? msg.text : undefined} />
        <button
          type="button"
          disabled={pending}
          className="inline-flex min-h-12 items-center rounded-full bg-night px-7 py-3 font-semibold text-white transition hover:bg-blue disabled:opacity-60"
          onClick={() =>
            start(async () => {
              const r = await finishMfaSetup(setup.factor, code);
              setMsg({ ok: r.ok, text: r.ok ? "Two-factor is on." : (r.message ?? "That code didn't work.") });
              if (r.ok) setSetup(undefined);
            })
          }
        >
          {pending ? "Checking…" : "Turn on"}
        </button>
      </div>
    </div>
  );
}

export function DeleteAccount() {
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();
  return (
    <Dialog
      trigger="Delete account"
      triggerClassName="inline-flex min-h-11 items-center rounded-full border border-red/40 px-6 py-2.5 font-semibold text-red-deep transition hover:bg-red/8"
      title="Delete your account?"
    >
      {(close) => (
        <div className="space-y-5">
          <p className="text-mute">
            This permanently removes your account, saved items, bookings and ratings. It can&rsquo;t be undone.
          </p>
          <FormMessage error={error} />
          <div className="flex gap-3">
            <button
              type="button"
              disabled={pending}
              onClick={() =>
                start(async () => {
                  const r = await deleteAccount();
                  if (r && !r.ok) setError(r.message);
                })
              }
              className="inline-flex min-h-12 flex-1 items-center justify-center rounded-full bg-red-deep px-6 py-3 font-semibold text-white transition hover:bg-red disabled:opacity-60"
            >
              {pending ? "Deleting…" : "Delete my account"}
            </button>
            <button type="button" onClick={close} className="inline-flex min-h-12 items-center rounded-full border border-line px-6 py-3 font-semibold">
              Cancel
            </button>
          </div>
        </div>
      )}
    </Dialog>
  );
}
