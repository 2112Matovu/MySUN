import { z } from "zod";

const email = z
  .string()
  .trim()
  .toLowerCase()
  .max(254, "Email must be less than 254 characters.")
  .pipe(z.email("Enter a valid email address."));

const name = z
  .string()
  .trim()
  .min(2, "Name must be at least 2 characters.")
  .max(100, "Name must be less than 100 characters.")
  .regex(/^[\p{L}\s\-'.]+$/u, "Name can only contain letters, spaces, hyphens, apostrophes and dots.");

export const loginSchema = z.object({
  email,
  password: z.string().min(1, "Enter your password.").max(200, "Password is too long."),
});

export const signupSchema = z.object({
  name,
  email,
  password: z
    .string()
    .min(8, "Use at least 8 characters for your password.")
    .max(200, "Password is too long."),
});

export const forgotSchema = z.object({ email });

/** First message per field, or the first overall message when asked for a single string. */
export function firstError(error: z.ZodError): string {
  return error.issues[0]?.message ?? "Check the details and try again.";
}
