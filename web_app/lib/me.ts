import "server-only";
import { apiData } from "./server-api";
import type { Announcement, CampusEvent } from "./api";

export type Booking = {
  id: string;
  student_id: string;
  provider_id: string;
  pickup: string;
  destination: string;
  requested_time: string | null;
  note: string | null;
  status: "pending" | "accepted" | "declined" | "cancelled" | "completed";
  created_at: string;
  provider_name: string | null;
  provider_phone: string | null;
  student_name: string | null;
};

export type AppNotification = {
  id: string;
  title: string;
  body: string;
  type: string;
  created_at: string;
  related_id: string | null;
  is_read?: boolean;
};

export type BookmarkRow = { content_type: "announcement" | "event"; content_id: string };

export const myBookmarks = async () => (await apiData<BookmarkRow[]>("/bookmarks")) ?? [];
export const myRegistrations = async () => (await apiData<string[]>("/events/registrations/mine")) ?? [];

export type { Announcement, CampusEvent };
