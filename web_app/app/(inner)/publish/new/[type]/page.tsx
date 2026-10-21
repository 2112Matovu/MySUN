import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requirePublisher } from "@/lib/auth";
import { apiData } from "@/lib/server-api";
import { TYPE_LABEL, isContentType, type Submission } from "@/lib/publish";
import { PublishForm } from "@/components/publish-forms";
import { ArrowLeft } from "@/components/ui";

export const metadata: Metadata = { title: "New post" };

export default async function NewPostPage({
  params,
  searchParams,
}: {
  params: Promise<{ type: string }>;
  searchParams: Promise<{ draft?: string }>;
}) {
  const { type } = await params;
  if (!isContentType(type)) notFound();
  await requirePublisher(`/publish/new/${type}`);

  const draftId = (await searchParams).draft;
  const draft = draftId
    ? ((await apiData<Submission[]>("/publisher/drafts")) ?? []).find((d) => d.id === draftId && d.type === type) ?? null
    : null;

  return (
    <div className="mx-auto max-w-3xl px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/publish" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> Publisher dashboard
      </Link>
      <h1 className="display mt-8 text-[clamp(2.6rem,6vw,4.5rem)]">
        {draft ? "Continue draft" : `New ${TYPE_LABEL[type].toLowerCase()}`}
      </h1>
      <div className="mt-10">
        <PublishForm type={type} draft={draft} />
      </div>
    </div>
  );
}
