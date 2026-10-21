import "server-only";
import { cookies } from "next/headers";

export const AT = "mysun_at";
export const RT = "mysun_rt";

const opts = {
  httpOnly: true,
  sameSite: "lax" as const,
  secure: process.env.NODE_ENV === "production",
  path: "/",
  maxAge: 60 * 60 * 24 * 30,
};

export async function getAccessToken() {
  return (await cookies()).get(AT)?.value ?? null;
}

/** Only callable from a Server Action or Route Handler. */
export async function setSession(access: string, refresh?: string | null) {
  const jar = await cookies();
  jar.set(AT, access, opts);
  if (refresh) jar.set(RT, refresh, opts);
}

export async function clearSession() {
  const jar = await cookies();
  jar.delete(AT);
  jar.delete(RT);
}
