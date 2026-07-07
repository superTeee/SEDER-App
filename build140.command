#!/bin/bash
set -e
cd "$(dirname "$0")/iOS"

echo "================================================"
echo "  Vitola build 140 — Smakstilpasset Dagens utvalgte"
echo "================================================"
echo ""

# Regenerer xcodeproj fra project.yml
echo "▶ Kjører xcodegen..."
/opt/homebrew/bin/xcodegen generate
echo "✓ xcodeproj regenerert"
echo ""

# Arkiver
ARCHIVE_PATH="/tmp/Vitola_build140.xcarchive"
echo "▶ Arkiverer (dette tar ~2 min)..."
xcodebuild archive \
  -project Vitola.xcodeproj \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED|Compiling|Linking|archive"

echo ""
echo "✓ Arkiv klart: $ARCHIVE_PATH"
echo ""

# Åpne arkivet i Xcode Organizer for opplasting
echo "▶ Åpner arkivet i Xcode Organizer..."
open "$ARCHIVE_PATH"

echo ""
echo "✓ Ferdig! Klikk 'Distribute App' i Xcode Organizer for TestFlight."
read -p "Trykk Enter for å lukke..."
