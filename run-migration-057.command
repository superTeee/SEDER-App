#!/bin/bash
# Migrasjon 057: Fermin Perez Premium Cigars
# Bruker AppleScript for å sette inn SQL direkte i Supabase SQL Editor

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_FILE="$SCRIPT_DIR/supabase/migrations/057_fermin_perez_seed.sql"

echo "Kopierer SQL til utklippstavlen..."
cat "$SQL_FILE" | pbcopy

echo "Åpner ny Supabase SQL Editor-fane..."
open "https://supabase.com/dashboard/project/wpcricosogcmzebkplwp/sql/new"

echo "Venter på at siden laster (10 sekunder)..."
sleep 10

echo "Limer inn og kjører SQL via AppleScript..."
osascript << 'APPLESCRIPT'
tell application "Google Chrome"
    activate
end tell

delay 2

tell application "System Events"
    tell process "Google Chrome"
        -- Velg alt innhold i editoren og lim inn
        keystroke "a" using command down
        delay 0.3
        keystroke "v" using command down
        delay 1
        -- Kjør med Cmd+Enter
        key code 36 using command down
    end tell
end tell

delay 3

-- Sjekk om det er en feil ved å ta bilde (valgfri notifikasjon)
display notification "Migrasjon 057 kjørt! Sjekk Supabase for resultater." with title "Vitola DB"
APPLESCRIPT

echo ""
echo "Ferdig! Sjekk Chrome — Supabase SQL Editor skal vise resultater."
read -p "Trykk Enter for å lukke dette vinduet..."
