import { Suspense } from "react";
import Inspector from "@/components/Inspector";

export default function InspectorPage() {
  return (
    <Suspense>
      <Inspector />
    </Suspense>
  );
}
