import { Suspense } from "react";
import LoginForm from "@/components/LoginForm";
import { BrandMark } from "@/components/Icons";

export default function LoginPage() {
  return (
    <div className="login">
      <section className="login-hero" aria-label="About Cadastra">
        <svg className="backdrop" aria-hidden="true" viewBox="0 0 720 900" preserveAspectRatio="xMidYMid slice">
          <g fill="none" stroke="#1F3A31" strokeWidth="1.4">
            <path d="M-40 640 C 160 600, 360 560, 760 470" /><path d="M-40 680 C 160 640, 360 600, 760 510" />
            <path d="M120 -20 L 170 920" /><path d="M-20 160 L 760 110" />
          </g>
          <g transform="translate(160 -40)">
          <g transform="rotate(-5 420 360)" fill="none" stroke="#2C5446" strokeWidth="1.6">
            <rect x="250" y="200" width="110" height="130" /><rect x="364" y="200" width="110" height="130" />
            <rect x="478" y="200" width="110" height="130" /><rect x="592" y="200" width="110" height="130" />
            <rect x="250" y="334" width="110" height="130" /><rect x="478" y="334" width="110" height="130" />
            <rect x="592" y="334" width="110" height="130" /><rect x="250" y="468" width="110" height="110" />
            <rect x="364" y="468" width="110" height="110" /><rect x="592" y="468" width="110" height="110" />
          </g>
          <g transform="rotate(-5 420 360)">
            <rect x="364" y="334" width="110" height="130" fill="#0B6E4F" fillOpacity="0.35" stroke="#E0A526" strokeWidth="2.5" />
            <g fill="#0F1B17" stroke="#E0A526" strokeWidth="2">
              <circle cx="364" cy="334" r="6" /><circle cx="474" cy="334" r="6" /><circle cx="474" cy="464" r="6" /><circle cx="364" cy="464" r="6" />
            </g>
          </g>
          </g>
        </svg>
        <div className="brand"><BrandMark size={36} /><span className="brand-name" style={{ fontSize: 22 }}>Cadastra</span></div>
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <h1>Every boundary surveyed, checked and on record.</h1>
          <p>The registry portal for reviewing field surveys, catching encroachments before they are approved, and issuing survey plans.</p>
          <ul className="login-points">
            <li>Overlap checks against every approved parcel</li>
            <li>Ghana National Grid and Ghana Metre Grid plans</li>
            <li>A full audit trail of who surveyed and who decided</li>
          </ul>
        </div>
        <p style={{ fontSize: 13, color: "var(--nav-muted)" }}>Lands Registry · Ghana</p>
      </section>
      <div className="login-main">
        <Suspense>
          <LoginForm />
        </Suspense>
      </div>
    </div>
  );
}
