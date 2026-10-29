"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";

export default function LoginForm() {
  const next = useSearchParams().get("next");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setBusy(true);
    setError(null);
    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: form.get("email"), password: form.get("password") }),
    }).catch(() => null);
    if (res?.ok) {
      // Full navigation so every component starts with the new session.
      const target = next && next.startsWith("/") && !next.startsWith("//") && !next.startsWith("/\\") ? next : "/";
      window.location.assign(target);
      return;
    }
    setBusy(false);
    setError((await res?.json().catch(() => null))?.detail ?? "Sign-in is unavailable right now.");
  }

  return (
    <form className="login-card" onSubmit={submit}>
      <h1>Cadastra</h1>
      <p className="muted">Sign in to the land registry portal.</p>
      <label>Email<input name="email" type="email" autoComplete="username" required autoFocus /></label>
      <label>Password<input name="password" type="password" autoComplete="current-password" required /></label>
      {error && <div className="alert">{error}</div>}
      <button className="btn primary" type="submit" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
    </form>
  );
}
