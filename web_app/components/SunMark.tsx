/** The MySun logo as vector art, rebuilt from the supplied icon so it stays sharp at any size. */
const RAYS: { angle: number; color: string }[] = [
  { angle: 0, color: "#f5b318" },
  { angle: 45, color: "#0a4a8f" },
  { angle: 90, color: "#0a4a8f" },
  { angle: 135, color: "#11a597" },
  { angle: 180, color: "#11a597" },
  { angle: 225, color: "#d9453b" },
  { angle: 270, color: "#d9453b" },
  { angle: 315, color: "#f5b318" },
];

export function SunMark({
  size = 40,
  lightRays = false,
  className,
}: {
  size?: number;
  /** Brighter blue and red rays for use on dark backgrounds. */
  lightRays?: boolean;
  className?: string;
}) {
  const swap = (c: string) =>
    lightRays ? (c === "#0a4a8f" ? "#3b8be0" : c === "#d9453b" ? "#ee6258" : c) : c;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      className={className}
      role="img"
      aria-label="MySun"
    >
      <g strokeWidth="5.5" strokeLinecap="round">
        {RAYS.map(({ angle, color }) => (
          <line
            key={angle}
            x1="50"
            y1="11"
            x2="50"
            y2="22"
            stroke={swap(color)}
            transform={`rotate(${angle} 50 50)`}
          />
        ))}
      </g>
      <circle cx="50" cy="50" r="17" fill="#f3f3f3" stroke="#f5b318" strokeWidth="1.8" />
      <circle cx="50" cy="50" r="9.6" fill="none" stroke="#5b8db8" strokeWidth="0.9" />
      <circle cx="50" cy="50" r="3.5" fill="#0a4a8f" />
    </svg>
  );
}
