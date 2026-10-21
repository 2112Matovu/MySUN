"use server";

import { redirect } from "next/navigation";
import { api } from "@/lib/server-api";
import { clearSession, setSession } from "@/lib/session";
import { safeNext, type User } from "@/lib/auth";
import { homeFor } from "@/lib/roles";

export type FormState = { error?: string; notice?: string; email?: string } | undefined;

type AuthResponse = {
  access_token: string;
  refresh_token?: string | null;
  user: User;
  mfa_required?: boolean;
  mfa_factor_id?: string | null;
};

const str = (f: FormData, k: string) => String(f.get(k) ?? "").trim();
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function login(_: FormState, form: FormData): Promise<FormState> {
  const email = str(form, "email");
  const password = String(form.get("password") ?? "");
  const next = safeNext(form.get("next"));
  if (!EMAIL.test(email)) return { error: "Enter a valid email address.", email };
  if (!password) return { error: "Enter your password.", email };

  const r = await api<AuthResponse>("/auth/login", { method: "POST", body: { email, password }, auth: false });
  if (!r.ok) return { error: r.message, email };

  await setSession(r.data.access_token, r.data.refresh_token);
  if (r.data.mfa_required && r.data.mfa_factor_id) {
    redirect(`/login/verify?factor=${encodeURIComponent(r.data.mfa_factor_id)}&next=${encodeURIComponent(next)}`);
  }
  redirect(next === "/" ? homeFor(r.data.user.role) : next);
}

export async function verifyMfa(_: FormState, form: FormData): Promise<FormState> {
  const code = str(form, "code").replace(/\s/g, "");
  const factor = str(form, "factor");
  const next = safeNext(form.get("next"));
  if (!/^\d{6}$/.test(code)) return { error: "Enter the 6-digit code from your authenticator app." };
  const r = await api<AuthResponse>("/auth/mfa/verify", { method: "POST", body: { factor_id: factor, code } });
  if (!r.ok) return { error: r.message };
  await setSession(r.data.access_token, r.data.refresh_token);
  redirect(next === "/" ? homeFor(r.data.user.role) : next);
}

export async function signup(_: FormState, form: FormData): Promise<FormState> {
  const name = str(form, "name");
  const email = str(form, "email");
  const password = String(form.get("password") ?? "");
  if (!name) return { error: "Enter your full name.", email };
  if (!EMAIL.test(email)) return { error: "Enter a valid email address.", email };
  if (password.length < 8) return { error: "Use at least 8 characters for your password.", email };

  const r = await api<AuthResponse>("/auth/signup", { method: "POST", body: { name, email, password }, auth: false });
  if (!r.ok) {
    // The server asks new accounts to confirm their email before the first sign-in.
    if (r.status === 400 && /confirm/i.test(r.message)) return { notice: r.message, email };
    return { error: r.message, email };
  }
  await setSession(r.data.access_token, r.data.refresh_token);
  redirect(safeNext(form.get("next")));
}

export async function requestPasswordReset(_: FormState, form: FormData): Promise<FormState> {
  const email = str(form, "email");
  if (!EMAIL.test(email)) return { error: "Enter a valid email address.", email };
  const r = await api("/auth/password-reset", { method: "POST", body: { email }, auth: false });
  if (!r.ok) return { error: r.message, email };
  return { notice: `If an account exists for ${email}, a reset link is on its way.`, email };
}

export async function logout() {
  await clearSession();
  redirect("/");
}

/** Exchanges the Google ID token for a session. The name comes from the Google account. */
export async function googleLogin(idToken: string, rawNext: string): Promise<{ error: string }> {
  const next = safeNext(rawNext);
  const r = await api<AuthResponse>("/auth/google", { method: "POST", body: { id_token: idToken }, auth: false });
  if (!r.ok) return { error: r.message };
  await setSession(r.data.access_token, r.data.refresh_token);
  if (r.data.mfa_required && r.data.mfa_factor_id) {
    redirect(`/login/verify?factor=${encodeURIComponent(r.data.mfa_factor_id)}&next=${encodeURIComponent(next)}`);
  }
  redirect(next === "/" ? homeFor(r.data.user.role) : next);
}
