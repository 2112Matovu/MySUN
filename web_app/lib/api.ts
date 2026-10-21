// Typed read-only client for the MySun API. Fields mirror the Pydantic schemas.
// Public pages only call unauthenticated GET endpoints, server-side, so there
// are no CORS or token concerns here.

export const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE ?? "https://2401600066.ncedges.com/api/v1";

export type Announcement = {
  id: string;
  title: string;
  description: string;
  category: string;
  publisher_name: string;
  published_at: string;
  is_important: boolean;
  image_url: string | null;
  expires_at: string | null;
};

export type CampusEvent = {
  id: string;
  title: string;
  description: string;
  category: string;
  organizer_name: string;
  date_time: string;
  end_date_time: string | null;
  venue: string;
  image_url: string | null;
  capacity: number | null;
  registered_count: number;
  is_featured: boolean;
};

export type Accommodation = {
  id: string;
  name: string;
  type: "hostel" | "rental" | string;
  location: string;
  price: number;
  is_gazetted: boolean;
  room_sharing: string;
  contact_phone: string;
  image_urls: string[];
  description: string;
  publisher_name: string;
  is_available: boolean;
};

export type TransportProvider = {
  id: string;
  name: string;
  phone_number: string;
  service_type: string;
  contact_person: string | null;
  operating_hours: string | null;
  service_areas: string[];
  image_url: string | null;
  is_verified: boolean;
  rating: number | null;
  rating_count: number;
};

/** Returns null when the API can't be reached, so pages can show a real error state. */
async function get<T>(path: string): Promise<T | null> {
  try {
    const res = await fetch(`${API_BASE}${path}`, { next: { revalidate: 60 } });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

export const getAnnouncements = (category?: string) =>
  get<Announcement[]>(
    `/announcements${category ? `?category=${encodeURIComponent(category)}` : ""}`,
  );
export const getEvents = () => get<CampusEvent[]>("/events");
export const getAccommodation = (type?: string) =>
  get<Accommodation[]>(
    `/accommodation${type ? `?type=${encodeURIComponent(type)}` : ""}`,
  );
export const getTransport = () => get<TransportProvider[]>("/transport");

export type BusSchedule = {
  id: string;
  route_name: string;
  departure_point: string;
  destination: string;
  departure_time: string;
  estimated_duration_minutes: number;
  operating_days: string;
  status?: string;
  notes?: string | null;
};

export type CampusServiceCategory = "food" | "health" | "it_support" | "library";

export type CampusService = {
  id: string;
  category: CampusServiceCategory;
  name: string;
  description?: string | null;
  location?: string | null;
  opening_hours?: string | null;
  contact_phone?: string | null;
};

export type SearchResults = {
  announcements: Announcement[];
  events: CampusEvent[];
  accommodation: Accommodation[];
  transport: TransportProvider[];
};

export const getAnnouncement = (id: string) => get<Announcement>(`/announcements/${id}`);
export const getEvent = (id: string) => get<CampusEvent>(`/events/${id}`);
export const getAccommodationItem = (id: string) => get<Accommodation>(`/accommodation/${id}`);
export const getProvider = (id: string) => get<TransportProvider>(`/transport/${id}`);
export const getBusSchedule = () => get<BusSchedule[]>("/transport/bus-schedule");
export const getCampusServices = () => get<CampusService[]>("/campus-services");
