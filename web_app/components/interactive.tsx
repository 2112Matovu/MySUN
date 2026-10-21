"use client";

import Link from "next/link";
import { useActionState, useOptimistic, useState, useTransition } from "react";
import { usePathname } from "next/navigation";
import { Dialog } from "./Dialog";
import { Field, FormMessage, SubmitButton, TextArea } from "./forms";
import {
  cancelBooking,
  createBooking,
  rateProvider,
  respondToBooking,
  setEventRegistration,
  toggleBookmark,
  type ActionResult,
} from "@/app/actions/content";

const pill =
  "inline-flex min-h-11 items-center justify-center gap-2 rounded-full px-5 py-2.5 text-[0.95rem] font-semibold transition disabled:opacity-60";

function useSignInHref() {
  const path = usePathname();
  return `/login?next=${encodeURIComponent(path)}`;
}

export function BookmarkButton({
  type,
  id,
  saved,
  signedIn,
  tone = "light",
}: {
  type: "announcement" | "event";
  id: string;
  saved: boolean;
  signedIn: boolean;
  tone?: "light" | "dark";
}) {
  const path = usePathname();
  const signIn = useSignInHref();
  const [optimistic, setOptimistic] = useOptimistic(saved);
  const [, start] = useTransition();
  const [error, setError] = useState<string>();

  const style =
    tone === "dark"
      ? "border border-white/30 text-white hover:bg-white/10"
      : "border border-line bg-paper text-ink hover:border-night/40";

  if (!signedIn) {
    return (
      <Link href={signIn} className={`${pill} ${style}`}>
        <Bookmark filled={false} /> Save
      </Link>
    );
  }
  return (
    <>
      <button
        type="button"
        aria-pressed={optimistic}
        className={`${pill} ${style}`}
        onClick={() =>
          start(async () => {
            setError(undefined);
            setOptimistic(!optimistic);
            const r = await toggleBookmark(type, id, path);
            if (!r.ok) setError(r.message);
          })
        }
      >
        <Bookmark filled={optimistic} /> {optimistic ? "Saved" : "Save"}
      </button>
      {error && <span role="alert" className="text-sm text-red-deep">{error}</span>}
    </>
  );
}

function Bookmark({ filled }: { filled: boolean }) {
  return (
    <svg viewBox="0 0 24 24" className="h-[1.1em] w-[1.1em]" fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth="2" strokeLinejoin="round" aria-hidden>
      <path d="M6 3h12v18l-6-4-6 4Z" />
    </svg>
  );
}

export function RegisterButton({
  id,
  registered,
  full,
  past,
  signedIn,
}: {
  id: string;
  registered: boolean;
  full: boolean;
  past: boolean;
  signedIn: boolean;
}) {
  const signIn = useSignInHref();
  const [optimistic, setOptimistic] = useOptimistic(registered);
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();

  if (past) return <p className="text-white/70">This event has ended.</p>;
  if (!signedIn) {
    return (
      <Link href={signIn} className={`${pill} bg-gold text-night hover:bg-white`}>
        Sign in to register
      </Link>
    );
  }
  if (full && !optimistic) {
    return <p className="font-semibold text-[#ff8a80]">Event full</p>;
  }
  return (
    <div className="flex flex-col items-start gap-2">
      <button
        type="button"
        disabled={pending}
        className={`${pill} ${
          optimistic ? "border border-white/40 text-white hover:bg-white/10" : "bg-gold text-night hover:bg-white"
        }`}
        onClick={() =>
          start(async () => {
            setError(undefined);
            setOptimistic(!optimistic);
            const r = await setEventRegistration(id, !optimistic);
            if (!r.ok) setError(r.message);
          })
        }
      >
        {optimistic ? "Cancel registration" : "Register"}
      </button>
      {error && <p role="alert" className="text-sm text-[#ff8a80]">{error}</p>}
    </div>
  );
}

export function CopyLinkButton({ tone = "light" }: { tone?: "light" | "dark" }) {
  const [done, setDone] = useState(false);
  const style =
    tone === "dark"
      ? "border border-white/30 text-white hover:bg-white/10"
      : "border border-line bg-paper text-ink hover:border-night/40";
  return (
    <button
      type="button"
      className={`${pill} ${style}`}
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(window.location.href);
          setDone(true);
          setTimeout(() => setDone(false), 2200);
        } catch {
          /* clipboard blocked: nothing to do */
        }
      }}
    >
      <svg viewBox="0 0 24 24" className="h-[1.1em] w-[1.1em]" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1" />
      </svg>
      <span aria-live="polite">{done ? "Link copied" : "Copy link"}</span>
    </button>
  );
}

/* ----- Boda: rate and book ----- */

