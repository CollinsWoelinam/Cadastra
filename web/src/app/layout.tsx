import type { Metadata } from "next";
import Link from "next/link";
import { NavLinks, SessionProvider, UserMenu } from "@/components/Session";
import "./globals.css";

export const metadata: Metadata = {
  title: "Cadastra Registry Portal",
  description: "Cadastral mapping, boundary validation and land rights registry",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <SessionProvider>
          <header className="app-nav">
            <Link href="/" className="brand">Cadastra</Link>
            <NavLinks />
            <UserMenu />
          </header>
          <main>{children}</main>
        </SessionProvider>
      </body>
    </html>
  );
}
