"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { SECTIONS, SECTION_ORDER } from "@/lib/sections";

export function NavLinks() {
  const pathname = usePathname();
  return (
    <>
      {SECTION_ORDER.map((key) => {
        const s = SECTIONS[key];
        const active = pathname === s.href || pathname.startsWith(`${s.href}/`);
        return (
          <Link
            key={key}
            href={s.href}
            aria-current={active ? "page" : undefined}
            className={`relative py-2 text-[0.95rem] font-medium transition-opacity hover:opacity-100 ${
              active ? "opacity-100" : "opacity-80"
            }`}
          >
            {s.label}
            <span
              aria-hidden
              className={`absolute inset-x-0 -bottom-0.5 h-[3px] origin-left rounded-full transition-transform duration-300 ${s.bar} ${
                active ? "scale-x-100" : "scale-x-0"
              }`}
            />
          </Link>
        );
      })}
    </>
  );
}
