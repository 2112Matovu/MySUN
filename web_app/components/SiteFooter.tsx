import Link from "next/link";
import { SunMark } from "./SunMark";
import { SECTIONS, SECTION_ORDER } from "@/lib/sections";

export function SiteFooter() {
  return (
    <footer data-dark className="bg-night text-white/80">
      <div className="mx-auto grid max-w-[76rem] gap-12 px-5 py-16 sm:px-8 md:grid-cols-[1.4fr_1fr_1fr]">
        <div>
          <div className="flex items-center gap-3 text-white">
            <SunMark size={44} lightRays />
            <span className="display-soft text-3xl font-bold">MySun</span>
          </div>
          <p className="mt-5 max-w-sm text-[0.98rem] leading-relaxed text-white/70">
            The campus companion for Soroti University. Notices, events, housing and
            transport, posted by the people who run them.
          </p>
        </div>

        <nav aria-label="Sections">
          <p className="text-sm font-semibold text-white">Browse</p>
          <ul className="mt-4 space-y-2.5">
            {SECTION_ORDER.map((key) => (
              <li key={key}>
                <Link
                  href={SECTIONS[key].href}
                  className="inline-flex items-center gap-2.5 transition hover:text-white"
                >
                  <span className={`h-2 w-2 rounded-full ${key === "services" ? "bg-white" : SECTIONS[key].bar}`} />
                  {SECTIONS[key].label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        <div>
          <p className="text-sm font-semibold text-white">On your phone</p>
          <p className="mt-4 text-[0.98rem] leading-relaxed text-white/70">
            The Android app adds push alerts, saved items, room bookings and offline
            reading.
          </p>
          <Link
            href="/#get-app"
            className="mt-5 inline-block rounded-full bg-gold px-5 py-2.5 text-[0.95rem] font-semibold text-night transition hover:bg-white"
          >
            Get the app
          </Link>
        </div>
      </div>
      <div className="border-t border-white/10">
        <p className="mx-auto max-w-[76rem] px-5 py-6 text-sm text-white/55 sm:px-8">
          © {new Date().getFullYear()} MySun. Times on this site are shown in Soroti
          local time (EAT).
        </p>
      </div>
    </footer>
  );
}
