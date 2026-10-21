"use server";

import QRCode from "qrcode";
import { revalidatePath } from "next/cache";
import { api } from "@/lib/server-api";
import { setSession } from "@/lib/session";
import type { User } from "@/lib/auth";

type Enrollment = { factor_id: string; secret?: string | null; uri?: string | null };

export type MfaStart =
  | { ok: true; factor: string; secret: string; qr: string }
  | { ok: false; message: string };

export async function startMfaSetup(): Promise<MfaStart> {
  const r = await api<Enrollment>("/auth/mfa/enroll", { method: "POST" });
  if (!r.ok) return { ok: false, message: r.message };
  const uri = r.data.uri ?? "";
  const qr = uri ? await QRCode.toString(uri, { type: "svg", margin: 1, width: 192 }) : "";
  return { ok: true, factor: r.data.factor_id, secret: r.data.secret ?? "", qr };
}

export async function finishMfaSetup(
  factor: string,
  code: string,
): Promise<{ ok: boolean; message?: string }> {
  const clean = code.replace(/\s/g, "");
  if (!/^\d{6}$/.test(clean)) return { ok: false, message: "Enter the 6-digit code from your app." };
  const r = await api<{ access_token: string; refresh_token?: string | null; user: User }>(
    "/auth/mfa/verify",
    { method: "POST", body: { factor_id: factor, code: clean } },
  );
  if (!r.ok) return { ok: false, message: r.message };
  await setSession(r.data.access_token, r.data.refresh_token);
  revalidatePath("/profile");
  return { ok: true };
}
