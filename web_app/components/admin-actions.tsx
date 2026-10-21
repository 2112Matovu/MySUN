"use client";

import { useEffect, useState, useTransition } from "react";
import { Dialog } from "./Dialog";
import { FormMessage, Select, TextArea } from "./forms";
import { removeContent, setRole, setVerified } from "@/app/actions/admin";
import { logout } from "@/app/actions/auth";
import { ROLE_LABEL, type Role } from "@/lib/roles";

const btn = "inline-flex min-h-10 items-center rounded-full border px-4 py-2 text-[0.9rem] font-semibold transition disabled:opacity-60";

export function RemoveContent({ id, title }: { id: string; title: string }) {
  const [reason, setReason] = useState("");
  const [msg, setMsg] = useState<{ ok: boolean; text: string }>();
  const [pending, start] = useTransition();
  return (
    <Dialog trigger="Remove" triggerClassName={`${btn} border-red/40 text-red-deep hover:bg-red/8`} title="Remove this content?">
      {(close) => (
        <div className="space-y-5">
          <p className="text-mute">“{title}” comes down straight away and the publisher gets your reason.</p>
          <TextArea label="Reason" rows={3} value={reason} onChange={(e) => setReason(e.target.value)} required />
          <FormMessage error={msg && !msg.ok ? msg.text : undefined} />
          <div className="flex gap-3">
            <button
              type="button"
              disabled={pending}
              onClick={() =>
                start(async () => {
                  const r = await removeContent(id, reason);
                  if (r.ok) close();
                  else setMsg({ ok: false, text: r.message });
                })
              }
              className="inline-flex min-h-12 flex-1 items-center justify-center rounded-full bg-red-deep px-6 py-3 font-semibold text-white hover:bg-red disabled:opacity-60"
            >
              {pending ? "Removing…" : "Remove"}
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

export function VerifyToggle({ id, verified }: { id: string; verified: boolean }) {
  const [on, setOn] = useState(verified);
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();
  return (
    <>
      <button
        type="button"
        role="switch"
        aria-checked={on}
        disabled={pending}
        onClick={() =>
          start(async () => {
            setError(undefined);
            const next = !on;
            setOn(next);
            const r = await setVerified(id, next);
            if (!r.ok) {
              setOn(!next);
              setError(r.message);
            }
          })
        }
        className={`${btn} ${on ? "border-blue bg-blue text-white" : "border-line bg-paper hover:border-night/40"}`}
      >
        {on ? "Verified" : "Verify"}
      </button>
      {error && <span role="alert" className="text-sm text-red-deep">{error}</span>}
    </>
  );
}

const ROLES: Role[] = ["student", "publisher", "minor_admin", "admin"];

export function RoleSelect({ userId, role, self }: { userId: string; role: Role; self: boolean }) {
  const [value, setValue] = useState<Role>(role);
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();
  return (
    <div className="flex items-center gap-3">
      <Select
        label=""
        aria-label="Role"
        value={value}
        disabled={pending || self}
        title={self ? "You can't change your own role" : undefined}
        onChange={(e) => {
          const next = e.target.value as Role;
          const prev = value;
          setValue(next);
          setError(undefined);
          start(async () => {
            const r = await setRole(userId, next);
            if (!r.ok) {
              setValue(prev);
              setError(r.message);
            }
          });
        }}
        options={ROLES.map((r) => ({ value: r, label: ROLE_LABEL[r] }))}
        className="min-w-44 [&_label]:hidden [&_select]:py-2.5"
      />
      {error && <span role="alert" className="text-sm text-red-deep">{error}</span>}
    </div>
  );
}

/** Admin sessions end after 30 idle minutes. */
export function IdleLogout({ minutes = 30 }: { minutes?: number }) {
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const reset = () => {
      clearTimeout(timer);
      timer = setTimeout(() => void logout(), minutes * 60_000);
    };
    const events = ["mousemove", "keydown", "click", "scroll", "touchstart"] as const;
    events.forEach((e) => window.addEventListener(e, reset, { passive: true }));
    reset();
    return () => {
      clearTimeout(timer);
      events.forEach((e) => window.removeEventListener(e, reset));
    };
  }, [minutes]);
  return null;
}

export function CopyReport({ text }: { text: string }) {
  const [done, setDone] = useState(false);
  return (
    <button
      type="button"
      className="inline-flex min-h-11 items-center rounded-full border border-line bg-paper px-6 py-2.5 font-semibold transition hover:border-night/40"
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(text);
          setDone(true);
          setTimeout(() => setDone(false), 2200);
        } catch {
          /* clipboard blocked */
        }
      }}
    >
      <span aria-live="polite">{done ? "Report copied" : "Copy report"}</span>
    </button>
  );
}
