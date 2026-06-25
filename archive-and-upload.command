#!/bin/bash
# Bygg og arkiver Vitola build 35 (OCR-strip: HABANA, CUBA, Desde)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT="$PROJECT_DIR/iOS/Vitola.xcodeproj"
ARCHIVE_PATH="/tmp/Vitola_build35.xcarchive"
EXPORT_PATH="/tmp/Vitola_build35_export"

echo "📁 Prosjekt: $PROJECT_DIR"
echo "🔨 Arkiverer build 35 (CURRENT_PROJECT_VERSION=35)..."
echo ""

/usr/bin/xcodebuild archive \
  -project "$XCODE_PROJECT" \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | grep -E "error:|warning:|Archive|BUILD|Compiling|Linking|archive"

if [ $? -ne 0 ]; then
  echo "❌ Arkivering feilet!"
  read -p "Trykk Enter for å avslutte..."; exit 1
fi

echo ""
echo "✅ Arkiv klart: $ARCHIVE_PATH"
echo "🚀 Åpner Organizer i Xcode for opplasting..."

# Åpne arkivet i Xcode Organizer
open "$ARCHIVE_PATH"

echo ""
echo "Klikk 'Distribute App' i Xcode Organizer for å laste opp til TestFlight."
read -p "Trykk Enter for å avslutte..."
