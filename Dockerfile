FROM python:3.11-slim-bookworm

# 1. Base Utilities
RUN apt-get update && apt-get install -y \
  curl git procps ca-certificates build-essential gnupg wget \
  && rm -rf /var/lib/apt/lists/*

# 2. Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 3. Install GH, Node, and dependencies for .NET
RUN apt-get update && apt-get install -y \
  gh \
  nodejs \
  npm \
  libicu-dev \
  && rm -rf /var/lib/apt/lists/*

# 4. Install .NET SDK via Official Script
# This works for both amd64 and arm64
RUN curl -dot-net -fsSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version latest --channel 8.0 --install-dir /usr/local/bin

# Ensure dotnet is in the PATH
ENV PATH="${PATH}:/usr/local/bin"
# Trigger first-run experience to populate local package cache
RUN dotnet --version

# 5. Install Claude Code & Tools
RUN npm install -g @anthropic-ai/claude-code serve

# 6. Setup the Telegram Bot Source
WORKDIR /app
RUN git clone --depth 1 https://github.com/RichardAtCT/claude-code-telegram.git .

# 7. Install Python Dependencies
# Included pyjwt/cryptography so the bot can handle the .pem handshake
RUN pip install --no-cache-dir poetry \
  && poetry config virtualenvs.create false \
  && poetry install --without dev --no-root \
  && pip install --no-cache-dir "mcp>=0.1.0" "claude-agent-sdk[mcp]>=0.1.0" pyjwt cryptography requests

# 8. Apply your Import Fix
RUN sed -i '1i import sys\nsys.path.insert(0, "/usr/local/lib/python3.11/site-packages")' /app/src/main.py

# 9. PERSISTENT WORKSPACE SETUP
RUN mkdir -p /data/workspace
WORKDIR /data/workspace

ENV PYTHONPATH="/app"
ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["python3", "/app/src/main.py"]
