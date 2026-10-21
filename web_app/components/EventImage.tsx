/**
 * Event poster shown whole (never cropped), on a blurred copy of itself so
 * portrait and landscape posters both fill the frame cleanly.
 */
export function EventImage({
  src,
  title,
  className = "",
  priority = false,
}: {
  src: string;
  title: string;
  className?: string;
  priority?: boolean;
}) {
  return (
    <div className={`relative overflow-hidden rounded-2xl bg-night ${className}`}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={src} alt="" aria-hidden loading="lazy" className="absolute inset-0 h-full w-full scale-125 object-cover opacity-60 blur-2xl" />
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src}
        alt={`Poster for ${title}`}
        loading={priority ? "eager" : "lazy"}
        decoding="async"
        className="relative h-full w-full object-contain"
      />
    </div>
  );
}
