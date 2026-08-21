#!/bin/bash
cd "$(dirname "$0")"
chmod +x scripts/install-macos.sh
/bin/bash scripts/install-macos.sh
echo
read -r -p "Press Enter to close..."