export function RateDialog({ id, name, signedIn }: { id: string; name: string; signedIn: boolean }) {
  const signIn = useSignInHref();
  if (!signedIn) {
    return (
      <Link href={signIn} className={`${pill} border border-line hover:border-night/40`}>
        Rate
      </Link>
    );
  }
  return (
    <Dialog
      trigger="Rate"
      triggerClassName={`${pill} border border-line bg-paper hover:border-night/40`}
      title={`Rate ${name}`}
    >
      {(close) => <RateForm id={id} close={close} />}
    </Dialog>
  );
}

function RateForm({ id, close }: { id: string; close: () => void }) {
  const [stars, setStars] = useState(0);
  const [comment, setComment] = useState("");
  const [msg, setMsg] = useState<ActionResult>();
  const [pending, start] = useTransition();
  return (
    <form
      className="space-y-5"
      onSubmit={(e) => {
        e.preventDefault();
        if (stars === 0) return setMsg({ ok: false, message: "Choose 1 to 5 stars." });
        start(async () => {
          const r = await rateProvider(id, stars, comment);
          setMsg(r);
          if (r.ok) setTimeout(close, 900);
        });
      }}
    >
      <div role="radiogroup" aria-label="Stars" className="flex gap-1">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            role="radio"
            aria-checked={stars === n}
            aria-label={`${n} ${n === 1 ? "star" : "stars"}`}
            onClick={() => setStars(n)}
            className={`text-4xl leading-none transition hover:scale-110 ${n <= stars ? "text-gold" : "text-line"}`}
          >
            ★
          </button>
        ))}
      </div>
      <TextArea label="Comment (optional)" rows={3} value={comment} onChange={(e) => setComment(e.target.value)} maxLength={500} />
      <FormMessage error={msg && !msg.ok ? msg.message : undefined} notice={msg?.ok ? msg.message : undefined} />
      <button type="submit" disabled={pending} className={`${pill} w-full bg-night text-white hover:bg-blue`}>
        {pending ? "Saving…" : "Save rating"}
      </button>
    </form>
  );
}

export function BookDialog({ id, name, signedIn }: { id: string; name: string; signedIn: boolean }) {
  const signIn = useSignInHref();
  if (!signedIn) {
    return (
      <Link href={signIn} className={`${pill} bg-night text-white hover:bg-blue`}>
        Book
      </Link>
    );
  }
  return (
    <Dialog trigger="Book" triggerClassName={`${pill} bg-night text-white hover:bg-blue`} title={`Book ${name}`}>
      {(close) => <BookForm id={id} close={close} />}
    </Dialog>
  );
}

function BookForm({ id, close }: { id: string; close: () => void }) {
  const [state, action] = useActionState<ActionResult | undefined, FormData>(createBooking, undefined);
  const [when, setWhen] = useState<"now" | "later">("now");
  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="provider_id" value={id} />
      <FormMessage error={state && !state.ok ? state.message : undefined} notice={state?.ok ? state.message : undefined} />
      <Field label="Pick-up point" name="pickup" required maxLength={120} />
      <Field label="Destination" name="destination" required maxLength={120} />
      <fieldset>
        <legend className="mb-2 text-[0.95rem] font-semibold">When</legend>
        <div className="flex gap-2">
          {(["now", "later"] as const).map((w) => (
            <label key={w} className={`${pill} cursor-pointer border ${when === w ? "border-night bg-night text-white" : "border-line"}`}>
              <input type="radio" name="when" value={w} checked={when === w} onChange={() => setWhen(w)} className="sr-only" />
              {w === "now" ? "As soon as possible" : "Choose a time"}
            </label>
          ))}
        </div>
      </fieldset>
      {when === "later" && <Field label="Pick-up time (Soroti time)" name="time" type="datetime-local" required />}
      <TextArea label="Note for the rider (optional)" name="note" rows={2} maxLength={300} />
      {state?.ok ? (
        <button type="button" onClick={close} className={`${pill} w-full bg-night text-white`}>
          Done
        </button>
      ) : (
        <SubmitButton pending="Sending…" className="w-full">
          Send request
        </SubmitButton>
      )}
    </form>
  );
}

/* ----- Bookings list actions ----- */

export function BookingAction({
  label,
  run,
  tone = "light",
}: {
  label: string;
  run: { kind: "cancel"; id: string } | { kind: "respond"; id: string; action: "accept" | "decline" | "complete" };
  tone?: "light" | "dark" | "danger";
}) {
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();
  const styles = {
    light: "border border-line bg-paper hover:border-night/40",
    dark: "bg-night text-white hover:bg-blue",
    danger: "border border-red/40 text-red-deep hover:bg-red/8",
  };
  return (
    <>
      <button
        type="button"
        disabled={pending}
        className={`${pill} ${styles[tone]}`}
        onClick={() =>
          start(async () => {
            const r = run.kind === "cancel" ? await cancelBooking(run.id) : await respondToBooking(run.id, run.action);
            if (!r.ok) setError(r.message);
          })
        }
      >
        {pending ? "Working…" : label}
      </button>
      {error && <span role="alert" className="text-sm text-red-deep">{error}</span>}
    </>
  );
}
