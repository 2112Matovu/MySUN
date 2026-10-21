import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getAccommodationItem } from "@/lib/api";
import { telHref, ugx } from "@/lib/format";
import { ArrowLeft, PhoneIcon } from "@/components/ui";
import { CopyLinkButton } from "@/components/interactive";
import { Gallery } from "@/components/Gallery";

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const h = await getAccommodationItem((await params).id);
  return h ? { title: h.name, description: `${h.location}. ${ugx(h.price)}.` } : { title: "Housing" };
}

const SHARING = { shared: "Shared rooms", private: "Private rooms", both: "Shared and private rooms" } as const;

export default async function AccommodationDetail({ params }: Props) {
  const { id } = await params;
  const h = await getAccommodationItem(id);
  if (!h) notFound();
  const unit = h.type === "hostel" ? "semester" : "month";

  return (
    <div className="mx-auto max-w-[76rem] px-5 pb-28 pt-10 sm:px-8 sm:pt-14">
      <Link href="/accommodation" className="inline-flex items-center gap-2 font-semibold text-mute hover:text-ink">
        <ArrowLeft className="h-5 w-5" /> All housing
      </Link>

      <div className="mt-10 grid gap-12 lg:grid-cols-[1.25fr_1fr]">
        <Gallery images={h.image_urls ?? []} name={h.name} />

        <div>
          <span className="block h-1.5 w-14 rounded-full bg-teal" aria-hidden />
          <p className="mt-6 flex flex-wrap gap-2 text-sm font-semibold">
            <span className="rounded-full bg-night px-3.5 py-1 text-white">{h.type === "hostel" ? "Hostel" : "Rental"}</span>
            {h.is_gazetted ? (
              <span className="rounded-full bg-teal px-3.5 py-1 text-white">Gazetted</span>
            ) : (
              <span className="rounded-full bg-line px-3.5 py-1">Non-gazetted</span>
            )}
            {h.is_available === false && <span className="rounded-full bg-red/10 px-3.5 py-1 text-red-deep">Currently full</span>}
          </p>
          <h1 className="display mt-5 text-[clamp(2.4rem,5.5vw,4.2rem)]">{h.name}</h1>
          <p className="mt-3 text-lg text-mute">{h.location}</p>

          <p className="tnum mt-8">
            <span className="display text-6xl">{ugx(h.price)}</span>
            <span className="ml-2 text-lg text-mute">per {unit}</span>
          </p>

          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href={telHref(h.contact_phone)}
              className="inline-flex min-h-12 items-center gap-2 rounded-full bg-night px-7 py-3 text-[1rem] font-semibold text-white transition hover:bg-teal"
            >
              <PhoneIcon /> Call {h.contact_phone}
            </a>
            <CopyLinkButton />
          </div>

          {h.description && <p className="prose-tight mt-10 text-[1.1rem] leading-[1.75]">{h.description}</p>}

          <dl className="mt-10 grid grid-cols-2 gap-x-6 gap-y-5 border-t border-line pt-8 text-[0.95rem]">
            <div>
              <dt className="text-mute">Room sharing</dt>
              <dd className="font-semibold">{SHARING[h.room_sharing as keyof typeof SHARING] ?? h.room_sharing}</dd>
            </div>
            <div>
              <dt className="text-mute">Billed</dt>
              <dd className="font-semibold">Per {unit}</dd>
            </div>
            {h.publisher_name && (
              <div className="col-span-2">
                <dt className="text-mute">Listed by</dt>
                <dd className="font-semibold">{h.publisher_name}</dd>
              </div>
            )}
          </dl>
        </div>
      </div>
    </div>
  );
}
