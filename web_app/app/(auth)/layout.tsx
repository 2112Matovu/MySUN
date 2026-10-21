import Link from "next/link";
import { SunMark } from "@/components/SunMark";

/** Sign-in pages: a dusk-sky panel beside the form on wide screens. */
export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid min-h-dvh lg:grid-cols-[1.05fr_1fr]">
      <aside
        data-dark
        className="relative hidden flex-col justify-between overflow-hidden p-12 text-white lg:flex"
        style={{
          background:
            "linear-gradient(180deg, #2e2662 0%, #a2436f 46%, #ee8a52 82%, #f8c26a 100%)",
        }}
      >
        <Link href="/" className="flex items-center gap-3" aria-label="MySun home">
          <SunMark size={44} lightRays />
          <span className="display-soft text-3xl font-bold">MySun</span>
        </Link>
        <div>
          <p className="display max-w-[11ch] text-[clamp(3.5rem,6vw,6rem)]">Welcome back to campus.</p>
          <p className="mt-6 max-w-sm text-lg text-white/85">
            Save events, book a boda, and hear about what matters the moment it is posted.
          </p>
        </div>
        <svg viewBox="0 0 1440 170" preserveAspectRatio="xMidYMax slice" className="absolute inset-x-0 bottom-0 h-40 w-full" aria-hidden>
          <path fill="#0d1b35" d="M0 170V122c110-6 210 4 330-2 120-7 210 6 350 1 130-5 210 3 320-3 52-3 66-48 112-68 44-19 100-21 136-4 40 19 52 60 80 70 38 12 72 9 112 11v43Z" />
        </svg>
      </aside>

      <main className="flex flex-col px-5 py-8 sm:px-10">
        <Link href="/" className="mb-10 flex items-center gap-2.5 lg:hidden" aria-label="MySun home">
          <SunMark size={36} />
          <span className="display-soft text-2xl font-bold">MySun</span>
        </Link>
        <div className="m-auto w-full max-w-md py-8">{children}</div>
      </main>
    </div>
  );
}
