#!/bin/bash
# Vitola — Generer Xcode-prosjekt
# Dobbeltklikk denne filen for å kjøre

cd "$(dirname "$0")"
echo "================================================"
echo "  Vitola — Xcode-prosjektgenerator"
echo "================================================"
echo ""

# Sjekk Homebrew
if ! command -v brew &>/dev/null; then
  echo "▶ Installerer Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✓ Homebrew er installert"
fi

# Sjekk XcodeGen
if ! command -v xcodegen &>/dev/null; then
  echo "▶ Installerer XcodeGen..."
  brew install xcodegen
else
  echo "✓ XcodeGen er installert ($(xcodegen --version))"
fi

echo ""
echo "▶ Genererer Vitola.xcodeproj..."
xcodegen generate --spec project.yml

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Vitola.xcodeproj er klar!"
  echo ""
  echo "▶ Åpner i Xcode..."
  open Vitola.xcodeproj
else
  echo ""
  echo "✗ Noe gikk galt. Sjekk feilmeldingen over."
fi

echo ""
echo "Trykk Enter for å lukke..."
read
