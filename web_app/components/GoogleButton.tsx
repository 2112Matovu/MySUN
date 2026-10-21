"use client";

import { useEffect, useRef, useState, useTransition } from "react";
import { googleLogin } from "@/app/actions/auth";

// Same Web OAuth client the Android app uses. Its "Authorised JavaScript origins"
// must include this site's origin (e.g. http://localhost:3001 and the live domain).
const CLIENT_ID =
  process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ??
  "364494750709-i4dr9m3orvle67ak62uhu26mk9eu461r.apps.googleusercontent.com";

type Gsi = {
  accounts: {
    id: {
      initialize: (o: { client_id: string; callback: (r: { credential: string }) => void }) => void;
      renderButton: (el: HTMLElement, o: Record<string, unknown>) => void;
    };
  };
};

/** Google's own sign-in button. The account's name and email become the MySun profile. */
export function GoogleButton({ next, text }: { next: string; text: "signup_with" | "signin_with" }) {
  const box = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();

  useEffect(() => {
    const setup = () => {
      const g = (window as unknown as { google?: Gsi }).google;
      if (!g || !box.current) return false;
      g.accounts.id.initialize({
        client_id: CLIENT_ID,
        callback: ({ credential }) =>
          start(async () => {
            setError(undefined);
            const r = await googleLogin(credential, next);
            if (r?.error) setError(r.error);
          }),
      });
      g.accounts.id.renderButton(box.current, { theme: "outline", size: "large", shape: "pill", text, width: 320 });
      return true;
    };
    if (setup()) return;
    const s = document.createElement("script");
    s.src = "https://accounts.google.com/gsi/client";
    s.async = true;
    s.onload = setup;
    s.onerror = () => setError("Couldn't load Google sign-in. Check your connection.");
    document.head.appendChild(s);
  }, [next, text]);

  return (
    <div>
      <div ref={box} className={`flex min-h-11 justify-center ${pending ? "opacity-50" : ""}`} />
      {error && <p role="alert" className="mt-3 text-center text-sm text-red-deep">{error}</p>}
    </div>
  );
}
