import type { Metadata } from "next";
import Link from "next/link";
import { ForgotForm } from "@/components/auth-forms";

export const metadata: Metadata = { title: "Reset password" };

export default function ForgotPasswordPage() {
  return (
    <>
      <h1 className="display text-5xl">Reset password</h1>
      <p className="mt-3 text-mute">
        Enter your email and we&rsquo;ll send you a link to choose a new password.
      </p>
      <div className="mt-8">
        <ForgotForm />
      </div>
      <p className="mt-8 text-center text-mute">
        <Link href="/login" className="font-semibold text-blue hover:underline">
          Back to sign in
        </Link>
      </p>
    </>
  );
}
