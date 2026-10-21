import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { GoogleButton } from "@/components/GoogleButton";
import { LoginForm } from "@/components/auth-forms";
import { getUser, safeNext } from "@/lib/auth";
import { homeFor } from "@/lib/roles";

export const metadata: Metadata = { title: "Sign in" };

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const next = safeNext((await searchParams).next);
  const me = await getUser();
  if (me) redirect(next === "/" ? homeFor(me.role) : next);
  return (
    <>
      <h1 className="display text-5xl">Sign in</h1>
      <p className="mt-3 text-mute">Use the email you registered with MySun.</p>
      <div className="mt-8">
        <GoogleButton next={next} text="signin_with" />
        <p className="my-6 text-center text-sm text-mute">or use your email and password</p>
        <LoginForm next={next} />
      </div>
      <p className="mt-8 text-center text-mute">
        New to MySun?{" "}
        <Link
          href={`/signup${next !== "/" ? `?next=${encodeURIComponent(next)}` : ""}`}
          className="font-semibold text-blue hover:underline"
        >
          Create an account
        </Link>
      </p>
    </>
  );
}
