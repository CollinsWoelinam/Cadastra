import type { NextConfig } from "next";

const CORE_API_URL = process.env.CORE_API_URL ?? "http://localhost:8000";

const nextConfig: NextConfig = {
  cacheComponents: true,
  partialPrefetching: true,
  serverExternalPackages: ["playwright", "playwright-core"],
  // Browser talks to the Core Engine through this origin, so no CORS setup is needed.
  rewrites() {
    return [{ source: "/core/:path*", destination: `${CORE_API_URL}/:path*` }];
  },
};

export default nextConfig;
