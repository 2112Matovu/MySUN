"use client";

import { useState } from "react";
import { ImageLightbox } from "./ImageLightbox";
import { SunMark } from "./SunMark";

/** Large photo with a thumbnail strip. Falls back to the logo when a listing has no photos. */
export function Gallery({ images, name }: { images: string[]; name: string }) {
  const [i, setI] = useState(0);
  if (images.length === 0) {
    return (
      <div className="flex aspect-[4/3] items-center justify-center rounded-3xl bg-night" role="img" aria-label={`No photos for ${name}`}>
        <SunMark size={96} lightRays />
      </div>
    );
  }
  return (
    <div>
      <ImageLightbox src={images[i]} alt={`${name}, photo ${i + 1} of ${images.length}`}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={images[i]} alt={`${name}, photo ${i + 1} of ${images.length}`} className="aspect-[4/3] w-full rounded-3xl object-cover" />
      </ImageLightbox>
      {images.length > 1 && (
        <ul className="mt-3 flex gap-3 overflow-x-auto pb-1">
          {images.map((src, n) => (
            <li key={src + n}>
              <button
                type="button"
                onClick={() => setI(n)}
                aria-label={`Show photo ${n + 1}`}
                aria-current={n === i}
                className={`block overflow-hidden rounded-xl ring-2 transition ${n === i ? "ring-teal" : "ring-transparent opacity-70 hover:opacity-100"}`}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={src} alt="" className="h-16 w-24 object-cover" />
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
