"use client";

import { useState, useTransition } from "react";
import { Dialog } from "./Dialog";
import { Field, FormMessage } from "./forms";
import { discardDraft, removeOwnSubmission, rescheduleContent } from "@/app/actions/publish";
import { isoToSoroti, sorotiToIso, type Submission } from "@/lib/publish";

const btn =
  "inline-flex min-h-10 items-center rounded-full border px-4 py-2 text-[0.9rem] font-semibold transition disabled:opacity-60";

export function RemoveButton({ id, title }: { id: string; title: string }) {
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();
  return (
    <Dialog trigger="Remove" triggerClassName={`${btn} border-red/40 text-red-deep hover:bg-red/8`} title="Remove this listing?">
      {(close) => (
        <div className="space-y-5">
          <p className="text-mute">“{title}” will disappear from MySun straight away.</p>
          <FormMessage error={error} />
          <div className="flex gap-3">
            <button
              type="button"
              disabled={pending}
              onClick={() =>
                start(async () => {
                  const r = await removeOwnSubmission(id);
                  if (!r.ok) setError(r.message);
                  else close();
                })
              }
              className="inline-flex min-h-12 flex-1 items-center justify-center rounded-full bg-red-deep px-6 py-3 font-semibold text-white hover:bg-red disabled:opacity-60"
            >
              {pending ? "Removing…" : "Remove"}
            </button>
            <button type="button" onClick={close} className="inline-flex min-h-12 items-center rounded-full border border-line px-6 py-3 font-semibold">
              Keep it
            </button>
          </div>
        </div>
      )}
    </Dialog>
  );
}

export function DiscardButton({ id }: { id: string }) {
  const [pending, start] = useTransition();
  return (
    <button
      type="button"
      disabled={pending}
      onClick={() => start(async () => void (await discardDraft(id)))}
      className={`${btn} border-red/40 text-red-deep hover:bg-red/8`}
    >
      {pending ? "Discarding…" : "Discard"}
    </button>
  );
}

/** Change the go-live time of a scheduled announcement or event, publish it now, or cancel it. */
export function ScheduleMenu({ s }: { s: Submission }) {
  const [when, setWhen] = useState(isoToSoroti(s.publish_at));
  const [msg, setMsg] = useState<{ ok: boolean; text: string }>();
  const [pending, start] = useTransition();
  if (!s.content_id || (s.type !== "announcement" && s.type !== "event")) return <RemoveButton id={s.id} title={s.title} />;
  const type = s.type;
  const contentId = s.content_id;

  const run = (publishAt: string | null) =>
    start(async () => {
      const r = await rescheduleContent(type, contentId, publishAt);
      setMsg({ ok: r.ok, text: r.message });
    });

  return (
    <>
      <Dialog trigger="Change time" triggerClassName={`${btn} border-line bg-paper hover:border-night/40`} title="Go-live time">
        {(close) => (
          <div className="space-y-5">
            <Field label="Goes live at (Soroti time)" type="datetime-local" value={when} onChange={(e) => setWhen(e.target.value)} />
            <FormMessage error={msg && !msg.ok ? msg.text : undefined} notice={msg?.ok ? msg.text : undefined} />
            <div className="flex flex-wrap gap-3">
              <button
                type="button"
                disabled={pending}
                onClick={() => {
                  const iso = sorotiToIso(when);
                  if (!iso || +new Date(iso) < Date.now()) return setMsg({ ok: false, text: "Pick a time in the future." });
                  run(iso);
                }}
                className="inline-flex min-h-12 items-center rounded-full bg-night px-6 py-3 font-semibold text-white hover:bg-blue disabled:opacity-60"
              >
                Save time
              </button>
              <button type="button" disabled={pending} onClick={() => run(null)} className="inline-flex min-h-12 items-center rounded-full border border-line px-6 py-3 font-semibold disabled:opacity-60">
                Publish now
              </button>
              <button type="button" onClick={close} className="inline-flex min-h-12 items-center rounded-full px-4 py-3 font-semibold text-mute">
                Close
              </button>
            </div>
          </div>
        )}
      </Dialog>
      <RemoveButton id={s.id} title={s.title} />
    </>
  );
}
