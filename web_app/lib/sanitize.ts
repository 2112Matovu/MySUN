import xss, { type IFilterXSSOptions } from "xss";

const options: IFilterXSSOptions = {
  whiteList: {},
  stripIgnoreTag: true,
  stripIgnoreTagBody: ["script", "style"],
};

/** Strips markup from free text. Never use this on passwords: it would change them. */
export function sanitize(input: unknown): string {
  if (typeof input !== "string") return "";
  return xss(input.trim(), options);
}

export function sanitizeEmail(input: unknown): string {
  return typeof input === "string" ? input.trim().toLowerCase() : "";
}
