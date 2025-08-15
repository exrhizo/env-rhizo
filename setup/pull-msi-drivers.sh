#!/usr/bin/env bash
# pull-msi-z690-carbon-min.sh
set -euo pipefail

MODEL="MPG-Z690-CARBON-WIFI"
URL="https://www.msi.com/Motherboard/${MODEL}/support?os=Windows%2011%2064-bit#down-driver"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127 Safari/537.36'
REF='https://www.msi.com/support/download/'

echo "[get] scraping $MODEL (Win11)…"
mapfile -t LINKS < <(wget -q --user-agent="$UA" --header="Referer: $REF" -O - "$URL" \
  | grep -Eo 'https:\\/\\/download(-2)?\.msi\.com[^"\\ ]+|https://download(-2)?\.msi\.com[^"'\'' <>]+' \
  | sed 's#\\/#/#g' \
  | grep -E '/dvr_exe/.*\.zip$' \
  | sort -u)

[ ${#LINKS[@]} -gt 0 ] || { echo "[err] no driver links found"; exit 1; }

for u in "${LINKS[@]}"; do
  echo "[get] ${u##*/}"
  wget -q --show-progress --progress=bar:force:noscroll -c \
    --user-agent="$UA" --header="Referer: $REF" "$u" || echo "[fail] ${u##*/}"
done

shopt -s nullglob
for z in *.zip; do
  echo "[unzip] $z"
  unzip -j -o "$z" -d .
done

echo "[ok] done — files are in ./"
