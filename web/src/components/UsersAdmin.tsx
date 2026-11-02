"use client";

import { useEffect, useState } from "react";
import { api, ApiError, type Role, type User } from "@/lib/api";
import { formatWhen, initials } from "@/lib/format";
import { generatePassword } from "@/lib/password";
import { useMe } from "@/components/Session";
import { CheckCircleIcon, PlusIcon, SearchIcon, WarningIcon } from "@/components/Icons";

const ROLES: { value: Role; label: string; plural: string; can: string }[] = [
  { value: "SURVEYOR", label: "Surveyor", plural: "Surveyors", can: "submits surveys from the field app" },
  { value: "REVIEWER", label: "Reviewer", plural: "Reviewers", can: "approves or rejects surveys" },
  { value: "ADMIN", label: "Administrator", plural: "Admins", can: "everything, including accounts" },
];

type Filter = "ALL" | Role | "INACTIVE";
type Notice = { ok: boolean; text: string; password?: string };

export default function UsersAdmin() {
  const me = useMe();
  const isAdmin = me?.role === "ADMIN";
  const [users, setUsers] = useState<User[] | null>(null);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [creating, setCreating] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<Filter>("ALL");

  useEffect(() => {
    if (isAdmin) api.users().then(setUsers).catch((e) => setNotice({ ok: false, text: String(e.message ?? e) }));
  }, [isAdmin]);

  if (!me) return null;
  if (!isAdmin) {
    return <div className="page"><div className="page-head"><h1>Accounts</h1></div><p className="muted">Only administrators can manage accounts.</p></div>;
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
    update(user, { password }, { ok: true, text: `New password for ${user.full_name}.`, password });
  }

  const all = users ?? [];
  const counts: Record<Filter, number> = {
    ALL: all.length,
    SURVEYOR: all.filter((u) => u.is_active && u.role === "SURVEYOR").length,
    REVIEWER: all.filter((u) => u.is_active && u.role === "REVIEWER").length,
    ADMIN: all.filter((u) => u.is_active && u.role === "ADMIN").length,
    INACTIVE: all.filter((u) => !u.is_active).length,
  };
  const tabs: { key: Filter; label: string }[] = [
    { key: "ALL", label: "All" },
    ...ROLES.map((r) => ({ key: r.value as Filter, label: r.plural })),
    { key: "INACTIVE", label: "Deactivated" },
  ];
  const q = query.trim().toLowerCase();
  const shown = all
    .filter((u) => filter === "ALL" || (filter === "INACTIVE" ? !u.is_active : u.is_active && u.role === filter))
    .filter((u) => !q || u.full_name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q))
    .sort((a, b) => Number(b.is_active) - Number(a.is_active));

  return (
    <div className="page">
      <div className="page-head">
        <div>
          <h1>Accounts</h1>
          <p>Who can survey, review and administer the registry.</p>
        </div>
        <button type="button" className="btn btn-primary btn-lg" onClick={() => { setCreating(true); setNotice(null); }} disabled={creating}>
          <PlusIcon color="#fff" />New account
        </button>
      </div>

      {notice && <NoticeBox notice={notice} onClose={() => setNotice(null)} />}

      {creating && (
        <NewAccount
          onCancel={() => setCreating(false)}
          onCreated={(user, password) => {
            setUsers((list) => [...(list ?? []), { ...user, last_active_at: null }]);
            setCreating(false);
            setNotice({ ok: true, text: `Account created for ${user.full_name}.`, password });
          }}
        />
      )}

      <div className="toolbar">
        <div className="tabs" role="tablist" aria-label="Filter accounts">
          {tabs.map((t) => (
            <button key={t.key} type="button" role="tab" className="tab" aria-selected={filter === t.key} onClick={() => setFilter(t.key)}>
              {t.label} · {counts[t.key]}
            </button>
          ))}
        </div>
        <label className="search-box">
          <SearchIcon color="#5A6862" />
          <span className="visually-hidden">Search accounts</span>
          <input type="search" placeholder="Search name or email" value={query} onChange={(e) => setQuery(e.target.value)} />
        </label>
      </div>

      {users === null ? <p className="muted">Loading…</p> : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr><th scope="col">Person</th><th scope="col">Role</th><th scope="col">Status</th><th scope="col">Last active</th><th scope="col"><span className="visually-hidden">Actions</span></th></tr>
            </thead>
            <tbody>
              {shown.map((u) => {
                const self = u.id === me.id;
                const busy = busyId === u.id;
                return (
                  <tr key={u.id} className={u.is_active ? "" : "inactive"}>
                    <td>
                      <div className="person">
                        <span className={`avatar lg ${u.is_active ? u.role : "inactive"}`}>{initials(u.full_name)}</span>
                        <span>
                          <span className="person-name">{u.full_name}{self && <span className="muted" style={{ fontWeight: 400 }}>(you)</span>}
                            {u.is_active && !u.last_active_at && <span className="pill pill-new">New</span>}</span>
                          <span className="person-email">{u.email}</span>
                        </span>
                      </div>
                    </td>
                    <td data-label="Role">
                      {u.is_active ? (
                        <select className="select" value={u.role} disabled={self || busy} aria-label={`Role for ${u.full_name}`}
                                title={self ? "You cannot change your own role" : undefined}
                                onChange={(e) => changeRole(u, e.target.value as Role)}>
                          {ROLES.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
                        </select>
                      ) : <span className="muted">{ROLES.find((r) => r.value === u.role)?.label}</span>}
                    </td>
                    <td data-label="Status">
                      <span className="status-text" style={{ color: u.is_active ? "var(--green-ink)" : "var(--muted)" }}>
                        <span className={`dot ${u.is_active ? "dot-green" : ""}`} />{u.is_active ? "Active" : "Deactivated"}
                      </span>
                    </td>
                    <td data-label="Last active" style={{ color: "var(--ink-2)" }}>
                      {self ? "Now" : u.last_active_at ? formatWhen(u.last_active_at) : "Never signed in"}
                    </td>
                    <td>
                      <div className="row-actions">
                        {self ? <span className="muted">Your own role and access are locked</span> : (
                          <>
                            {u.is_active && <button type="button" className="btn btn-sm" disabled={busy} onClick={() => resetPassword(u)}>Reset password</button>}
                            <button type="button" className={`btn btn-sm ${u.is_active ? "btn-danger-outline" : "btn-green-outline"}`}
                                    disabled={busy} onClick={() => toggleActive(u)}>
                              {u.is_active ? "Deactivate" : "Reactivate"}
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
              {shown.length === 0 && <tr><td colSpan={5} className="muted">No accounts match.</td></tr>}
            </tbody>
          </table>
        </div>
      )}

      <p className="footnote">
        <strong>Surveyors</strong> submit boundaries from the field app. <strong>Reviewers</strong> approve or reject
        them. <strong>Administrators</strong> can also manage accounts. Nobody can review a survey they submitted.
      </p>
    </div>
  );
}

function NoticeBox({ notice, onClose }: { notice: Notice; onClose: () => void }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className={`notice ${notice.ok ? "" : "error"}`} role="status">
      {notice.ok ? <CheckCircleIcon size={22} color="#0B6E4F" /> : <WarningIcon size={22} color="#B42318" />}
      <div className="notice-text">
        <strong>{notice.text}</strong>
        {notice.password && " Give it to them privately; it will not be shown again. They should change it under My account after signing in."}
      </div>
      {notice.password && (
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <code className="secret">{notice.password}</code>
          <button type="button" className="btn btn-sm btn-green-outline" onClick={() => navigator.clipboard.writeText(notice.password!).then(() => setCopied(true))}>
            {copied ? "Copied" : "Copy"}
          </button>
        </div>
      )}
      <button type="button" className="notice-close" aria-label="Dismiss" onClick={onClose}>×</button>
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
    <form className="card form-card" onSubmit={submit}>
      <h2>New account</h2>
      <div className="field"><label htmlFor="na-name">Full name</label><input id="na-name" name="full_name" className="input" required maxLength={100} autoFocus /></div>
      <div className="field"><label htmlFor="na-email">Email</label><input id="na-email" name="email" type="email" className="input" required maxLength={254} autoComplete="off" /></div>
      <div className="field">
        <label htmlFor="na-role">Role</label>
        <select id="na-role" name="role" className="select" defaultValue="SURVEYOR" style={{ minHeight: 46, fontSize: 15 }}>
          {ROLES.map((r) => <option key={r.value} value={r.value}>{r.label} — {r.can}</option>)}
        </select>
      </div>
      <div className="field">
        <label htmlFor="na-pw">Initial password</label>
        <span className="with-button">
          <input id="na-pw" className="input" value={password} onChange={(e) => setPassword(e.target.value)} minLength={12} maxLength={128}
                 required autoComplete="new-password" spellCheck={false} />
          <button type="button" className="btn" onClick={() => setPassword(generatePassword())}>Generate</button>
        </span>
      </div>
      {error && <div className="alert" role="alert"><WarningIcon color="#B42318" /><span>{error}</span></div>}
      <div className="btn-row" style={{ maxWidth: 360 }}>
        <button className="btn btn-primary" type="submit" disabled={busy}>{busy ? "Creating…" : "Create account"}</button>
        <button className="btn" type="button" onClick={onCancel}>Cancel</button>
      </div>
    </form>
  );
}
