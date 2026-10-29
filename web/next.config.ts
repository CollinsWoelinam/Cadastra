import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Self-contained server bundle for the production container (see Dockerfile).
  output: "standalone",
  cacheComponents: true,
  partialPrefetching: true,
  serverExternalPackages: ["playwright", "playwright-core"],
};

export default nextConfig;
