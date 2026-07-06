#!/bin/bash
set -e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT="$PROJECT_DIR/iOS/Vitola.xcodeproj"
ARCHIVE_PATH="/tmp/Vitola_build67.xcarchive"

echo "🔨 Arkiverer build 67 (ønskeliste)..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild archive \
  -project "$XCODE_PROJECT" \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | grep -E "error:|warning:|Archive|BUILD|Compiling|Linking|archive|FAILED|succeeded"

echo "✅ Arkiv klart — åpner i Xcode Organizer..."
open "$ARCHIVE_PATH"
read -p "Trykk Enter for å avslutte..."
