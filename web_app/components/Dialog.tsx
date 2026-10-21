"use client";

import { useRef } from "react";

/** A button that opens a native modal <dialog>. Focus trapping and Escape come from the browser. */
export function Dialog({
  trigger,
  triggerClassName,
  title,
  children,
}: {
  trigger: React.ReactNode;
  triggerClassName: string;
  title: string;
  children: (close: () => void) => React.ReactNode;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const close = () => ref.current?.close();
  return (
    <>
      <button type="button" className={triggerClassName} onClick={() => ref.current?.showModal()}>
        {trigger}
      </button>
      <dialog
        ref={ref}
        onClick={(e) => e.target === ref.current && close()}
        className="m-auto w-[min(32rem,calc(100vw-2rem))] rounded-3xl border-0 bg-paper p-0 text-ink shadow-[0_30px_80px_-20px_rgba(13,27,53,0.6)] backdrop:bg-night/60 backdrop:backdrop-blur-sm"
      >
        <div className="p-7 sm:p-8">
          <div className="mb-6 flex items-start justify-between gap-4">
            <h2 className="display-soft text-3xl">{title}</h2>
            <button
              type="button"
              onClick={close}
              aria-label="Close"
              className="-mr-2 -mt-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-mute hover:bg-chalk"
            >
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
                <path d="M6 6l12 12M18 6 6 18" />
              </svg>
            </button>
          </div>
          {children(close)}
        </div>
      </dialog>
    </>
  );
}
