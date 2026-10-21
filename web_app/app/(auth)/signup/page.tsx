import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { GoogleButton } from "@/components/GoogleButton";
import { SignupForm } from "@/components/auth-forms";
import { getUser, safeNext } from "@/lib/auth";

export const metadata: Metadata = { title: "Create account" };

export default async function SignupPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const next = safeNext((await searchParams).next);
  if (await getUser()) redirect(next);
  return (
    <>
      <h1 className="display text-5xl">Create your account</h1>
      <p className="mt-3 text-mute">Every new account starts as a student.</p>
      <div className="mt-8">
        <GoogleButton next={next} text="signup_with" />
        <p className="my-6 text-center text-sm text-mute">or sign up with your email</p>
        <SignupForm next={next} />
      </div>
      <p className="mt-8 text-center text-mute">
        Already have an account?{" "}
        <Link href="/login" className="font-semibold text-blue hover:underline">
          Sign in
        </Link>
      </p>
    </>
  );
}
