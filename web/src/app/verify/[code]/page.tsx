import { Suspense } from "react";
import VerifyResult from "@/components/VerifyResult";

export const metadata = { title: "Certificate verification · Cadastra" };

export default function VerifyCodePage({ params }: PageProps<"/verify/[code]">) {
  return (
    <div className="page verify">
      <Suspense fallback={<p className="muted">Checking the registry…</p>}>
        <VerifyResult params={params} />
      </Suspense>
    </div>
  );
}
