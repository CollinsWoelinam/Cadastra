FROM node:24-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY scripts ./scripts
RUN npm ci
COPY . .
# The basemap is compiled into the browser bundle, so it is chosen at build time.
ARG NEXT_PUBLIC_BASEMAP_TILES=""
ARG NEXT_PUBLIC_BASEMAP_ATTRIBUTION=""
RUN npm run build

# Playwright's image carries the Chromium build that renders certificate PDFs. Its
# version must match the playwright package in package.json.
FROM mcr.microsoft.com/playwright:v1.64.1-noble
WORKDIR /app
ENV NODE_ENV=production PORT=3000 HOSTNAME=0.0.0.0 \
    # Certificate rendering loads the page from this server directly, not via the proxy.
    CERT_RENDER_ORIGIN=http://127.0.0.1:3000
COPY --from=build --chown=pwuser /app/.next/standalone ./
COPY --from=build --chown=pwuser /app/.next/static ./.next/static
COPY --from=build --chown=pwuser /app/public ./public
# File tracing misses data files Playwright reads at runtime (browsers.json), so ship
# both packages whole.
COPY --from=build --chown=pwuser /app/node_modules/playwright ./node_modules/playwright
COPY --from=build --chown=pwuser /app/node_modules/playwright-core ./node_modules/playwright-core
USER pwuser
EXPOSE 3000
CMD ["node", "server.js"]
