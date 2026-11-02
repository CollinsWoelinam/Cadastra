import VerifyForm from "@/components/VerifyForm";
import { VerifyExplainer } from "@/components/VerifyResult";

export const metadata = { title: "Verify a certificate · Cadastra" };

export default function VerifyPage() {
  return (
    <div className="page verify">
      <div className="page-head">
        <div>
          <h1>Verify a land certificate</h1>
          <p>Scan the QR code on a Cadastra survey certificate, or type the code printed beside it.</p>
        </div>
      </div>
      <section className="card verify-again"><VerifyForm /></section>
      <VerifyExplainer />
    </div>
  );
}
