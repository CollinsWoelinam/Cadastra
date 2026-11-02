import { Suspense } from "react";
import type { Metadata } from "next";
import { IBM_Plex_Mono, IBM_Plex_Sans } from "next/font/google";
import AppHeader from "@/components/AppHeader";
import { SessionProvider } from "@/components/Session";
import "./globals.css";

const plexSans = IBM_Plex_Sans({ subsets: ["latin"], weight: ["400", "500", "600", "700"], variable: "--font-plex-sans" });
const plexMono = IBM_Plex_Mono({ subsets: ["latin"], weight: ["400", "500"], variable: "--font-plex-mono" });

export const metadata: Metadata = {
  title: "Cadastra Registry Portal",
  description: "Cadastral mapping, boundary validation and land rights registry",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${plexSans.variable} ${plexMono.variable}`}>
      <body>
        <SessionProvider>
          {/* The header reads the current path; the empty bar keeps the layout steady meanwhile. */}
          <Suspense fallback={<div className="app-header" aria-hidden="true" />}>
            <AppHeader />
          </Suspense>
          <main>{children}</main>
        </SessionProvider>
      </body>
    </html>
  );
}
