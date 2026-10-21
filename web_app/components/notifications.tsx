"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { markAllNotificationsRead, markNotificationRead } from "@/app/actions/content";

/** A whole row that marks the alert as read, then opens what it is about. */
export function NotificationLink({
  id,
  href,
  read,
  children,
}: {
  id: string;
  href: string | null;
  read: boolean;
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [, start] = useTransition();
  return (
    <button
      type="button"
      className="flex w-full items-start gap-4 py-6 text-left transition hover:bg-night/[0.03]"
      onClick={() =>
        start(async () => {
          if (!read) await markNotificationRead(id);
          if (href) router.push(href);
        })
      }
    >
      {children}
    </button>
  );
}

export function MarkAllRead({ ids }: { ids: string[] }) {
  const [pending, start] = useTransition();
  return (
    <button
      type="button"
      disabled={pending}
      onClick={() => start(async () => void (await markAllNotificationsRead(ids)))}
      className="inline-flex min-h-11 items-center rounded-full border border-line bg-paper px-5 py-2.5 font-semibold transition hover:border-night/40 disabled:opacity-60"
    >
      {pending ? "Working…" : "Mark all read"}
    </button>
  );
}
