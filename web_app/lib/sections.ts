// Each public section owns one of the logo's ray colours. Class names are written
// out in full so Tailwind can see them.
export type SectionKey = "announcements" | "events" | "accommodation" | "transport" | "services";

export const SECTIONS: Record<
  SectionKey,
  {
    href: string;
    label: string;
    title: string;
    blurb: string;
    bar: string; // background utility for the accent bar
    text: string; // readable accent text on light surfaces
    textOnDark: string;
    soft: string; // tinted background
    hex: string;
  }
> = {
  announcements: {
    href: "/announcements",
    label: "Announcements",
    title: "Announcements",
    blurb: "Notices from faculties, departments and student bodies, newest first.",
    bar: "bg-gold",
    text: "text-gold-deep",
    textOnDark: "text-gold",
    soft: "bg-gold/15",
    hex: "#f5b318",
  },
  events: {
    href: "/events",
    label: "Events",
    title: "Events",
    blurb: "What is on at Soroti University, from lectures to career fairs.",
    bar: "bg-red",
    text: "text-red-deep",
    textOnDark: "text-[#ff8a80]",
    soft: "bg-red/10",
    hex: "#d9453b",
  },
  accommodation: {
    href: "/accommodation",
    label: "Housing",
    title: "Student housing",
    blurb: "Hostels and rentals near campus, with prices and a number to call.",
    bar: "bg-teal",
    text: "text-teal-deep",
    textOnDark: "text-[#4fd1c5]",
    soft: "bg-teal/10",
    hex: "#11857c",
  },
  transport: {
    href: "/transport",
    label: "Boda stages",
    title: "Boda stages",
    blurb: "Verified riders and stages around campus, with hours and a number to call.",
    bar: "bg-blue",
    text: "text-blue",
    textOnDark: "text-[#7db4f0]",
    soft: "bg-blue/10",
    hex: "#0a4a8f",
  },
  services: {
    href: "/services",
    label: "Campus services",
    title: "Campus services",
    blurb: "Food, health, IT support and the library: where to go and when they are open.",
    bar: "bg-night",
    text: "text-night",
    textOnDark: "text-white",
    soft: "bg-night/10",
    hex: "#0d1b35",
  },
};

export const SECTION_ORDER: SectionKey[] = [
  "announcements",
  "events",
  "accommodation",
  "transport",
  "services",
];

/** The four sections that carry a logo ray colour. */
export const RAY_SECTIONS: SectionKey[] = SECTION_ORDER.slice(0, 4);
