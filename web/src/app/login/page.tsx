import { Suspense } from "react";
import LoginForm from "@/components/LoginForm";

export default function LoginPage() {
  return (
    <div className="login-page">
      <Suspense>
        <LoginForm />
      </Suspense>
    </div>
  );
}
