"use server";

import { revalidatePath } from "next/cache";
import { api } from "@/lib/server-api";
import type { ContentType } from "@/lib/publish";

export type PublishResult = { ok: true; message: string } | { ok: false; message: string };

const ENDPOINT: Record<ContentType, string> = {
  announcement: "/announcements",
  event: "/events",
  accommodation: "/accommodation",
  transport: "/transport",
};

function refresh() {
  for (const p of ["/publish", "/announcements", "/events", "/accommodation", "/transport", "/"]) {
    revalidatePath(p);
  }
}

export async function saveDraft(
  type: ContentType,
  title: string,
  formData: Record<string, unknown>,
  draftId?: string | null,
): Promise<PublishResult & { id?: string }> {
  const r = await api<{ id: string }>("/publisher/drafts", {
    method: "POST",
    body: { id: draftId ?? null, type, title: title.trim() || "Untitled draft", form_data: formData },
  });
  if (!r.ok) return { ok: false, message: r.message };
  revalidatePath("/publish");
  revalidatePath("/publish/drafts");
  return { ok: true, message: "Draft saved.", id: r.data.id };
}

export async function discardDraft(id: string): Promise<PublishResult> {
  const r = await api(`/publisher/drafts/${id}`, { method: "DELETE" });
  if (!r.ok) return { ok: false, message: r.message };
  revalidatePath("/publish/drafts");
  revalidatePath("/publish");
  return { ok: true, message: "Draft discarded." };
}

/** Publishes now, or schedules when `payload.publish_at` is set. */
export async function publishContent(
  type: ContentType,
  payload: Record<string, unknown>,
  draftId?: string | null,
): Promise<PublishResult> {
  const r = await api(ENDPOINT[type], { method: "POST", body: { ...payload, draft_id: draftId ?? null } });
  if (!r.ok) return { ok: false, message: r.message };
  refresh();
  return {
    ok: true,
    message: payload.publish_at ? "Scheduled. It will go live at the time you chose." : "Published. It is live now.",
  };
}

export async function removeOwnSubmission(id: string): Promise<PublishResult> {
  const r = await api(`/publisher/submissions/${id}/remove`, { method: "POST" });
  if (!r.ok) return { ok: false, message: r.message };
  refresh();
  return { ok: true, message: "Removed." };
}

/** `publishAt` null publishes straight away. Only announcements and events can be scheduled. */
export async function rescheduleContent(
  type: "announcement" | "event",
  contentId: string,
  publishAt: string | null,
): Promise<PublishResult> {
  const r = await api(`${ENDPOINT[type]}/${contentId}/schedule`, {
    method: "PATCH",
    body: { publish_at: publishAt },
  });
  if (!r.ok) return { ok: false, message: r.message };
  refresh();
  return { ok: true, message: publishAt ? "Time changed." : "Published." };
}
