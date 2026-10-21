"use client";

import { useFormStatus } from "react-dom";
import { useId, useState } from "react";

/** Primary submit button that shows progress and blocks double submits. */
export function SubmitButton({
  children,
  pending: pendingLabel,
  tone = "night",
  className = "",
}: {
  children: React.ReactNode;
  pending?: string;
  tone?: "night" | "gold" | "red";
  className?: string;
}) {
  const { pending } = useFormStatus();
  const tones = {
    night: "bg-night text-white hover:bg-blue",
    gold: "bg-gold text-night hover:bg-gold/85",
    red: "bg-red-deep text-white hover:bg-red",
  };
  return (
    <button
      type="submit"
      disabled={pending}
      className={`inline-flex min-h-12 items-center justify-center gap-2 rounded-full px-7 py-3 text-[1rem] font-semibold transition disabled:cursor-wait disabled:opacity-70 ${tones[tone]} ${className}`}
    >
      {pending && (
        <span
          aria-hidden
          className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
        />
      )}
      {pending ? (pendingLabel ?? "Working…") : children}
    </button>
  );
}

const input =
  "w-full rounded-2xl border border-line bg-paper px-4 py-3.5 text-[1.02rem] text-ink placeholder:text-mute/60 transition focus:border-blue focus:outline-none focus:ring-4 focus:ring-blue/15";

export function Field({
  label,
  hint,
  error,
  className = "",
  ...props
}: {
  label: string;
  hint?: string;
  error?: string;
} & React.InputHTMLAttributes<HTMLInputElement>) {
  const id = useId();
  return (
    <div className={className}>
      <label htmlFor={id} className="mb-1.5 block text-[0.95rem] font-semibold">
        {label}
      </label>
      <input id={id} aria-invalid={error ? true : undefined} className={input} {...props} />
      {hint && !error && <p className="mt-1.5 text-sm text-mute">{hint}</p>}
      {error && <p className="mt-1.5 text-sm text-red-deep">{error}</p>}
    </div>
  );
}

export function PasswordField({
  label = "Password",
  hint,
  ...props
}: { label?: string; hint?: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  const [show, setShow] = useState(false);
  const id = useId();
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-[0.95rem] font-semibold">
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          type={show ? "text" : "password"}
          autoCapitalize="none"
          autoCorrect="off"
          spellCheck={false}
          className={`${input} pr-20`}
          {...props}
        />
        {/* preventDefault on press keeps focus (and the phone keyboard) in the input while toggling. */}
        <button
          type="button"
          onPointerDown={(e) => e.preventDefault()}
          onClick={() => setShow((s) => !s)}
          aria-pressed={show}
          aria-label={show ? "Hide password" : "Show password"}
          className="absolute right-1.5 top-1/2 min-h-11 min-w-16 -translate-y-1/2 touch-manipulation rounded-full px-3 text-sm font-semibold text-blue active:bg-blue/10"
        >
          {show ? "Hide" : "Show"}
        </button>
      </div>
      {hint && <p className="mt-1.5 text-sm text-mute">{hint}</p>}
    </div>
  );
}

export function TextArea({
  label,
  hint,
  className = "",
  ...props
}: { label: string; hint?: string } & React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  const id = useId();
  return (
    <div className={className}>
      <label htmlFor={id} className="mb-1.5 block text-[0.95rem] font-semibold">
        {label}
      </label>
      <textarea id={id} rows={5} className={`${input} resize-y`} {...props} />
      {hint && <p className="mt-1.5 text-sm text-mute">{hint}</p>}
    </div>
  );
}

export function Select({
  label,
  options,
  className = "",
  ...props
}: {
  label: string;
  options: { value: string; label: string }[];
} & React.SelectHTMLAttributes<HTMLSelectElement>) {
  const id = useId();
  return (
    <div className={className}>
      <label htmlFor={id} className="mb-1.5 block text-[0.95rem] font-semibold">
        {label}
      </label>
      <select id={id} className={input} {...props}>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
}

export function FormMessage({ error, notice }: { error?: string; notice?: string }) {
  if (!error && !notice) return null;
  return (
    <p
      role={error ? "alert" : "status"}
      className={`rounded-2xl px-4 py-3 text-[0.95rem] font-medium ${
        error ? "bg-red/10 text-red-deep" : "bg-teal/10 text-teal-deep"
      }`}
    >
      {error ?? notice}
    </p>
  );
}
