import type { Metadata } from "next";
import { getCampusServices, type CampusServiceCategory } from "@/lib/api";
import { ApiDown, EmptyState, FilterPills, PageHeader, PhoneIcon } from "@/components/ui";
import { telHref } from "@/lib/format";

export const metadata: Metadata = {
  title: "Campus services",
  description: "Food, health, IT support and library services at Soroti University.",
};

const CATEGORIES: { value: CampusServiceCategory; label: string }[] = [
  { value: "food", label: "Food" },
  { value: "health", label: "Health" },
  { value: "it_support", label: "IT support" },
  { value: "library", label: "Library" },
];

export default async function ServicesPage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string }>;
}) {
  const { category } = await searchParams;
  const all = await getCampusServices();
  const items = (all ?? []).filter((s) => !category || s.category === category);
  const label = (c: string) => CATEGORIES.find((x) => x.value === c)?.label ?? c;

  return (
    <>
      <PageHeader section="services" count={all ? `${items.length} ${items.length === 1 ? "service" : "services"}` : undefined}>
        <FilterPills basePath="/services" param="category" options={CATEGORIES} active={category} section="services" />
      </PageHeader>
      <div className="mx-auto max-w-[76rem] px-5 pb-28 sm:px-8">
        {all === null ? (
          <ApiDown />
        ) : items.length === 0 ? (
          <EmptyState section="services" title="Nothing listed here yet" body="Administrators add campus services from the app." />
        ) : (
          <ul className="border-t border-line">
            {items.map((s) => (
              <li key={s.id} className="grid gap-4 border-b border-line py-7 lg:grid-cols-[1.3fr_1fr_auto] lg:items-center lg:gap-10">
                <div>
                  <p className="text-sm font-semibold text-mute">{label(s.category)}</p>
                  <h3 className="display-soft text-[1.7rem]">{s.name}</h3>
                  {s.description && <p className="prose-tight mt-2 text-mute">{s.description}</p>}
                </div>
                <div>
                  {s.opening_hours && <p className="font-medium">{s.opening_hours}</p>}
                  {s.location && <p className="mt-1 text-mute">{s.location}</p>}
                </div>
                {s.contact_phone && (
                  <a
                    href={telHref(s.contact_phone)}
                    className="inline-flex min-h-11 w-fit items-center gap-2 rounded-full bg-night px-5 py-2.5 text-[0.95rem] font-semibold text-white transition hover:bg-blue"
                  >
                    <PhoneIcon /> {s.contact_phone}
                  </a>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
