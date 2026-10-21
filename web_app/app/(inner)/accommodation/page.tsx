import type { Metadata } from "next";
import { getAccommodation } from "@/lib/api";
import { ApiDown, EmptyState, FilterPills, PageHeader } from "@/components/ui";
import { HousingCard } from "@/components/listings";

export const metadata: Metadata = {
  title: "Student housing",
  description: "Hostels and rentals near Soroti University, with prices and contact numbers.",
};

const TYPES = [
  { value: "hostel", label: "Hostels" },
  { value: "rental", label: "Rentals" },
];

export default async function AccommodationPage({
  searchParams,
}: {
  searchParams: Promise<{ type?: string }>;
}) {
  const { type } = await searchParams;
  const all = await getAccommodation();
  const items = (all ?? [])
    .filter((h) => !type || h.type === type)
    .sort((a, b) => Number(b.is_available) - Number(a.is_available) || a.price - b.price);

  return (
    <>
      <PageHeader
        section="accommodation"
        count={all ? `${items.length} ${items.length === 1 ? "listing" : "listings"}` : undefined}
      >
        <FilterPills
          basePath="/accommodation"
          param="type"
          options={TYPES}
          active={type}
          section="accommodation"
        />
      </PageHeader>

      <div className="mx-auto max-w-[76rem] px-5 pb-28 sm:px-8">
        {all === null ? (
          <ApiDown />
        ) : items.length === 0 ? (
          <EmptyState
            section="accommodation"
            title="No listings here yet"
            body="Hostel managers and landlords add rooms from the app. Try the other type, or check back soon."
          />
        ) : (
          <>
            <p className="mb-8 max-w-2xl text-mute">
              Hostel prices are per semester. Rentals are per month. Gazetted means the
              hostel is on the university&rsquo;s approved list.
            </p>
            <div className="grid gap-6 md:grid-cols-2">
              {items.map((h) => (
                <div key={h.id} className={h.is_available ? "" : "opacity-60"}>
                  <HousingCard h={h} large />
                  {!h.is_available && (
                    <p className="mt-2 px-2 text-sm font-medium text-red-deep">Fully booked</p>
                  )}
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </>
  );
}
