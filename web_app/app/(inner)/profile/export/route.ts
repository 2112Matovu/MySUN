import { api } from "@/lib/server-api";

/** Streams everything MySun holds about the signed-in user as a JSON download. */
export async function GET() {
  const r = await api<unknown>("/auth/me/export");
  if (!r.ok) return new Response(r.message, { status: r.status || 502 });
  return new Response(JSON.stringify(r.data, null, 2), {
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Content-Disposition": 'attachment; filename="mysun-my-data.json"',
      "Cache-Control": "no-store",
    },
  });
}
