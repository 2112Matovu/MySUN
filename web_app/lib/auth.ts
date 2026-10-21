import "server-only";
import { cache } from "react";
import { redirect } from "next/navigation";
import { api } from "./server-api";
import { getAccessToken } from "./session";
import { canPublish, isAdminLevel, type Role } from "./roles";

export { ROLE_LABEL, canPublish, isAdminLevel, type Role } from "./roles";

export type User = {
  id: string;
  name: string;
  email: string;
  role: Role;
  student_id: string | null;
  faculty: string | null;
  program: string | null;
  image_url: string | null;
};


/** The signed-in user, or null. Memoised for the length of one request. */
export const getUser = cache(async (): Promise<User | null> => {
  if (!(await getAccessToken())) return null;
  const r = await api<User>("/auth/me");
  return r.ok ? r.data : null;
});

export async function requireUser(next = "/"): Promise<User> {
  const user = await getUser();
  if (!user) redirect(`/login?next=${encodeURIComponent(next)}`);
  return user;
}

export async function requirePublisher(next = "/publish"): Promise<User> {
  const user = await requireUser(next);
  if (!canPublish(user.role)) redirect("/");
  return user;
}

export async function requireAdmin(next = "/admin", superOnly = false): Promise<User> {
  const user = await requireUser(next);
  if (!isAdminLevel(user.role)) redirect("/");
  if (superOnly && user.role !== "admin") redirect("/admin");
  return user;
}

/** Only allow same-site relative redirects after sign-in. */
export function safeNext(next: unknown): string {
  return typeof next === "string" && next.startsWith("/") && !next.startsWith("//") ? next : "/";
}
