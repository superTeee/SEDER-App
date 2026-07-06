#!/bin/bash
set -eo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT="$PROJECT_DIR/iOS/Vitola.xcodeproj"
ARCHIVE_PATH="/tmp/Vitola_build68.xcarchive"
LOG="/tmp/build68.log"

echo "🔨 Arkiverer build 68..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild archive \
  -project "$XCODE_PROJECT" \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | tee "$LOG" | grep -E "error:|warning:|BUILD|Archive|Compiling|Linking|FAILED|succeeded" || true

if [ ! -d "$ARCHIVE_PATH" ]; then
  echo ""
  echo "❌ FEIL: Arkivet ble ikke opprettet. Siste 30 linjer av loggen:"
  tail -30 "$LOG"
  exit 1
fi

echo ""
echo "✅ Arkiv klart — åpner i Xcode Organizer..."
open "$ARCHIVE_PATH"
read -p "Trykk Enter for å avslutte..."
