import { api } from "@/lib/server-api";

const MAX_BYTES = 6 * 1024 * 1024;

/** Passes an image from the browser on to the MySun API, using the signed-in user's token. */
export async function POST(req: Request) {
  const incoming = await req.formData();
  const file = incoming.get("file");
  if (!(file instanceof File)) return Response.json({ message: "Choose an image to upload." }, { status: 400 });
  if (!file.type.startsWith("image/")) return Response.json({ message: "Only images can be uploaded." }, { status: 400 });
  if (file.size > MAX_BYTES) return Response.json({ message: "Images must be under 6 MB." }, { status: 413 });

  const form = new FormData();
  form.append("file", file, file.name);
  const r = await api<{ url: string }>("/uploads", { method: "POST", form });
  if (!r.ok) return Response.json({ message: r.message }, { status: r.status || 502 });
  return Response.json({ url: r.data.url });
}
