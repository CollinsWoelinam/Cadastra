"use client";

import { createContext, useContext, useEffect, useState } from "react";
import Link from "next/link";

export interface Me {
  id: string;
  email: string;
  full_name: string;
  role: "SURVEYOR" | "REVIEWER" | "ADMIN";
}

const SessionContext = createContext<Me | null>(null);

export function useMe() {
  return useContext(SessionContext);
}

export function canReview(me: Me | null) {
  return me?.role === "REVIEWER" || me?.role === "ADMIN";
}

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [me, setMe] = useState<Me | null>(null);
  useEffect(() => {
    fetch("/core/auth/me", { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : null))
      .then(setMe)
      .catch(() => setMe(null));
  }, []);
  return <SessionContext value={me}>{children}</SessionContext>;
}

export function UserMenu() {
  const me = useMe();
  if (!me) return null;
  async function signOut() {
    await fetch("/api/auth/logout", { method: "POST" });
    // Full reload, not router.push: hidden routes stay mounted (Activity) and would keep the
    // previous session's data in memory.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.assign("/login");
  }
  return (
    <div className="user-menu">
      <Link href="/account" title="My account">
        <span className="who">{me.full_name} · <span className="role">{me.role.toLowerCase()}</span></span>
        <span className="who-short">Account</span>
      </Link>
      <button className="link-btn" onClick={signOut}>Sign out</button>
    </div>
  );
}

/** Main navigation; admin-only links appear once the session is known. */
export function NavLinks() {
  const me = useMe();
  return (
    <nav>
      <Link href="/">Registry map</Link>
      <Link href="/inspector">Encroachment inspector</Link>
      {me?.role === "ADMIN" && <Link href="/users">Accounts</Link>}
    </nav>
  );
}
