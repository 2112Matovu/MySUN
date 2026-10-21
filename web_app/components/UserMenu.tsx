"use client";

import Link from "next/link";
import { useEffect, useRef } from "react";
import { logout } from "@/app/actions/auth";

type Item = { href: string; label: string };

/** Avatar button with a dropdown. A native <details>, closed on outside click or Escape. */
export function UserMenu({
  name,
  email,
  roleLabel,
  items,
}: {
  name: string;
  email: string;
  roleLabel: string;
  items: Item[];
}) {
  const ref = useRef<HTMLDetailsElement>(null);

  useEffect(() => {
    const close = (e: Event) => {
      const el = ref.current;
      if (!el?.open) return;
      if (e instanceof KeyboardEvent && e.key !== "Escape") return;
      if (e instanceof MouseEvent && el.contains(e.target as Node)) return;
      el.open = false;
    };
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", close);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", close);
    };
  }, []);

  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join("");

  return (
    <details ref={ref} className="relative">
      <summary
        className="flex h-11 w-11 cursor-pointer list-none items-center justify-center rounded-full bg-gold text-[0.95rem] font-bold text-night [&::-webkit-details-marker]:hidden"
        aria-label={`Account menu for ${name}`}
      >
        {initials || "?"}
      </summary>
      <div className="absolute right-0 top-14 z-40 w-72 rounded-2xl border border-line bg-paper p-2 text-ink shadow-[0_20px_50px_-20px_rgba(13,27,53,0.45)]">
        <div className="px-4 py-3">
          <p className="display-soft truncate text-lg">{name}</p>
          <p className="truncate text-sm text-mute">{email}</p>
          <p className="mt-2 inline-block rounded-full bg-night/8 px-2.5 py-0.5 text-xs font-semibold">
            {roleLabel}
          </p>
        </div>
        <div className="border-t border-line pt-1">
          {items.map((i) => (
            <Link
              key={i.href}
              href={i.href}
              onClick={() => ref.current && (ref.current.open = false)}
              className="block rounded-xl px-4 py-2.5 font-medium hover:bg-chalk"
            >
              {i.label}
            </Link>
          ))}
          <form action={logout}>
            <button
              type="submit"
              className="block w-full rounded-xl px-4 py-2.5 text-left font-medium text-red-deep hover:bg-red/8"
            >
              Sign out
            </button>
          </form>
        </div>
      </div>
    </details>
  );
}
