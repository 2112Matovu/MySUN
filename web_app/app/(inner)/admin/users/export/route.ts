import { getAccessToken } from "@/lib/session";
import { API_BASE } from "@/lib/api";

/** Streams the administrator CSV of all users. The API records the export in the audit log. */
export async function GET() {
  const token = await getAccessToken();
  if (!token) return new Response("Sign in first.", { status: 401 });
  const res = await fetch(`${API_BASE}/admin/users/export.csv`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
  });
  if (!res.ok) return new Response("You can't export users.", { status: res.status });
  return new Response(res.body, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="mysun-users.csv"',
      "Cache-Control": "no-store",
    },
  });
}
