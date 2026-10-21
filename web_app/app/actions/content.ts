"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { api } from "@/lib/server-api";
import { clearSession } from "@/lib/session";
import { getUser } from "@/lib/auth";

export type ActionResult = { ok: true; message?: string } | { ok: false; message: string };

const fail = (message: string): ActionResult => ({ ok: false, message });

async function needUser() {
  return getUser();
}

export async function toggleBookmark(
  type: "announcement" | "event",
  id: string,
  path: string,
): Promise<ActionResult & { bookmarked?: boolean }> {
  if (!(await needUser())) return fail("Sign in to save items.");
  const r = await api<{ bookmarked: boolean }>("/bookmarks/toggle", {
    method: "POST",
    body: { content_type: type, content_id: id },
  });
  if (!r.ok) return fail(r.message);
  revalidatePath("/bookmarks");
  revalidatePath(path);
  return { ok: true, bookmarked: r.data.bookmarked };
}

export async function setEventRegistration(
  id: string,
  register: boolean,
): Promise<ActionResult & { registered?: boolean; count?: number }> {
  if (!(await needUser())) return fail("Sign in to register for events.");
  const r = await api<{ registered: boolean; registered_count: number }>(`/events/${id}/register`, {
    method: register ? "POST" : "DELETE",
  });
  if (!r.ok) return fail(r.message);
  revalidatePath(`/events/${id}`);
  revalidatePath("/events");
  return { ok: true, registered: r.data.registered, count: r.data.registered_count };
}

export async function rateProvider(
  id: string,
  stars: number,
  comment: string,
): Promise<ActionResult> {
  if (!(await needUser())) return fail("Sign in to rate a rider.");
  const r = await api(`/transport/${id}/rate`, {
    method: "POST",
    body: { stars, comment: comment.trim() || null },
  });
  if (!r.ok) return fail(r.message);
  revalidatePath("/transport");
  return { ok: true, message: "Thanks, your rating was saved." };
}

export async function createBooking(_: unknown, form: FormData): Promise<ActionResult> {
  if (!(await needUser())) return fail("Sign in to book a rider.");
  const provider_id = String(form.get("provider_id") ?? "");
  const pickup = String(form.get("pickup") ?? "").trim();
  const destination = String(form.get("destination") ?? "").trim();
  const when = String(form.get("when") ?? "");
  const note = String(form.get("note") ?? "").trim();
  if (!pickup || !destination) return fail("Enter a pick-up point and a destination.");
  let requested_time: string | null = null;
  if (when === "later") {
    const t = String(form.get("time") ?? "");
    const d = t ? new Date(`${t}+03:00`) : null;
    if (!d || Number.isNaN(+d) || +d < Date.now()) return fail("Pick a time in the future.");
    requested_time = d.toISOString();
  }
  const r = await api("/bookings", {
    method: "POST",
    body: { provider_id, pickup, destination, requested_time, note: note || null },
  });
  if (!r.ok) return fail(r.message);
  revalidatePath("/bookings");
  return { ok: true, message: "Request sent. The rider will accept or decline it." };
}

export async function cancelBooking(id: string): Promise<ActionResult> {
  const r = await api(`/bookings/${id}/cancel`, { method: "POST" });
  if (!r.ok) return fail(r.message);
  revalidatePath("/bookings");
  return { ok: true };
}

export async function respondToBooking(
  id: string,
  action: "accept" | "decline" | "complete",
): Promise<ActionResult> {
  const r = await api(`/bookings/${id}/respond`, { method: "POST", body: { action } });
  if (!r.ok) return fail(r.message);
  revalidatePath("/bookings");
  return { ok: true };
}

export async function markNotificationRead(id: string): Promise<ActionResult> {
  const r = await api(`/notifications/${id}/read`, { method: "POST" });
  if (!r.ok) return fail(r.message);
  revalidatePath("/notifications");
  return { ok: true };
}

export async function markAllNotificationsRead(ids: string[]): Promise<ActionResult> {
  await Promise.all(ids.map((id) => api(`/notifications/${id}/read`, { method: "POST" })));
  revalidatePath("/notifications");
  return { ok: true };
}

export async function saveNotificationPrefs(prefs: {
  announcements: boolean;
  events: boolean;
  reminders: boolean;
  transport: boolean;
}): Promise<ActionResult> {
  const r = await api("/notifications/preferences", { method: "PUT", body: prefs });
  if (!r.ok) return fail(r.message);
  revalidatePath("/profile");
  return { ok: true };
}

export async function deleteAccount(): Promise<ActionResult> {
  const r = await api("/auth/me", { method: "DELETE" });
  if (!r.ok) return fail(r.message);
  await clearSession();
  redirect("/");
}
