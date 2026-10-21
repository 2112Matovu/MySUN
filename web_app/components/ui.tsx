import Link from "next/link";
import { SECTIONS, type SectionKey } from "@/lib/sections";

/** Page title block for the inner pages. The accent bar carries the section's ray colour. */
export function PageHeader({
  section,
  count,
  children,
}: {
  section: SectionKey;
  count?: string;
  children?: React.ReactNode;
}) {
  const s = SECTIONS[section];
  return (
    <section className="mx-auto max-w-[76rem] px-5 pb-10 pt-14 sm:px-8 sm:pt-20">
      <div className="flex items-end justify-between gap-8">
        <div>
          <span className={`block h-1.5 w-14 rounded-full ${s.bar}`} aria-hidden />
          <h1 className="display mt-6 text-[clamp(3rem,8vw,6.25rem)]">{s.title}</h1>
          <p className="prose-tight mt-5 text-lg text-mute">{s.blurb}</p>
        </div>
        {count && (
          <p className="tnum hidden pb-2 text-right text-sm font-medium text-mute sm:block">
            {count}
          </p>
        )}
      </div>
      {children && <div className="mt-9">{children}</div>}
    </section>
  );
}

/** Filter pills that work as plain links, so filtering needs no client JavaScript. */
export function FilterPills({
  basePath,
  param,
  options,
  active,
  section,
}: {
  basePath: string;
  param: string;
  options: { value: string; label: string }[];
  active?: string;
  section: SectionKey;
}) {
  const s = SECTIONS[section];
  const pill = (isActive: boolean) =>
    `rounded-full border px-4 py-2 text-[0.95rem] font-medium transition ${
      isActive
        ? "border-night bg-night text-white"
        : "border-line bg-paper text-ink hover:border-night/40"
    }`;
  return (
    <div className="flex flex-wrap gap-2" role="group" aria-label="Filter">
      <Link href={basePath} className={pill(!active)} aria-current={!active ? "true" : undefined}>
        All
      </Link>
      {options.map((o) => (
        <Link
          key={o.value}
          href={`${basePath}?${param}=${encodeURIComponent(o.value)}`}
          className={pill(active === o.value)}
          aria-current={active === o.value ? "true" : undefined}
        >
          {o.label}
        </Link>
      ))}
      <span className="sr-only">{s.label}</span>
    </div>
  );
}

export function EmptyState({
  title,
  body,
  section,
}: {
  title: string;
  body: string;
  section: SectionKey;
}) {
  return (
    <div className="rounded-3xl border border-dashed border-line bg-paper px-8 py-16 text-center">
      <span className={`mx-auto block h-1.5 w-10 rounded-full ${SECTIONS[section].bar}`} aria-hidden />
      <h2 className="display-soft mt-6 text-3xl">{title}</h2>
      <p className="mx-auto mt-3 max-w-md text-mute">{body}</p>
    </div>
  );
}

export function ApiDown() {
  return (
    <div role="alert" className="rounded-3xl border border-red/30 bg-red/5 px-8 py-14 text-center">
      <h2 className="display-soft text-3xl">Can&rsquo;t load this right now</h2>
      <p className="mx-auto mt-3 max-w-md text-mute">
        The MySun server isn&rsquo;t answering. Check your connection and refresh the
        page in a minute.
      </p>
    </div>
  );
}

export function Stars({ rating }: { rating: number }) {
  const pct = Math.max(0, Math.min(100, (rating / 5) * 100));
  return (
    <span className="relative inline-block text-[1.05rem] leading-none tracking-[0.12em]" aria-hidden>
      <span className="text-line">★★★★★</span>
      <span className="absolute inset-y-0 left-0 overflow-hidden text-gold" style={{ width: `${pct}%` }}>
        ★★★★★
      </span>
    </span>
  );
}

export function Check({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 20 20" className={`h-[1.05em] w-[1.05em] ${className}`} aria-hidden>
      <circle cx="10" cy="10" r="9" fill="currentColor" />
      <path d="m6 10.3 2.7 2.7L14 7.6" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function ArrowRight({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={`h-6 w-6 ${className}`} aria-hidden fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

export function PhoneIcon({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={`h-[1.1em] w-[1.1em] ${className}`} aria-hidden fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2Z" />
    </svg>
  );
}

export function ArrowLeft({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={`h-6 w-6 ${className}`} aria-hidden fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M19 12H5M11 6l-6 6 6 6" />
    </svg>
  );
}
