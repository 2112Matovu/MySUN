"use client";

import { useEffect, useState } from "react";
import { SunMark } from "./SunMark";

type Phase = "dawn" | "day" | "dusk" | "night";

/** Hours and minutes in Soroti (EAT), independent of the visitor's own timezone. */
function sorotiTime(now = new Date()) {
  // ?hour=14.5 previews the sky at another time of day (handy for design review).
  const preview = new URLSearchParams(window.location.search).get("hour");
  if (preview !== null && Number.isFinite(Number(preview))) {
    const t = ((Number(preview) % 24) + 24) % 24;
    return { h: Math.floor(t), m: Math.floor((t % 1) * 60), t };
  }
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Kampala",
    hour: "numeric",
    minute: "numeric",
    hour12: false,
  }).formatToParts(now);
  const h = Number(parts.find((p) => p.type === "hour")?.value ?? 12) % 24;
  const m = Number(parts.find((p) => p.type === "minute")?.value ?? 0);
  return { h, m, t: h + m / 60 };
}

function phaseAt(t: number): Phase {
  if (t >= 5.5 && t < 7.5) return "dawn";
  if (t >= 7.5 && t < 17) return "day";
  if (t >= 17 && t < 19) return "dusk";
  return "night";
}

// The sun climbs from 06:00 to 18:00 (Soroti sits on the equator, so day length barely changes).
const sunFraction = (t: number) => (t - 6) / 12;

// Arc geometry in a 1100 x 330 box.
const W = 1100;
const H = 330;
const RX = 496;
const RY = 280;
const sunX = (f: number) => (W / 2 - RX * Math.cos(Math.PI * f)) / W;
const sunY = (f: number) => (RY * Math.sin(Math.PI * f)) / H;

const easeOut = (x: number) => 1 - Math.pow(1 - x, 3);

function Moon({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden>
      <defs>
        <mask id="moon-mask">
          <rect width="100" height="100" fill="#fff" />
          <circle cx="64" cy="42" r="34" fill="#000" />
        </mask>
      </defs>
      <circle cx="46" cy="52" r="34" fill="#eef2ff" mask="url(#moon-mask)" />
    </svg>
  );
}

export function SkyHero({
  header,
  children,
}: {
  header: React.ReactNode;
  children: React.ReactNode;
}) {
  // Start from a neutral midday sky and let it catch up to the real hour on load.
  const [phase, setPhase] = useState<Phase>("day");
  const [clock, setClock] = useState<string | null>(null);
  const [t, setT] = useState(12);
  const [prog, setProg] = useState(0);

  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;

    const tick = () => {
      const now = sorotiTime();
      setT(now.t);
      setPhase(phaseAt(now.t));
      const hr = now.h % 12 === 0 ? 12 : now.h % 12;
      setClock(`${hr}:${String(now.m).padStart(2, "0")} ${now.h < 12 ? "am" : "pm"}`);
    };
    tick();

    if (reduce) {
      setProg(1);
    } else {
      const start = performance.now();
      const run = (now: number) => {
        const p = Math.min(1, (now - start) / 2600);
        setProg(easeOut(p));
        if (p < 1) raf = requestAnimationFrame(run);
      };
      raf = requestAnimationFrame(run);
    }

    const id = window.setInterval(tick, 30_000);
    return () => {
      cancelAnimationFrame(raf);
      window.clearInterval(id);
    };
  }, []);

  const light = phase !== "day";
  // Both bodies rise from below the horizon to their real position for this hour.
  const RISE_FROM = -0.12;
  const rise = (target: number) => RISE_FROM + (target - RISE_FROM) * prog;
  const sunTarget = sunFraction(t);
  const sunVisible = sunTarget > -0.06 && sunTarget < 1.06;
  const moonTarget = ((t >= 12 ? t - 18 : t + 6) ) / 12;
  const moonVisible = !sunVisible && moonTarget > -0.04 && moonTarget < 1.04;
  const f = rise(sunTarget);
  const mf = rise(moonTarget);

  return (
    <section
      data-phase={phase}
      data-dark={light ? "" : undefined}
      className="relative isolate flex min-h-[min(100svh,54rem)] flex-col overflow-hidden"
      style={{
        color: light ? "#ffffff" : "#0d1b35",
        transition: "color 1800ms ease",
      }}
    >
      <div aria-hidden className="absolute inset-0 -z-10">
        <div className="sky sky-dawn" data-on={phase === "dawn"} />
        <div className="sky sky-day" data-on={phase === "day"} />
        <div className="sky sky-dusk" data-on={phase === "dusk"} />
        <div className="sky sky-night" data-on={phase === "night"} />
      </div>

      {header}

      <div className="mx-auto flex w-full max-w-[76rem] flex-1 flex-col justify-center px-5 pb-4 pt-28 sm:px-8">
        {children}
      </div>

      {/* The sun's path across the sky. */}
      <div className="relative mx-auto -mt-10 w-full max-w-[900px] px-0">
        <div className="relative w-full" style={{ aspectRatio: `${W} / ${H}` }}>
          <svg
            viewBox={`0 0 ${W} ${H}`}
            className="absolute inset-0 h-full w-full"
            fill="none"
            aria-hidden
          >
            <path
              d={`M ${W / 2 - RX} ${H} A ${RX} ${RY} 0 0 1 ${W / 2 + RX} ${H}`}
              stroke="currentColor"
              strokeOpacity="0.28"
              strokeWidth="1.5"
              strokeDasharray="2 9"
              strokeLinecap="round"
            />
          </svg>

          {moonVisible && (
            <div
              className="absolute"
              style={{
                left: `${sunX(mf) * 100}%`,
                bottom: `${sunY(mf) * 100 - 3}%`,
                transform: "translate(-50%, 50%)",
                filter: "drop-shadow(0 0 30px rgba(190,210,255,0.45))",
              }}
            >
              <Moon size={84} />
            </div>
          )}

          {sunVisible && (
            <div
              className="absolute"
              style={{
                left: `${sunX(f) * 100}%`,
                bottom: `${sunY(f) * 100 - 3}%`,
                transform: "translate(-50%, 50%)",
                filter: "drop-shadow(0 0 28px rgba(245,179,24,0.55))",
              }}
            >
              <SunMark size={96} lightRays={light} />
            </div>
          )}

          <p className="tnum absolute inset-x-0 -bottom-1 text-center text-sm font-medium opacity-90">
            {clock ? (
              <>
                <span className="text-base font-semibold">{clock}</span> in Soroti
              </>
            ) : (
              <span className="opacity-0">00:00 am in Soroti</span>
            )}
          </p>
        </div>
      </div>

      {/* Soroti Rock and an acacia against the horizon. */}
      <svg
        viewBox="0 0 1440 170"
        preserveAspectRatio="xMidYMax slice"
        className="relative -mb-px block h-[max(6rem,11.8vw)] w-full"
        aria-hidden
      >
        <path
          fill="#0d1b35"
          d="M0 170V122c110-6 210 4 330-2 120-7 210 6 350 1 130-5 210 3 320-3 52-3 66-48 112-68 44-19 100-21 136-4 40 19 52 60 80 70 38 12 72 9 112 11v43Z"
        />
        <path
          fill="#0d1b35"
          d="M214 124c1-26 0-44-4-60-1-4 2-6 4-3 5 8 7 24 8 63Zm-92-56c34-26 92-34 148-30 46 4 78 18 96 36-34-8-70-8-118-6-58 2-100 2-126 0Z"
        />
      </svg>
    </section>
  );
}
