#!/bin/bash
grep -E "error:|Build FAILED|\(.*failure" /tmp/build67.log > "/Users/tomerikheggedal/Documents/My Projects/Cigar App/build67_errors.txt"
echo "Ferdig — sjekk build67_errors.txt"
read -p ""
