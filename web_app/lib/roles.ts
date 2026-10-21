export type Role = "student" | "publisher" | "admin" | "minor_admin";

export const ROLE_LABEL: Record<Role, string> = {
  student: "Student",
  publisher: "Publisher",
  admin: "Super admin",
  minor_admin: "Admin",
};

// Matches the Android app and the API: only publishers publish; admins moderate.
export const canPublish = (r: Role) => r === "publisher";
export const isAdminLevel = (r: Role) => r === "admin" || r === "minor_admin";

/** Where a user lands after signing in with no destination, as in the Android app. */
export const homeFor = (r: Role) => (isAdminLevel(r) ? "/admin" : canPublish(r) ? "/publish" : "/");
