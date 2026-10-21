import { NextResponse, type NextRequest } from "next/server";

// Runs before every page request. It keeps the sign-in alive by swapping an expired
// access token for a fresh one (the refresh token never reaches client JavaScript),
// and sends signed-out visitors away from pages that need an account.

const API =
  process.env.API_BASE ??
  process.env.NEXT_PUBLIC_API_BASE ??
  "https://2401600066.ncedges.com/api/v1";

const AT = "mysun_at";
const RT = "mysun_rt";
const PROTECTED = ["/bookmarks", "/notifications", "/profile", "/bookings", "/publish", "/admin"];

function secondsLeft(token: string): number {
  try {
    const payload = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const { exp } = JSON.parse(atob(payload)) as { exp?: number };
    return (exp ?? 0) - Math.floor(Date.now() / 1000);
  } catch {
    return -1;
  }
}

const cookieOpts = {
  httpOnly: true,
  sameSite: "lax" as const,
  secure: process.env.NODE_ENV === "production",
  path: "/",
  maxAge: 60 * 60 * 24 * 30,
};

export async function proxy(req: NextRequest) {
  const at = req.cookies.get(AT)?.value;
  const rt = req.cookies.get(RT)?.value;
  const path = req.nextUrl.pathname;

  let fresh: { access_token: string; refresh_token?: string | null } | null = null;
  let dropped = false;

  if (rt && (!at || secondsLeft(at) < 30)) {
    try {
      const res = await fetch(`${API}/auth/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: rt }),
        cache: "no-store",
      });
      if (res.ok) fresh = await res.json();
      else if (res.status === 401 || res.status === 400) dropped = true;
    } catch {
      // API unreachable: keep whatever we have and let the page show its own error.
    }
  }

  const signedIn = Boolean(fresh) || (Boolean(at) && !dropped && secondsLeft(at!) > 0);
  const needsAccount = PROTECTED.some((p) => path === p || path.startsWith(`${p}/`));

  if (needsAccount && !signedIn) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.search = `?next=${encodeURIComponent(path)}`;
    const res = NextResponse.redirect(url);
    if (dropped) {
      res.cookies.delete(AT);
      res.cookies.delete(RT);
    }
    return res;
  }

  if (fresh) {
    req.cookies.set(AT, fresh.access_token);
    if (fresh.refresh_token) req.cookies.set(RT, fresh.refresh_token);
  } else if (dropped) {
    req.cookies.delete(AT);
    req.cookies.delete(RT);
  }

  const res = NextResponse.next({ request: { headers: req.headers } });
  if (fresh) {
    res.cookies.set(AT, fresh.access_token, cookieOpts);
    if (fresh.refresh_token) res.cookies.set(RT, fresh.refresh_token, cookieOpts);
  } else if (dropped) {
    res.cookies.delete(AT);
    res.cookies.delete(RT);
  }
  return res;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|icon.svg|favicon.ico|.*\\.(?:png|jpg|jpeg|svg|webp|ico|css|js)$).*)"],
};
