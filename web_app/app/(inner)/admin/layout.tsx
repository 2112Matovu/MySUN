import { IdleLogout } from "@/components/admin-actions";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <IdleLogout />
      {children}
    </>
  );
}
