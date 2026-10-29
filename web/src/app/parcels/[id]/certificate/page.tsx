import { Suspense } from "react";
import Certificate from "@/components/Certificate";

export default function CertificatePage({ params }: PageProps<"/parcels/[id]/certificate">) {
  return (
    <Suspense>
      <Certificate params={params} />
    </Suspense>
  );
}
