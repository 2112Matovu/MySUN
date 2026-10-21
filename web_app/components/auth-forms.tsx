"use client";

import Link from "next/link";
import { useActionState } from "react";
import { Field, FormMessage, PasswordField, SubmitButton } from "./forms";
import {
  login,
  requestPasswordReset,
  signup,
  verifyMfa,
  type FormState,
} from "@/app/actions/auth";

export function LoginForm({ next }: { next: string }) {
  const [state, action] = useActionState<FormState, FormData>(login, undefined);
  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="next" value={next} />
      <FormMessage error={state?.error} />
      <Field
        label="Email address"
        name="email"
        type="email"
        autoComplete="email"
        required
        defaultValue={state?.email}
        placeholder="you@sun.ac.ug"
      />
      <PasswordField name="password" autoComplete="current-password" required />
      <div className="flex justify-end">
        <Link href="/forgot-password" className="text-sm font-semibold text-blue hover:underline">
          Forgot password?
        </Link>
      </div>
      <SubmitButton pending="Signing in…" className="w-full">
        Sign in
      </SubmitButton>
    </form>
  );
}

export function SignupForm({ next }: { next: string }) {
  const [state, action] = useActionState<FormState, FormData>(signup, undefined);
  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="next" value={next} />
      <FormMessage error={state?.error} notice={state?.notice} />
      <Field label="Full name" name="name" autoComplete="name" required placeholder="John Opiyo" />
      <Field
        label="Email address"
        name="email"
        type="email"
        autoComplete="email"
        required
        defaultValue={state?.email}
        placeholder="you@sun.ac.ug"
      />
      <PasswordField
        name="password"
        autoComplete="new-password"
        minLength={8}
        required
        hint="At least 8 characters."
      />
      <SubmitButton pending="Creating account…" className="w-full">
        Create account
      </SubmitButton>
    </form>
  );
}

export function ForgotForm() {
  const [state, action] = useActionState<FormState, FormData>(requestPasswordReset, undefined);
  return (
    <form action={action} className="space-y-5">
      <FormMessage error={state?.error} notice={state?.notice} />
      <Field
        label="Email address"
        name="email"
        type="email"
        autoComplete="email"
        required
        defaultValue={state?.email}
      />
      <SubmitButton pending="Sending…" className="w-full">
        Send reset link
      </SubmitButton>
    </form>
  );
}

export function MfaForm({ factor, next }: { factor: string; next: string }) {
  const [state, action] = useActionState<FormState, FormData>(verifyMfa, undefined);
  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="factor" value={factor} />
      <input type="hidden" name="next" value={next} />
      <FormMessage error={state?.error} />
      <Field
        label="6-digit code"
        name="code"
        inputMode="numeric"
        autoComplete="one-time-code"
        pattern="[0-9 ]{6,7}"
        maxLength={7}
        required
        autoFocus
        className="[&_input]:text-center [&_input]:text-2xl [&_input]:tracking-[0.4em]"
      />
      <SubmitButton pending="Checking…" className="w-full">
        Verify and sign in
      </SubmitButton>
    </form>
  );
}
