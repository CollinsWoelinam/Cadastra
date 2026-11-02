"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { api } from "@/lib/api";
import { initials } from "@/lib/format";
import { BrandMark } from "@/components/Icons";
import { useMe } from "@/components/Session";

/** Fired after a change that alters registry counts (e.g. a review decision). */
export const REGISTRY_CHANGED = "cadastra:registry-changed";

const ROLE_LABEL = { SURVEYOR: "Surveyor", REVIEWER: "Reviewer", ADMIN: "Administrator" } as const;

export default function AppHeader() {
  const pathname = usePathname();
  const me = useMe();
  const [pending, setPending] = useState<number | null>(null);

  useEffect(() => {
    if (!me) return;
    const load = () => api.stats().then((s) => setPending(s.PENDING)).catch(() => {});
    load();
    window.addEventListener(REGISTRY_CHANGED, load);
    return () => window.removeEventListener(REGISTRY_CHANGED, load);
  }, [me]);

  if (pathname === "/login") return null;
  if (pathname.startsWith("/verify")) {
    return (
      <header className="public-header">
        <div>
          <Link href="/verify" className="brand">
            <BrandMark ring="#0B6E4F" />
            <span className="brand-name">Cadastra</span>
            <span className="brand-sub">Certificate verification</span>
          </Link>
          <Link href={me ? "/" : "/login"} style={{ fontWeight: 600, fontSize: 14 }}>{me ? "Back to the registry" : "Registry staff sign in"}</Link>
        </div>
      </header>
    );
  }

  const link = (href: string, label: React.ReactNode, active: boolean) => (
    <Link href={href} className="nav-link" aria-current={active ? "page" : undefined}>{label}</Link>
  );

  async function signOut() {
    await fetch("/api/auth/logout", { method: "POST" });
    // Full reload, not router.push: hidden routes stay mounted (Activity) and would keep the
    // previous session's data in memory.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.assign("/login");
  }

  return (
    <header className="app-header">
      <Link href="/" className="brand">
        <BrandMark />
        <span className="brand-name">Cadastra</span>
        <span className="brand-sub">Lands Registry · Ghana</span>
      </Link>
      <nav className="main-nav" aria-label="Main">
        {link("/", "Registry map", pathname === "/")}
        {link("/inspector", <>Encroachment inspector{!!pending && <span className="count-badge">{pending}</span>}</>,
          pathname.startsWith("/inspector"))}
        {me?.role === "ADMIN" && link("/users", "Accounts", pathname.startsWith("/users"))}
      </nav>
      {me && (
        <div className="user-menu">
          <Link href="/account" className="user-chip" title="My account">
            <span className={`avatar ${me.role}`}>{initials(me.full_name)}</span>
            <span className="user-chip-text">
              <span className="user-chip-name">{me.full_name}</span>
              <span className="user-chip-role">{ROLE_LABEL[me.role]}</span>
            </span>
          </Link>
          <button type="button" className="btn-dark" onClick={signOut}>Sign out</button>
        </div>
      )}
    </header>
  );
}
