"use client";

import { useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { EyeIcon, EyeOffIcon, InfoIcon, QrIcon, WarningIcon } from "@/components/Icons";

export default function LoginForm() {
  const next = useSearchParams().get("next");
  const [error, setError] = useState<{ text: string; throttled: boolean } | null>(null);
  const [busy, setBusy] = useState(false);
  const [reveal, setReveal] = useState(false);

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
    const detail = (await res?.json().catch(() => null))?.detail ?? "Sign-in is unavailable right now.";
    setError({ text: detail, throttled: res?.status === 429 });
  }

  return (
    <form className="login-form" onSubmit={submit}>
      <div>
        <h2>Sign in</h2>
        <p className="lead">Use the account your registry administrator gave you.</p>
      </div>
      <div className="field">
        <label htmlFor="email">Email</label>
        <input id="email" name="email" type="email" className="input" autoComplete="username" required autoFocus
               style={{ minHeight: 50, fontSize: 16 }} />
      </div>
      <div className="field">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 12, flexWrap: "wrap" }}>
          <label htmlFor="password" className="field-label">Password</label>
          <span className="muted">Forgotten? Ask your administrator.</span>
        </div>
        <div className="password-box">
          <input id="password" name="password" type={reveal ? "text" : "password"} autoComplete="current-password" required />
          <button type="button" className="icon-btn" aria-label={reveal ? "Hide password" : "Show password"}
                  aria-pressed={reveal} onClick={() => setReveal((r) => !r)}>
            {reveal ? <EyeOffIcon size={20} color="#3E4C47" /> : <EyeIcon size={20} color="#3E4C47" />}
          </button>
        </div>
      </div>
      {error && (
        <div className={`alert ${error.throttled ? "alert-warn" : ""}`} role="alert">
          {error.throttled ? <InfoIcon color="#9A5B05" /> : <WarningIcon color="#B42318" />}
          <span>{error.text}</span>
        </div>
      )}
      <button className="btn btn-primary btn-lg" type="submit" disabled={busy} style={{ minHeight: 52 }}>
        {busy ? "Signing in…" : "Sign in"}
      </button>
      <div className="login-aside">
        <QrIcon size={20} color="#0B6E4F" />
        <span>Checking a certificate? <Link href="/verify" style={{ fontWeight: 600 }}>Verify it here</Link>, no account needed.</span>
      </div>
    </form>
  );
}
