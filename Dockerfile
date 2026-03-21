FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y \
  curl git procps nodejs npm ca-certificates build-essential \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app
RUN git clone --depth 1 https://github.com/RichardAtCT/claude-code-telegram.git .

# Install dependencies WITHOUT installing the 'src' package itself
RUN pip install --no-cache-dir poetry \
  && poetry config virtualenvs.create false \
  && poetry install --without dev --no-root \
  && pip install --no-cache-dir "mcp>=0.1.0" "claude-agent-sdk[mcp]>=0.1.0"

# BAKE THE IMPORT FIX INTO THE FILE
RUN sed -i '1i import sys\nsys.path.insert(0, "/usr/local/lib/python3.11/site-packages")' /app/src/main.py

ENV PYTHONPATH="/app"
ENV PYTHONUNBUFFERED=1

RUN mkdir -p /workspace
WORKDIR /workspace

ENTRYPOINT ["python3", "/app/src/main.py"]
