"use client";

import { useState } from "react";
import { useMe } from "@/components/Session";
import { initials } from "@/lib/format";
import { CheckCircleIcon, WarningIcon } from "@/components/Icons";

const ROLE_LABEL = { SURVEYOR: "Surveyor", REVIEWER: "Reviewer", ADMIN: "Administrator" } as const;

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
      <div className="page-head"><h1>My account</h1></div>
      <div className="card profile">
        <span className={`avatar lg ${me.role}`}>{initials(me.full_name)}</span>
        <div>
          <div style={{ fontWeight: 600, fontSize: 17 }}>{me.full_name}</div>
          <div className="muted">{me.email} · {ROLE_LABEL[me.role]}</div>
        </div>
      </div>

      <form className="card form-card" onSubmit={submit}>
        <h2>Change password</h2>
        <div className="field"><label htmlFor="cur">Current password</label><input id="cur" name="current_password" type="password" className="input" autoComplete="current-password" required /></div>
        <div className="field"><label htmlFor="new">New password</label><input id="new" name="new_password" type="password" className="input" autoComplete="new-password" minLength={12} maxLength={128} required /></div>
        <div className="field"><label htmlFor="conf">Confirm new password</label><input id="conf" name="confirm" type="password" className="input" autoComplete="new-password" minLength={12} maxLength={128} required /></div>
        <p className="muted" style={{ margin: 0 }}>At least 12 characters. A few unrelated words are easier to remember than symbols.</p>
        {message && (
          <div className={`alert ${message.ok ? "alert-ok" : ""}`} role="status">
            {message.ok ? <CheckCircleIcon color="#0B6E4F" /> : <WarningIcon color="#B42318" />}<span>{message.text}</span>
          </div>
        )}
        <div><button className="btn btn-primary" type="submit" disabled={busy}>{busy ? "Saving…" : "Change password"}</button></div>
      </form>
    </div>
  );
}
