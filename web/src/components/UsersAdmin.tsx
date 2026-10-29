"use client";

import { useEffect, useState } from "react";
import { api, ApiError, type Role, type User } from "@/lib/api";
import { generatePassword } from "@/lib/password";
import { useMe } from "@/components/Session";

const ROLES: { value: Role; label: string; can: string }[] = [
  { value: "SURVEYOR", label: "Surveyor", can: "submits surveys from the field app" },
  { value: "REVIEWER", label: "Reviewer", can: "approves or rejects surveys" },
  { value: "ADMIN", label: "Administrator", can: "everything, including accounts" },
];

type Notice = { ok: boolean; text: string; password?: string };

function formatDate(iso: string | null) {
  return iso ? new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" }) : "Never";
}

export default function UsersAdmin() {
  const me = useMe();
  const isAdmin = me?.role === "ADMIN";
  const [users, setUsers] = useState<User[] | null>(null);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [creating, setCreating] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  useEffect(() => {
    if (isAdmin) api.users().then(setUsers).catch((e) => setNotice({ ok: false, text: String(e.message ?? e) }));
  }, [isAdmin]);

  if (!me) return null;
  if (!isAdmin) {
    return <div className="page"><h1>Accounts</h1><p className="muted">Only administrators can manage accounts.</p></div>;
  }

  function replace(user: User) {
    setUsers((list) => list?.map((u) => (u.id === user.id ? { ...user, last_active_at: u.last_active_at } : u)) ?? null);
  }

  async function update(user: User, patch: Parameters<typeof api.updateUser>[1], success: Notice) {
    setBusyId(user.id);
    setNotice(null);
    try {
      replace(await api.updateUser(user.id, patch));
      setNotice(success);
    } catch (e) {
      setNotice({ ok: false, text: e instanceof ApiError ? e.message : String(e) });
    } finally {
      setBusyId(null);
    }
  }

  function changeRole(user: User, role: Role) {
    const label = ROLES.find((r) => r.value === role)!.label.toLowerCase();
    update(user, { role }, { ok: true, text: `${user.full_name} is now ${label === "administrator" ? "an" : "a"} ${label}.` });
  }

  function toggleActive(user: User) {
    if (user.is_active && !window.confirm(`Deactivate ${user.full_name}? They will be signed out everywhere, ` +
        "including the field app, and cannot sign in until reactivated. Their surveys and decisions are kept.")) return;
    update(user, { is_active: !user.is_active },
      { ok: true, text: `${user.full_name} ${user.is_active ? "deactivated and signed out" : "reactivated"}.` });
  }

  function resetPassword(user: User) {
    if (!window.confirm(`Reset ${user.full_name}'s password? Their current sessions will end.`)) return;
    const password = generatePassword();
    update(user, { password }, { ok: true, text: `New password for ${user.full_name}:`, password });
  }

  const q = query.trim().toLowerCase();
  const shown = (users ?? [])
    .filter((u) => !q || u.full_name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q))
    .sort((a, b) => Number(b.is_active) - Number(a.is_active));

  return (
    <div className="page">
      <div className="page-head">
        <h1>Accounts</h1>
        <button className="btn primary" onClick={() => { setCreating(true); setNotice(null); }} disabled={creating}>
          New account
        </button>
      </div>

      {notice && <NoticeBox notice={notice} onClose={() => setNotice(null)} />}

      {creating && (
        <NewAccount
          onCancel={() => setCreating(false)}
          onCreated={(user, password) => {
            setUsers((list) => [...(list ?? []), { ...user, last_active_at: null }]);
            setCreating(false);
            setNotice({ ok: true, text: `Account created for ${user.full_name} (${user.email}). Password:`, password });
          }}
        />
      )}

      <div className="toolbar">
        <input type="search" placeholder="Search by name or email" value={query} onChange={(e) => setQuery(e.target.value)}
               aria-label="Search accounts" />
        {users && <span className="muted">{users.filter((u) => u.is_active).length} active · {users.length} total</span>}
      </div>

      {users === null ? <p className="muted">Loading…</p> : (
        <div className="table-scroll">
          <table className="data accounts">
            <thead>
              <tr><th>Name</th><th>Role</th><th>Status</th><th>Last active</th><th></th></tr>
            </thead>
            <tbody>
              {shown.map((u) => {
                const self = u.id === me.id;
                const busy = busyId === u.id;
                return (
                  <tr key={u.id} className={u.is_active ? "" : "inactive"}>
                    <td>
                      <div className="name">{u.full_name}{self && <span className="muted"> (you)</span>}</div>
                      <div className="muted">{u.email}</div>
                    </td>
                    <td data-label="Role">
                      <select value={u.role} disabled={self || busy || !u.is_active} aria-label={`Role for ${u.full_name}`}
                              title={self ? "You cannot change your own role" : undefined}
                              onChange={(e) => changeRole(u, e.target.value as Role)}>
                        {ROLES.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
                      </select>
                    </td>
                    <td data-label="Status"><span className={`badge ${u.is_active ? "active" : "disabled"}`}>{u.is_active ? "Active" : "Deactivated"}</span></td>
                    <td className="muted" data-label="Last active">{formatDate(u.last_active_at)}</td>
                    <td>
                      <div className="row-actions">
                      {u.is_active && (
                        <button className="btn small" disabled={busy} onClick={() => resetPassword(u)}>Reset password</button>
                      )}
                      <button className={`btn small ${u.is_active ? "danger-outline" : ""}`} disabled={self || busy}
                              title={self ? "You cannot deactivate yourself" : undefined} onClick={() => toggleActive(u)}>
                        {u.is_active ? "Deactivate" : "Reactivate"}
                      </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
              {shown.length === 0 && <tr><td colSpan={5} className="muted">No accounts match “{query}”.</td></tr>}
            </tbody>
          </table>
        </div>
      )}

      <p className="muted footnote">
        {ROLES.map((r) => <span key={r.value}><strong>{r.label}</strong> {r.can}. </span>)}
        Nobody can review a survey they submitted.
      </p>
    </div>
  );
}

function NoticeBox({ notice, onClose }: { notice: Notice; onClose: () => void }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className={`alert ${notice.ok ? "ok" : ""} notice`} role="status">
      <div>
        {notice.text}
        {notice.password && (
          <>
            {" "}<code className="secret">{notice.password}</code>{" "}
            <button className="link-btn dark" onClick={() => navigator.clipboard.writeText(notice.password!).then(() => setCopied(true))}>
              {copied ? "Copied" : "Copy"}
            </button>
            <div className="hint">
              Give it to them privately; it will not be shown again. They should change it under My account after
              signing in.
            </div>
          </>
        )}
      </div>
      <button className="close" aria-label="Dismiss" onClick={onClose}>×</button>
    </div>
  );
}

function NewAccount({ onCancel, onCreated }: { onCancel: () => void; onCreated: (u: User, password: string) => void }) {
  const [password, setPassword] = useState(generatePassword);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setBusy(true);
    setError(null);
    try {
      const user = await api.createUser({
        full_name: String(form.get("full_name")).trim(),
        email: String(form.get("email")).trim(),
        role: form.get("role") as Role,
        password,
      });
      onCreated(user, password);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : String(err));
      setBusy(false);
    }
  }

  return (
    <form className="card form-grid" onSubmit={submit}>
      <h2>New account</h2>
      <label>Full name<input name="full_name" required maxLength={100} autoFocus /></label>
      <label>Email<input name="email" type="email" required maxLength={254} autoComplete="off" /></label>
      <label>Role
        <select name="role" defaultValue="SURVEYOR">
          {ROLES.map((r) => <option key={r.value} value={r.value}>{r.label} — {r.can}</option>)}
        </select>
      </label>
      <label>Initial password
        <span className="with-button">
          <input value={password} onChange={(e) => setPassword(e.target.value)} minLength={12} maxLength={128} required
                 autoComplete="new-password" spellCheck={false} />
          <button type="button" className="btn" onClick={() => setPassword(generatePassword())}>Generate</button>
        </span>
      </label>
      {error && <div className="alert">{error}</div>}
      <div className="actions">
        <button className="btn primary" type="submit" disabled={busy}>{busy ? "Creating…" : "Create account"}</button>
        <button className="btn" type="button" onClick={onCancel}>Cancel</button>
      </div>
    </form>
  );
}
