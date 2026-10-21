"use client";

import { useRef, useState } from "react";

/** Uploads images through /api/upload and reports the hosted URLs. */
export function ImageUpload({
  label,
  urls,
  onChange,
  max = 1,
  hint,
}: {
  label: string;
  urls: string[];
  onChange: (urls: string[]) => void;
  max?: number;
  hint?: string;
}) {
  const input = useRef<HTMLInputElement>(null);
  const camera = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();

  async function pick(files: FileList | null) {
    if (!files || files.length === 0) return;
    setError(undefined);
    setBusy(true);
    const next = [...urls];
    for (const file of Array.from(files)) {
      if (next.length >= max) break;
      const body = new FormData();
      body.append("file", file);
      try {
        const res = await fetch("/api/upload", { method: "POST", body });
        const json = (await res.json()) as { url?: string; message?: string };
        if (!res.ok || !json.url) {
          setError(json.message ?? "The upload failed. Try again.");
          break;
        }
        next.push(json.url);
      } catch {
        setError("Can't reach the server. Check your connection and try again.");
        break;
      }
    }
    onChange(next);
    setBusy(false);
    if (input.current) input.current.value = "";
    if (camera.current) camera.current.value = "";
  }

  return (
    <div>
      <p className="mb-1.5 text-[0.95rem] font-semibold">{label}</p>
      <ul className="flex flex-wrap gap-3">
        {urls.map((u, i) => (
          <li key={u} className="group relative">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={u} alt={`Upload ${i + 1}`} className="h-24 w-32 rounded-2xl object-cover" />
            <button
              type="button"
              aria-label={`Remove photo ${i + 1}`}
              onClick={() => onChange(urls.filter((x) => x !== u))}
              className="absolute -right-2 -top-2 flex h-7 w-7 items-center justify-center rounded-full bg-night text-white shadow"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden>
                <path d="M6 6l12 12M18 6 6 18" />
              </svg>
            </button>
          </li>
        ))}
        {urls.length < max && (
          <li className="flex gap-3">
            <button
              type="button"
              disabled={busy}
              onClick={() => input.current?.click()}
              className="flex h-24 w-32 flex-col items-center justify-center gap-1 rounded-2xl border-2 border-dashed border-line text-sm font-semibold text-mute transition hover:border-blue hover:text-blue disabled:opacity-60"
            >
              <span className="text-2xl leading-none">{busy ? "…" : "+"}</span>
              {busy ? "Uploading" : "Choose photo"}
            </button>
            <button
              type="button"
              disabled={busy}
              onClick={() => camera.current?.click()}
              className="flex h-24 w-32 flex-col items-center justify-center gap-1 rounded-2xl border-2 border-dashed border-line text-sm font-semibold text-mute transition hover:border-blue hover:text-blue disabled:opacity-60"
            >
              <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <path d="M4 8h3l2-3h6l2 3h3v11H4z" />
                <circle cx="12" cy="13" r="3.5" />
              </svg>
              Take photo
            </button>
          </li>
        )}
      </ul>
      <input
        ref={input}
        type="file"
        accept="image/*"
        multiple={max > 1}
        className="sr-only"
        tabIndex={-1}
        onChange={(e) => pick(e.target.files)}
      />
      <input
        ref={camera}
        type="file"
        accept="image/*"
        capture="environment"
        className="sr-only"
        tabIndex={-1}
        onChange={(e) => pick(e.target.files)}
      />
      {hint && !error && <p className="mt-1.5 text-sm text-mute">{hint}</p>}
      {error && <p role="alert" className="mt-1.5 text-sm text-red-deep">{error}</p>}
    </div>
  );
}
