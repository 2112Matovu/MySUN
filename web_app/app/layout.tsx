import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://2401600066.ncedges.com"),
  title: {
    default: "MySun: Soroti University campus companion",
    template: "%s | MySun",
  },
  description:
    "Announcements, events, student housing and boda stages for Soroti University, posted by the people who run them.",
  openGraph: {
    title: "MySun: Soroti University campus companion",
    description:
      "Announcements, events, student housing and boda stages for Soroti University.",
    type: "website",
    locale: "en_UG",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d1b35",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-dvh antialiased">{children}</body>
    </html>
  );
}
