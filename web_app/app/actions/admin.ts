"use server";

import { revalidatePath } from "next/cache";
import { api } from "@/lib/server-api";
import type { Role } from "@/lib/auth";

export type AdminResult = { ok: true; message: string } | { ok: false; message: string };

export async function removeContent(submissionId: string, reason: string): Promise<AdminResult> {
  const clean = reason.trim();
  if (clean.length < 3) return { ok: false, message: "Give the publisher a reason for the removal." };
  const r = await api(`/admin/moderation/${submissionId}/remove`, { method: "POST", body: { reason: clean } });
  if (!r.ok) return { ok: false, message: r.message };
  for (const p of ["/admin", "/admin/moderation", "/announcements", "/events", "/accommodation", "/transport", "/"]) revalidatePath(p);
  return { ok: true, message: "Removed. The publisher has been told why." };
}

export async function setRole(userId: string, role: Role): Promise<AdminResult> {
  const r = await api(`/admin/users/${userId}/role`, { method: "PATCH", body: { new_role: role } });
  if (!r.ok) return { ok: false, message: r.message };
  revalidatePath("/admin/users");
  revalidatePath("/admin/minor-admins");
  revalidatePath("/admin/grant-access");
  return { ok: true, message: "Role updated." };
}

export async function setVerified(providerId: string, verified: boolean): Promise<AdminResult> {
  const r = await api(`/admin/transport/${providerId}/verified`, { method: "PATCH", body: { is_verified: verified } });
  if (!r.ok) return { ok: false, message: r.message };
  for (const p of ["/admin/moderation", "/transport", "/"]) revalidatePath(p);
  return { ok: true, message: verified ? "Marked as verified." : "Verification removed." };
}
