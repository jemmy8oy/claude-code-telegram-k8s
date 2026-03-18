# Use a stable Python base
FROM python:3.11-slim-bookworm

# Install System Dependencies
RUN apt-get update && apt-get install -y \
  curl git procps nodejs npm ca-certificates build-essential \
  && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Setup the Telegram Bot wrapper
WORKDIR /app

# CLONE AND INSTALL
# We install the SDK with [mcp] extras to fix the 'mcp.types' error
RUN git clone --depth 1 https://github.com/RichardAtCT/claude-code-telegram.git . \
  && pip install --no-cache-dir poetry \
  && pip install --no-cache-dir "claude-agent-sdk[mcp]" "mcp>=0.1.0" \
  && poetry config virtualenvs.create false \
  && poetry install --without dev \
  && rm -rf /root/.cache/pip /root/.cache/pypoetry

# Final Workspace Setup
RUN mkdir -p /workspace
WORKDIR /workspace

# Start the bot
ENTRYPOINT ["python", "/app/src/main.py"]
