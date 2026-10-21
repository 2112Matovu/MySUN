// Shared constants and types for the publisher tools. The draft `form_data` keys
// match the Android app so a draft started on a phone can be finished here.

export type ContentType = "announcement" | "event" | "accommodation" | "transport";

export const CONTENT_TYPES: ContentType[] = ["announcement", "event", "accommodation", "transport"];

export const isContentType = (v: string): v is ContentType =>
  (CONTENT_TYPES as string[]).includes(v);

export const TYPE_LABEL: Record<ContentType, string> = {
  announcement: "Announcement",
  event: "Event",
  accommodation: "Housing listing",
  transport: "Boda rider",
};

export const DEPARTMENTS = [
  "HR Department",
  "Academic Registrar",
  "Student Affairs",
  "ICT Directorate",
  "Finance Department",
];

export const ORGANIZERS = [
  "Student Affairs Office",
  "Department of Computer Science",
  "Sports Department",
  "Careers & Counselling Unit",
  "Students' Guild",
];

export const ANNOUNCEMENT_CATEGORIES = ["Academic", "Social", "Sports", "Administration", "Clubs", "Transport"];
export const EVENT_CATEGORIES = ["Academic", "Sports", "Social", "Clubs", "Workshops"];

export type Submission = {
  id: string;
  publisher_id: string;
  type: ContentType;
  title: string;
  status: "draft" | "scheduled" | "published" | "removed";
  content_id: string | null;
  form_data: Record<string, unknown> | null;
  publisher_name: string | null;
  removal_reason: string | null;
  publish_at: string | null;
  updated_at: string;
};

export type Performance = {
  total_submissions: number;
  published: number;
  removed: number;
  drafts: number;
  by_type: Record<string, number>;
  estimated_views: number;
  engagement_percent: number;
};

/** A datetime-local value ("2026-10-21T09:30") typed in Soroti time, as an ISO instant. */
export function sorotiToIso(local: string | null | undefined): string | null {
  if (!local) return null;
  const d = new Date(`${local.length === 16 ? `${local}:00` : local}+03:00`);
  return Number.isNaN(+d) ? null : d.toISOString();
}

/** An ISO instant as a datetime-local value in Soroti time. */
export function isoToSoroti(iso: string | null | undefined): string {
  if (!iso) return "";
  const d = new Date(new Date(iso).getTime() + 3 * 3_600_000);
  return Number.isNaN(+d) ? "" : d.toISOString().slice(0, 16);
}
