#!/bin/bash
# Deploy scan-cigar Edge Function v18 (25s OpenAI timeout)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPABASE_CLI=""

# Finn Supabase CLI
for path in /opt/homebrew/bin/supabase /usr/local/bin/supabase ~/.supabase/bin/supabase; do
  if [ -f "$path" ]; then
    SUPABASE_CLI="$path"
    break
  fi
done

if [ -z "$SUPABASE_CLI" ]; then
  echo "❌ Supabase CLI ikke funnet. Installer med: brew install supabase/tap/supabase"
  read -p "Trykk Enter for å avslutte..."
  exit 1
fi

echo "✅ Supabase CLI: $SUPABASE_CLI"
echo "📁 Prosjekt: $PROJECT_DIR"

echo "🚀 Deployer scan-cigar (v18 — 25s OpenAI timeout)..."
cd "$PROJECT_DIR"
"$SUPABASE_CLI" functions deploy scan-cigar --project-ref wpcricosogcmzebkplwp --use-api

echo ""
echo "✅ scan-cigar v18 deployed!"
read -p "Trykk Enter for å avslutte..."
