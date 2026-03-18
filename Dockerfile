# Use a stable Python base
FROM python:3.11-slim-bookworm

# Install Node.js, Git, and Certificates
RUN apt-get update && apt-get install -y \
  curl git procps nodejs npm ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Setup the Telegram Bot wrapper
WORKDIR /app
RUN git clone https://github.com/RichardAtCT/claude-code-telegram.git . \
  && pip install --no-cache-dir poetry \
  && poetry config virtualenvs.create false \
  && poetry install --without dev

# Final Workspace Setup
RUN mkdir /workspace
WORKDIR /workspace

# Start the bot
ENTRYPOINT ["python", "/app/src/main.py"]
