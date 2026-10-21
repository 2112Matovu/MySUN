import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { MfaForm } from "@/components/auth-forms";
import { safeNext } from "@/lib/auth";

export const metadata: Metadata = { title: "Two-factor sign-in" };

export default async function VerifyPage({
  searchParams,
}: {
  searchParams: Promise<{ factor?: string; next?: string }>;
}) {
  const sp = await searchParams;
  if (!sp.factor) redirect("/login");
  return (
    <>
      <h1 className="display text-5xl">Two-factor sign-in</h1>
      <p className="mt-3 text-mute">
        Open your authenticator app and enter the 6-digit code for MySun.
      </p>
      <div className="mt-8">
        <MfaForm factor={sp.factor} next={safeNext(sp.next)} />
      </div>
      <p className="mt-8 text-center text-mute">
        <Link href="/login" className="font-semibold text-blue hover:underline">
          Back to sign in
        </Link>
      </p>
    </>
  );
}
