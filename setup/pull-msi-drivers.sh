#!/usr/bin/env bash
set -e

MODEL="MPG-Z690-CARBON-WIFI"
SUPPORT_URL="https://www.msi.com/Motherboard/${MODEL}/support"
DEST="${1:-.}"

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127 Safari/537.36'
LINKS="/tmp/msi_links.txt"
TMP_HTML="/tmp/msi_support.html"

mkdir -p "$DEST/Drivers/all"

# Pull links (handle JSON-escaped https:\/\/ and normal https://)
curl -fsSL -A "$UA" "$SUPPORT_URL?os=Windows%2011%2064-bit#down-driver" > "$TMP_HTML"

grep -Eo "https:\\/\\/download\.msi\.com[^\"\\ ]+|https://download\.msi\.com[^\"' <>]+" "$TMP_HTML" \
| sed 's#\\/#/#g' \
| grep -iE '/(dvr_exe|uti_exe|utility)/' \
| sort -u > "$LINKS"

# Bail early if MSI blocked us or layout changed
if ! [ -s "$LINKS" ]; then
  echo "No driver URLs parsed. MSI may be blocking curl or the page layout changed." >&2
  exit 1
fi

# Download: aria2c if present, else wget
if command -v aria2c >/dev/null 2>&1; then
  aria2c -c -x16 -s16 -d "$DEST/Drivers/all" -i "$LINKS"
else
  wget -c -P "$DEST/Drivers/all" -i "$LINKS"
fi

# Categorize by filename keywords
mkdir -p "$DEST/Drivers"/{Chipset,ME,LAN,WiFi,Bluetooth,Audio,SerialIO,Thunderbolt,IRST}
shopt -s nullglob
for f in "$DEST/Drivers/all"/*; do
  lname="$(basename "$f")"; lname="${lname,,}"
  case "$lname" in
    *chipset* )                             mv -n "$f" "$DEST/Drivers/Chipset/";;
    *management*|*me_*|*mei* )              mv -n "$f" "$DEST/Drivers/ME/";;
    *lan*|*i225*|*ethernet* )               mv -n "$f" "$DEST/Drivers/LAN/";;
    *wifi*|*wireless*|*ax210*|*ax211* )     mv -n "$f" "$DEST/Drivers/WiFi/";;
    *bt*|*bluetooth*|*intel_bt* )           mv -n "$f" "$DEST/Drivers/Bluetooth/";;
    *audio*|*nahimic*|*realtek* )           mv -n "$f" "$DEST/Drivers/Audio/";;
    *serial*io*|*gpio*|*i2c* )              mv -n "$f" "$DEST/Drivers/SerialIO/";;
    *thunderbolt*|*tbt* )                   mv -n "$f" "$DEST/Drivers/Thunderbolt/";;
    *rst*|*vmd*|*f6*|*irst* )               mv -n "$f" "$DEST/Drivers/IRST/";;
    * ) : ;;
  esac
done

echo "Driver packs in: $DEST/Drivers"
