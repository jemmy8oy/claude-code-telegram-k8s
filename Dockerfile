FROM python:3.11-slim-bookworm

# 1. Install System Dependencies (Bot, GH CLI, .NET SDK, & Node.js)
RUN apt-get update && apt-get install -y \
  curl git procps ca-certificates build-essential gnupg wget \
  && mkdir -p -m 755 /etc/apt/keyrings \
  # --- GitHub CLI Repo ---
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  # --- .NET SDK Repo (Debian 12 Bookworm) ---
  && wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && rm packages-microsoft-prod.deb \
  # --- Final Install ---
  && apt-get update && apt-get install -y \
  gh \
  dotnet-sdk-8.0 \
  nodejs \
  npm \
  && rm -rf /var/lib/apt/lists/*

# 2. Install Claude Code & Global Frontend Tools
# Adding 'serve' for React builds and ensuring latest npm
RUN npm install -g npm@latest && \
  npm install -g @anthropic-ai/claude-code serve

# 3. Setup the Telegram Bot Source
WORKDIR /app
RUN git clone --depth 1 https://github.com/RichardAtCT/claude-code-telegram.git .

# 4. Install Python Dependencies
# Included pyjwt/cryptography so the bot can handle the .pem handshake
RUN pip install --no-cache-dir poetry \
  && poetry config virtualenvs.create false \
  && poetry install --without dev --no-root \
  && pip install --no-cache-dir "mcp>=0.1.0" "claude-agent-sdk[mcp]>=0.1.0" pyjwt cryptography requests

# 5. Apply your Import Fix
RUN sed -i '1i import sys\nsys.path.insert(0, "/usr/local/lib/python3.11/site-packages")' /app/src/main.py

# 6. PERSISTENT WORKSPACE SETUP
RUN mkdir -p /data/workspace
WORKDIR /data/workspace

ENV PYTHONPATH="/app"
ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["python3", "/app/src/main.py"]
