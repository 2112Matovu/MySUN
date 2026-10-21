import type { Metadata } from "next";
import { ImageLightbox } from "@/components/ImageLightbox";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getAnnouncement } from "@/lib/api";
import { getUser } from "@/lib/auth";
import { myBookmarks } from "@/lib/me";
import { longDate, relativeDay } from "@/lib/format";
import { BookmarkButton, CopyLinkButton } from "@/components/interactive";
import { ArrowLeft } from "@/components/ui";

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const a = await getAnnouncement((await params).id);
  return a ? { title: a.title, description: a.description.slice(0, 160) } : { title: "Announcement" };
}

export default async function AnnouncementPage({ params }: Props) {
  const { id } = await params;
  const a = await getAnnouncement(id);
  if (!a) notFound();
  const user = await getUser();
  const saved = user ? (await myBookmarks()).some((b) => b.content_type === "announcement" && b.content_id === id) : false;

  return (
    <article className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/announcements" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> All announcements
      </Link>

      <div className="mt-10 grid gap-12 lg:grid-cols-[1fr_17rem]">
        <div>
          <span className="block h-1.5 w-14 rounded-full bg-gold" aria-hidden />
          {a.is_important && (
            <p className="mt-6 inline-block rounded-full bg-gold px-3.5 py-1 text-sm font-semibold text-night">Important</p>
          )}
          <h1 className="display mt-5 text-[clamp(2.6rem,6.5vw,5rem)]">{a.title}</h1>
          <p className="mt-6 text-mute">
            {a.category} · {a.publisher_name} · {longDate(a.published_at)} ({relativeDay(a.published_at)})
          </p>
          {a.image_url && (
            <ImageLightbox src={a.image_url} alt={a.title} className="mt-9">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={a.image_url} alt="" className="max-h-[28rem] w-full rounded-3xl object-cover" />
            </ImageLightbox>
          )}
          <div className="prose-tight mt-9 whitespace-pre-line text-[1.15rem] leading-[1.75]">{a.description}</div>
          {a.expires_at && <p className="mt-8 text-mute">Open until {longDate(a.expires_at)}.</p>}
        </div>

        <aside className="h-fit space-y-3 lg:sticky lg:top-8">
          <BookmarkButton type="announcement" id={a.id} saved={saved} signedIn={Boolean(user)} />
          <div>
            <CopyLinkButton />
          </div>
          <dl className="mt-6 space-y-4 border-t border-line pt-6 text-[0.95rem]">
            <div>
              <dt className="text-mute">Posted by</dt>
              <dd className="font-semibold">{a.publisher_name}</dd>
            </div>
            <div>
              <dt className="text-mute">Category</dt>
              <dd className="font-semibold">{a.category}</dd>
            </div>
          </dl>
        </aside>
      </div>
    </article>
  );
}
