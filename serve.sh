#!/usr/bin/env bash
# Run FreeLLMAPI in production mode without Docker.
#
#   ./serve.sh            install deps (if needed), build, then start on $PORT (default 3001)
#   SKIP_BUILD=1 ./serve.sh   start from an existing build
#
# Secrets are never stored here: ENCRYPTION_KEY must come from the environment
# or from a local, git-ignored .env file (see .env.example).
set -euo pipefail

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

export NODE_ENV=production
export PORT="${PORT:-3001}"

if [ -z "${ENCRYPTION_KEY:-}" ] || [ "${ENCRYPTION_KEY}" = "your-64-char-hex-key-here" ]; then
  echo "serve.sh: ENCRYPTION_KEY is not set (64 hex chars required in production)." >&2
  echo "  generate one: node -e \"console.log(require('crypto').randomBytes(32).toString('hex'))\"" >&2
  echo "  then export it, or put ENCRYPTION_KEY=... in .env (never commit it)." >&2
  exit 1
fi

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  [ -d node_modules ] || npm ci
  npm run build
fi

echo "serve.sh: starting FreeLLMAPI on port ${PORT} (health: /api/ping)"
exec node server/dist/index.js
