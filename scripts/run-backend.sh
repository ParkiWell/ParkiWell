#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-.env.local}"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${SUPABASE_URL:?Set SUPABASE_URL in .env.local or environment}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY in .env.local or environment}"

BACKEND_PROVIDER="${BACKEND_PROVIDER:-supabase}"
SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-com.parkiwell.app://login-callback/}"

flutter run \
  --dart-define=BACKEND_PROVIDER="$BACKEND_PROVIDER" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  "$@"
