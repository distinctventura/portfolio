#!/bin/bash

set -e

FOLDER="$1"
PORTFOLIO_DIR="$(cd "$(dirname "$0")" && pwd)"
HTML="$PORTFOLIO_DIR/index.html"

if [ -z "$FOLDER" ]; then
  echo "Usage: $0 <folder-name>"
  echo "Example: $0 film-archive"
  exit 1
fi

if [ ! -d "$PORTFOLIO_DIR/$FOLDER" ]; then
  echo "Error: folder '$FOLDER' not found in $(dirname "$0")"
  exit 1
fi

# Collect image/video files sorted numerically
FILES=$(ls "$PORTFOLIO_DIR/$FOLDER/" | grep -iE '\.(jpg|jpeg|png|mp4)$' | sort -V)

if [ -z "$FILES" ]; then
  echo "No image/video files found in $FOLDER/"
  exit 1
fi

COUNT=$(echo "$FILES" | wc -l | tr -d ' ')

# Build the JS array string
ARRAY="["
FIRST=1
while IFS= read -r FILE; do
  if [ $FIRST -eq 0 ]; then
    ARRAY="${ARRAY},"
  fi
  ARRAY="${ARRAY}'${FOLDER}/${FILE}'"
  FIRST=0
done <<< "$FILES"
ARRAY="${ARRAY}]"

echo "Found $COUNT files in $FOLDER/:"
echo "$FILES" | sed 's/^/  /'
echo ""

# Update the imgs array in index.html using Python
python3 - "$HTML" "$FOLDER" "$ARRAY" <<'PYEOF'
import sys, re

html_path, folder, new_array = sys.argv[1], sys.argv[2], sys.argv[3]

with open(html_path, 'r') as f:
    content = f.read()

pattern = r"(imgs:\s*)\[[^\]]*'" + re.escape(folder) + r"/[^\]]*\]"
replacement = r"\g<1>" + new_array

new_content, count = re.subn(pattern, replacement, content)

if count == 0:
    print(f"Error: no imgs array found for folder '{folder}' in index.html")
    print("Make sure the project already has an imgs entry in the PROJECTS array.")
    sys.exit(1)

with open(html_path, 'w') as f:
    f.write(new_content)

print(f"index.html updated — {count} imgs array replaced")
PYEOF
