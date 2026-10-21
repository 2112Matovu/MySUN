import type { Metadata } from "next";
import Link from "next/link";
import { getAnnouncements } from "@/lib/api";
import { ApiDown, EmptyState, FilterPills, PageHeader } from "@/components/ui";
import { dayParts, longDate, relativeDay } from "@/lib/format";

export const metadata: Metadata = {
  title: "Announcements",
  description: "Notices from Soroti University faculties, departments and student bodies.",
};

export default async function AnnouncementsPage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string }>;
}) {
  const { category } = await searchParams;
  // Fetch the full list for the filter options, then filter locally so the
  // pills never disappear when one is selected.
  const all = await getAnnouncements();
  const categories = [...new Set((all ?? []).map((a) => a.category))].sort();
  const items = (all ?? [])
    .filter((a) => !category || a.category === category)
    .sort(
      (a, b) =>
        Number(b.is_important) - Number(a.is_important) ||
        +new Date(b.published_at) - +new Date(a.published_at),
    );

  return (
    <>
      <PageHeader
        section="announcements"
        count={all ? `${items.length} ${items.length === 1 ? "notice" : "notices"}` : undefined}
      >
        {categories.length > 1 && (
          <FilterPills
            basePath="/announcements"
            param="category"
            options={categories.map((c) => ({ value: c, label: c }))}
            active={category}
            section="announcements"
          />
        )}
      </PageHeader>

      <div className="mx-auto max-w-[76rem] px-5 pb-28 sm:px-8">
        {all === null ? (
          <ApiDown />
        ) : items.length === 0 ? (
          <EmptyState
            section="announcements"
            title={category ? `No ${category} notices` : "No announcements yet"}
            body={
              category
                ? "Nothing is posted under this category right now. Try another one, or view all notices."
                : "When a faculty or department posts a notice, it appears here straight away."
            }
          />
        ) : (
          <ul className="border-t border-line">
            {items.map((a) => {
              const d = dayParts(a.published_at);
              return (
                <li key={a.id} className="grid gap-4 border-b border-line py-9 md:grid-cols-[9rem_1fr] md:gap-10">
                  <div className="tnum text-mute">
                    <p className="display-soft text-3xl text-ink">
                      {d.day} {d.month}
                    </p>
                    <p className="text-sm">{d.year}</p>
                  </div>
                  <article className="relative md:pl-0">
                    {a.is_important && (
                      <span className="mb-3 inline-flex items-center gap-2 rounded-full bg-gold px-3.5 py-1 text-sm font-semibold text-night">
                        Important
                      </span>
                    )}
                    <h2 className="display-soft text-[clamp(1.6rem,3.2vw,2.3rem)]">
                      <Link href={`/announcements/${a.id}`} className="hover:text-blue hover:underline decoration-2 underline-offset-4">{a.title}</Link>
                    </h2>
                    <p className="mt-2 text-[0.95rem] text-mute">
                      {a.category} · {a.publisher_name} · {relativeDay(a.published_at)}
                    </p>
                    <p className="prose-tight mt-4 whitespace-pre-line">{a.description}</p>
                    {a.image_url && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={a.image_url}
                        alt=""
                        loading="lazy"
                        className="mt-6 max-h-96 w-full max-w-2xl rounded-2xl object-cover"
                      />
                    )}
                    {a.expires_at && (
                      <p className="mt-4 text-sm text-mute">Open until {longDate(a.expires_at)}</p>
                    )}
                  </article>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </>
  );
}
