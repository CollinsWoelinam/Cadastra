import type { Metadata } from "next";
import Link from "next/link";
import { SessionProvider, UserMenu } from "@/components/Session";
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
            <nav>
              <Link href="/">Registry map</Link>
              <Link href="/inspector">Encroachment inspector</Link>
            </nav>
            <UserMenu />
          </header>
          <main>{children}</main>
        </SessionProvider>
      </body>
    </html>
  );
}
