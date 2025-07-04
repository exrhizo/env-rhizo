#!/usr/bin/env bash
# /Users/exrhizo/env-rhizo/narrative.sh
set -euo pipefail

# 1 ▪ Grab the page (follow redirects) and squash newlines → easier regexp
html=$(curl -sL https://exrhizo.me | tr '\n' ' ')

# 2 ▪ Pull out the description, regardless of attribute order or quote style
bio=$(
  printf '%s\n' "$html" |
  sed -nE 's|.*<meta[^>]+name=[\"\x27]description[\"\x27][^>]+content=[\"\x27]([^\"\x27>]*)[\"\x27][^>]*>.*|\1|Ip' |
  head -n1
)

echo "Current site bio: $bio"
root_tagline="Build the tools that feel"
echo "Root tagline   : $root_tagline"

# 3 ▪ Fire a notification **only** if the tagline is missing
if ! grep -qF "$root_tagline" <<<"$bio"; then
  /usr/bin/osascript -e \
    'display notification "Bio drift detected on exrhizo.me" with title "Narrative Monitor"'
fi
