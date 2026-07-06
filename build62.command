#!/bin/bash
# Bygg og arkiver Vitola build 62 (ingen Venner-tab, ingen del-knapp)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT="$PROJECT_DIR/iOS/Vitola.xcodeproj"
ARCHIVE_PATH="/tmp/Vitola_build62.xcarchive"

echo "📁 Prosjekt: $PROJECT_DIR"
echo "🔨 Arkiverer build 62..."
echo ""

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild archive \
  -project "$XCODE_PROJECT" \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | grep -E "error:|warning:|Archive|BUILD|Compiling|Linking|archive|FAILED|succeeded"

echo ""
echo "✅ Arkiv klart: $ARCHIVE_PATH"
echo "🚀 Åpner i Xcode Organizer for opplasting til TestFlight..."

open "$ARCHIVE_PATH"

echo ""
echo "Klikk 'Distribute App' i Xcode Organizer → TestFlight."
read -p "Trykk Enter for å avslutte..."
