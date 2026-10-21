import Link from "next/link";
import { SunMark } from "./SunMark";
import { BookDialog, RateDialog } from "./interactive";
import { Check, PhoneIcon, Stars } from "./ui";
import type { Accommodation, TransportProvider } from "@/lib/api";
import { telHref, ugx } from "@/lib/format";

export function HousingCard({ h, large = false }: { h: Accommodation; large?: boolean }) {
  const img = h.image_urls?.[0];
  return (
    <article className="group relative flex flex-col overflow-hidden rounded-[1.75rem] bg-chalk ring-1 ring-line">
      <div className={`relative overflow-hidden bg-night-2 ${large ? "aspect-[16/10]" : "aspect-[16/8]"}`}>
        {img ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={img}
            alt={h.name}
            loading="lazy"
            className="h-full w-full object-cover transition duration-700 group-hover:scale-[1.04]"
          />
        ) : (
          <div className="flex h-full items-center justify-center">
            <SunMark size={72} lightRays />
          </div>
        )}
        <span className="absolute left-4 top-4 rounded-full bg-white px-3.5 py-1.5 text-sm font-semibold text-night">
          {h.type === "hostel" ? "Hostel" : "Rental"}
        </span>
        {h.is_gazetted && (
          <span className="absolute right-4 top-4 inline-flex items-center gap-1.5 rounded-full bg-teal px-3.5 py-1.5 text-sm font-semibold text-white">
            Gazetted
          </span>
        )}
      </div>
      <div className="flex flex-1 flex-col p-6">
        <h3 className="display-soft text-[1.6rem]">
          <Link href={`/accommodation/${h.id}`} className="after:absolute after:inset-0 hover:text-teal-deep">{h.name}</Link>
        </h3>
        <p className="mt-1 text-mute">{h.location}</p>
        {large && h.description && (
          <p className="prose-tight mt-3 text-[0.98rem] text-mute">{h.description}</p>
        )}
        <div className="mt-auto flex flex-wrap items-end justify-between gap-3 pt-5">
          <p className="tnum">
            <span className="display-soft text-3xl">{ugx(h.price)}</span>
            <span className="text-mute"> / {h.type === "hostel" ? "semester" : "month"}</span>
          </p>
          <a
            href={telHref(h.contact_phone)}
            className="relative z-10 inline-flex items-center gap-2 rounded-full bg-night px-5 py-2.5 text-[0.95rem] font-semibold text-white transition hover:bg-teal"
          >
            <PhoneIcon /> Call
          </a>
        </div>
      </div>
    </article>
  );
}

export function BodaRow({ t, signedIn = false }: { t: TransportProvider; signedIn?: boolean }) {
  return (
    <li className="grid gap-4 border-b border-line py-7 lg:grid-cols-[1.3fr_1fr_auto] lg:items-center lg:gap-10">
      <div>
        <h3 className="display-soft flex flex-wrap items-center gap-x-3 text-[1.55rem]">
          {t.name}
          {t.is_verified && (
            <span className="inline-flex items-center gap-1.5 font-sans text-sm font-semibold text-blue">
              <Check className="text-blue" /> Verified
            </span>
          )}
        </h3>
        {t.contact_person && <p className="mt-1 text-mute">{t.contact_person}</p>}
        <p className="mt-2 flex items-center gap-3 text-[0.95rem]">
          {t.rating !== null && t.rating_count > 0 ? (
            <>
              <Stars rating={t.rating} />
              <span className="tnum text-mute">
                {t.rating.toFixed(1)} from {t.rating_count} ratings
              </span>
            </>
          ) : (
            <span className="text-mute">Not rated yet</span>
          )}
        </p>
      </div>
      <div>
        {t.operating_hours && <p className="font-medium">{t.operating_hours}</p>}
        {t.service_areas.length > 0 && (
          <p className="mt-1 text-mute">{t.service_areas.join(", ")}</p>
        )}
      </div>
      <div className="flex flex-wrap items-center gap-2.5">
        <a
          href={telHref(t.phone_number)}
          className="inline-flex min-h-11 items-center gap-2 rounded-full border border-line bg-paper px-5 py-2.5 text-[0.95rem] font-semibold transition hover:border-night/40"
        >
          <PhoneIcon /> Call
        </a>
        <RateDialog id={t.id} name={t.name} signedIn={signedIn} />
        <BookDialog id={t.id} name={t.name} signedIn={signedIn} />
      </div>
    </li>
  );
}
