#!/bin/bash
# paste-and-run.command
# SQL er allerede i utklippstavlen — bare lim inn og kjør i aktiv Chrome-tab

osascript << 'APPLESCRIPT'
tell application "Google Chrome"
    activate
end tell

delay 1.5

tell application "System Events"
    tell process "Google Chrome"
        -- Velg alt i editoren
        keystroke "a" using command down
        delay 0.5
        -- Lim inn fra utklippstavlen
        keystroke "v" using command down
        delay 1.0
        -- Kjør med Cmd+Enter
        key code 36 using command down
    end tell
end tell

delay 2

display notification "SQL kjørt! Sjekk Supabase for resultater." with title "Vitola DB — Migrasjon 057"
APPLESCRIPT

echo "Ferdig! Lukk dette vinduet og sjekk Supabase."
read -p "Trykk Enter for å lukke..."
