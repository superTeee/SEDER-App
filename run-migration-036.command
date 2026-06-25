#!/bin/bash
# Kjør migrasjon 036: utvid tasting_logs med sub-ratings for 0-100 score
# Åpner Supabase SQL Editor direkte i nettleseren

echo "Åpner Supabase SQL Editor..."
open "https://supabase.com/dashboard/project/wpcricosogcmzebkplwp/sql/new"

echo ""
echo "Lim inn og kjør følgende SQL:"
echo "────────────────────────────────────────────────────────"
cat "$(dirname "$0")/supabase/migrations/036_tasting_logs_extended_rating.sql"
echo ""
echo "────────────────────────────────────────────────────────"
echo "Kopier SQL-en over, lim inn i editoren, og klikk 'Run'."
echo ""
read -p "Trykk Enter for å avslutte..."
