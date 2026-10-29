"use client";

import { useState } from "react";
import { useMe } from "@/components/Session";

export default function AccountForm() {
  const me = useMe();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formEl = e.currentTarget;
    const form = new FormData(formEl);
    const next = String(form.get("new_password"));
    if (next !== form.get("confirm")) return setMessage({ ok: false, text: "The new passwords do not match." });
    setBusy(true);
    setMessage(null);
    const res = await fetch("/api/auth/password", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ current_password: form.get("current_password"), new_password: next }),
    }).catch(() => null);
    setBusy(false);
    if (res?.ok) {
      formEl.reset();
      setMessage({ ok: true, text: "Password changed. You have been signed out everywhere else, including the field app." });
    } else {
      setMessage({ ok: false, text: (await res?.json().catch(() => null))?.detail ?? "The registry is unavailable right now." });
    }
  }

  if (!me) return null;
  return (
    <div className="page narrow">
      <h1>My account</h1>
      <dl className="props card">
        <dt>Name</dt><dd>{me.full_name}</dd>
        <dt>Email</dt><dd>{me.email}</dd>
        <dt>Role</dt><dd className="role">{me.role.toLowerCase()}</dd>
      </dl>

      <form className="card form-grid" onSubmit={submit}>
        <h2>Change password</h2>
        <label>Current password<input name="current_password" type="password" autoComplete="current-password" required /></label>
        <label>New password<input name="new_password" type="password" autoComplete="new-password" minLength={12} maxLength={128} required /></label>
        <label>Confirm new password<input name="confirm" type="password" autoComplete="new-password" minLength={12} maxLength={128} required /></label>
        <p className="muted">At least 12 characters. A few unrelated words is easier to remember than symbols.</p>
        {message && <div className={`alert ${message.ok ? "ok" : ""}`}>{message.text}</div>}
        <div className="actions">
          <button className="btn primary" type="submit" disabled={busy}>{busy ? "Saving…" : "Change password"}</button>
        </div>
      </form>
    </div>
  );
}
