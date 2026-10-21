import type { Metadata } from "next";
import Link from "next/link";
import { canPublish, requireUser } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import type { Booking } from "@/lib/me";
import { clock, longDate, relativeDay, telHref } from "@/lib/format";
import { EmptyState, PhoneIcon } from "@/components/ui";
import { BookingAction } from "@/components/interactive";

export const metadata: Metadata = { title: "Boda bookings" };

const STATUS: Record<Booking["status"], { label: string; cls: string }> = {
  pending: { label: "Waiting for the rider", cls: "bg-gold/20 text-gold-deep" },
  accepted: { label: "Accepted", cls: "bg-teal/15 text-teal-deep" },
  declined: { label: "Declined", cls: "bg-red/10 text-red-deep" },
  cancelled: { label: "Cancelled", cls: "bg-line text-mute" },
  completed: { label: "Completed", cls: "bg-blue/10 text-blue" },
};

function when(b: Booking) {
  return b.requested_time ? `${longDate(b.requested_time)}, ${clock(b.requested_time)}` : "As soon as possible";
}

export default async function BookingsPage() {
  const user = await requireUser("/bookings");
  const mine = (await apiData<Booking[]>("/bookings/mine")) ?? [];
  const incoming = canPublish(user.role) ? ((await apiData<Booking[]>("/bookings/incoming")) ?? []) : [];

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-14 sm:px-8 sm:pt-20">
      <span className="block h-1.5 w-14 rounded-full bg-blue" aria-hidden />
      <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">Boda bookings</h1>

      {incoming.length > 0 && (
        <section className="mt-14">
          <h2 className="display-soft text-3xl">Requests for your riders</h2>
          <ul className="mt-6 border-t border-line">
            {incoming.map((b) => (
              <li key={b.id} className="grid gap-4 border-b border-line py-7 md:grid-cols-[1fr_auto] md:items-center">
                <div>
                  <p className="flex flex-wrap items-center gap-3">
                    <span className="display-soft text-2xl">{b.pickup} to {b.destination}</span>
                    <span className={`rounded-full px-3 py-0.5 text-sm font-semibold ${STATUS[b.status].cls}`}>{STATUS[b.status].label}</span>
                  </p>
                  <p className="mt-1 text-mute">{b.student_name ?? "Student"} · for {b.provider_name} · {when(b)}</p>
                  {b.note && <p className="mt-2 italic">“{b.note}”</p>}
                </div>
                <div className="flex flex-wrap items-center gap-2.5">
                  {b.status === "pending" && (
                    <>
                      <BookingAction label="Accept" run={{ kind: "respond", id: b.id, action: "accept" }} tone="dark" />
                      <BookingAction label="Decline" run={{ kind: "respond", id: b.id, action: "decline" }} tone="danger" />
                    </>
                  )}
                  {b.status === "accepted" && (
                    <BookingAction label="Mark completed" run={{ kind: "respond", id: b.id, action: "complete" }} tone="dark" />
                  )}
                </div>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section className="mt-14">
        <h2 className="display-soft text-3xl">My rides</h2>
        {mine.length === 0 ? (
          <div className="mt-6">
            <EmptyState section="transport" title="No bookings yet" body="Choose a rider on the Boda stages page and press Book." />
            <p className="mt-6 text-center">
              <Link href="/transport" className="font-semibold text-blue hover:underline">Find a boda rider</Link>
            </p>
          </div>
        ) : (
          <ul className="mt-6 border-t border-line">
            {mine.map((b) => (
              <li key={b.id} className="grid gap-4 border-b border-line py-7 md:grid-cols-[1fr_auto] md:items-center">
                <div>
                  <p className="flex flex-wrap items-center gap-3">
                    <span className="display-soft text-2xl">{b.pickup} to {b.destination}</span>
                    <span className={`rounded-full px-3 py-0.5 text-sm font-semibold ${STATUS[b.status].cls}`}>{STATUS[b.status].label}</span>
                  </p>
                  <p className="mt-1 text-mute">For {b.provider_name} · {when(b)} · requested {relativeDay(b.created_at)}</p>
                  {b.note && <p className="mt-2 italic">“{b.note}”</p>}
                </div>
                <div className="flex flex-wrap items-center gap-2.5">
                  {b.status === "accepted" && b.provider_phone && (
                    <a href={telHref(b.provider_phone)} className="inline-flex min-h-11 items-center gap-2 rounded-full bg-night px-5 py-2.5 text-[0.95rem] font-semibold text-white hover:bg-blue">
                      <PhoneIcon /> Call rider
                    </a>
                  )}
                  {(b.status === "pending" || b.status === "accepted") && (
                    <BookingAction label="Cancel" run={{ kind: "cancel", id: b.id }} tone="danger" />
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
