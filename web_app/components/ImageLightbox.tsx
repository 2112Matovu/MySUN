"use client";

import { useRef } from "react";

/**
 * Wraps an image exactly as it is shown today; clicking it opens the whole,
 * uncropped picture in a full-screen viewer (Escape, the X or a click outside closes it).
 */
export function ImageLightbox({
  src,
  alt,
  children,
  className = "",
}: {
  src: string;
  alt: string;
  children: React.ReactNode;
  className?: string;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const close = () => ref.current?.close();
  return (
    <>
      <button
        type="button"
        onClick={() => ref.current?.showModal()}
        aria-label={`View full image: ${alt}`}
        className={`block w-full cursor-zoom-in text-left ${className}`}
      >
        {children}
      </button>
      <dialog
        ref={ref}
        onClick={(e) => e.target === ref.current && close()}
        className="m-auto h-dvh max-h-none w-screen max-w-none border-0 bg-transparent p-0 backdrop:bg-black/90"
      >
        <div className="flex h-full w-full items-center justify-center p-4 sm:p-8" onClick={close}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={src} alt={alt} className="max-h-full max-w-full object-contain" />
        </div>
        <button
          type="button"
          onClick={close}
          aria-label="Close"
          className="absolute right-4 top-4 flex h-11 w-11 items-center justify-center rounded-full bg-white/15 text-white backdrop-blur hover:bg-white/30"
        >
          <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </dialog>
    </>
  );
}
