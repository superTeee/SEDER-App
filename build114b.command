#!/bin/bash
set -e
cd "$(dirname "$0")/iOS"

echo "================================================"
echo "  Vitola build 114 — Google Sign-In fix"
echo "================================================"
echo ""

# Pek xcode-select til Xcode (ikke Command Line Tools)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
echo "✓ xcode-select → Xcode"
echo ""

# Arkiver
ARCHIVE_PATH="/tmp/Vitola_build114.xcarchive"
echo "▶ Arkiverer build 114 (~2 min)..."
xcodebuild archive \
  -project Vitola.xcodeproj \
  -scheme Vitola \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=H7NS3V5EFA \
  2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED|archive"

echo ""
if [ -d "$ARCHIVE_PATH" ]; then
  echo "✓ Arkiv klart!"
  echo "▶ Åpner i Xcode Organizer for opplasting..."
  open "$ARCHIVE_PATH"
else
  echo "❌ Arkivering feilet — se feil over"
fi

read -p "Trykk Enter for å lukke..."
