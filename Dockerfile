# ─────────────────────────────────────────────────────────────────────────────
# Atlassian Compat Checker — Production Dockerfile (Render-compatible)
#
# Why bullseye (Debian 11)?
#   node:18-slim was missing critical shared libraries that Chrome needs
#   (libgbm, libasound2, libxss1, etc.), causing "Chrome crashed" errors on
#   Render. Using bullseye-slim gives us access to the 'chromium' apt package
#   which pulls in ALL its dependencies automatically.
#
# Strategy: install OS-provided Chromium, skip Puppeteer's own Chrome
#   download, then point Puppeteer at /usr/bin/chromium via env vars.
# ─────────────────────────────────────────────────────────────────────────────

FROM node:20-bullseye-slim

# 1. Install Chromium + all shared libraries it requires + fonts
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-freefont-ttf \
    libxss1 \
    libgbm1 \
    libasound2 \
    --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# 2. Tell Puppeteer to use the system Chromium instead of downloading its own
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# 3. Set working directory
WORKDIR /app

# 4. Install Node dependencies
#    postinstall ("npx puppeteer browsers install chrome") is safely skipped
#    because PUPPETEER_SKIP_DOWNLOAD=true is already set above.
COPY package*.json ./
RUN npm ci --omit=dev

# 5. Copy application source
COPY . .

# 6. Expose port (Render overrides this with its own PORT env var)
EXPOSE 3000

# 7. Start
CMD ["npm", "start"]