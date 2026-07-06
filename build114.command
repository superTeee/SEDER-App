#!/bin/bash
set -e
cd "$(dirname "$0")/iOS"

echo "================================================"
echo "  Vitola build 114 — Google Sign-In fix"
echo "================================================"
echo ""

# Regenerer xcodeproj
echo "▶ Kjører xcodegen..."
/opt/homebrew/bin/xcodegen generate
echo "✓ xcodeproj regenerert"
echo ""

# Arkiver
ARCHIVE_PATH="/tmp/Vitola_build114.xcarchive"
echo "▶ Arkiverer (dette tar ~2 min)..."
xcodebuild archive \
  -project Vitola.xcodeproj \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | grep -E "error:|BUILD|Compiling|Linking|archive|warning: " | grep -v "warning: "

echo ""
echo "✓ Arkiv klart: $ARCHIVE_PATH"
echo ""

# Last opp
echo "▶ Laster opp til App Store Connect..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist /tmp/vitola_export114.plist \
  -exportPath /tmp/Vitola_build114_export 2>/dev/null || true

# Åpne i Organizer for manuell opplasting
echo "▶ Åpner arkivet i Xcode Organizer..."
open "$ARCHIVE_PATH"

echo ""
echo "✓ Ferdig! Klikk 'Distribute App' i Xcode Organizer."
read -p "Trykk Enter for å lukke..."
