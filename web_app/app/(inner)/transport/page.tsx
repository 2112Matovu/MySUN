import type { Metadata } from "next";
import { getTransport } from "@/lib/api";
import { getUser } from "@/lib/auth";
import Link from "next/link";
import { ApiDown, EmptyState, PageHeader } from "@/components/ui";
import { BodaRow } from "@/components/listings";

export const metadata: Metadata = {
  title: "Boda stages",
  description: "Verified boda riders and stages around Soroti University, with hours and phone numbers.",
};

export default async function TransportPage() {
  const all = await getTransport();
  const user = await getUser();
  const items = [...(all ?? [])].sort(
    (a, b) =>
      Number(b.is_verified) - Number(a.is_verified) || (b.rating ?? 0) - (a.rating ?? 0),
  );

  return (
    <>
      <PageHeader
        section="transport"
        count={all ? `${items.length} ${items.length === 1 ? "stage" : "stages"}` : undefined}
      />
      <div className="mx-auto max-w-[76rem] px-5 pb-28 sm:px-8">
        {all === null ? (
          <ApiDown />
        ) : items.length === 0 ? (
          <EmptyState
            section="transport"
            title="No stages listed yet"
            body="Stage chairpersons and riders can list themselves from the app."
          />
        ) : (
          <>
            <p className="mb-8 max-w-2xl text-mute">
              Verified stages have been checked by the MySun team. Ratings come from
              students who have used them.
            </p>
            <Link href="/transport/bus-schedule" className="mb-8 inline-flex items-center gap-2 font-semibold text-blue hover:underline">
              See the bus schedule
            </Link>
            <ul className="border-t border-line">
              {items.map((t) => (
                <BodaRow key={t.id} t={t} signedIn={Boolean(user)} />
              ))}
            </ul>
          </>
        )}
      </div>
    </>
  );
}
