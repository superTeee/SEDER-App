#!/bin/bash
cd "$(dirname "$0")"
git push origin master:main
echo ""
echo "✅ Push ferdig!"
read -p "Trykk Enter for å lukke..."
