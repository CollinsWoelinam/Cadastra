"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

/** Looks up a certificate by the code printed beside its QR code. */
export default function VerifyForm({ initial = "" }: { initial?: string }) {
  const router = useRouter();
  const [code, setCode] = useState(initial);
  return (
    <form className="verify-form" onSubmit={(e) => {
      e.preventDefault();
      const clean = code.trim().toUpperCase();
      if (clean) router.push(`/verify/${encodeURIComponent(clean)}`);
    }}>
      <div className="field" style={{ flex: "1 1 220px" }}>
        <label htmlFor="code">Verification code</label>
        <input id="code" className="input mono" placeholder="CDX-XXXX-XXXX" autoComplete="off" spellCheck={false}
               value={code} onChange={(e) => setCode(e.target.value)} style={{ fontSize: 17, letterSpacing: "0.06em", minHeight: 50 }} />
      </div>
      <button type="submit" className="btn btn-primary btn-lg">Verify</button>
    </form>
  );
}
