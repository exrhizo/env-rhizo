#!/usr/bin/env bash
set -e

DEST="./"
SUPPORT_URL="https://www.msi.com/Motherboard/MPG-Z690-CARBON-WIFI/support"

# Pull links for Win11 x64 driver zips/exes from the support page
curl -Ls "$SUPPORT_URL?os=Windows%2011%2064-bit#down-driver" \
| grep -Eo 'https://download\.msi\.com[^"'\'' ]+' \
| grep -E '/(dvr_exe|utility)/' \
| sort -u > /tmp/msi_links.txt

# Download with parallel segments; fallback to wget if aria2c is not your vibe
aria2c -c -x16 -s16 -d "$DEST/Drivers/all" -i /tmp/msi_links.txt || \
  wget -c -P "$DEST/Drivers/all" -i /tmp/msi_links.txt

# Categorize by filename keywords (rough but works)
while IFS= read -r f; do :; done < /dev/null
mkdir -p "$DEST/Drivers"/{Chipset,ME,LAN,WiFi,Bluetooth,Audio,SerialIO,Thunderbolt,IRST} || true
shopt -s nullglob
for f in "$DEST/Drivers/all"/*; do
  name=$(basename "$f" | tr '[:upper:]' '[:lower:]')
  case "$name" in
    *chipset* )    mv -n "$f" "$DEST/Drivers/Chipset/";;
    *management*|*mei*|*me_* ) mv -n "$f" "$DEST/Drivers/ME/";;
    *lan*|*i225*|*ethernet* )  mv -n "$f" "$DEST/Drivers/LAN/";;
    *wifi*|*wireless*|*ax210*|*ax211* ) mv -n "$f" "$DEST/Drivers/WiFi/";;
    *bt*|*bluetooth* )         mv -n "$f" "$DEST/Drivers/Bluetooth/";;
    *audio*|*nahimic*|*realtek* ) mv -n "$f" "$DEST/Drivers/Audio/";;
    *serial*io*|*gpio*|*i2c* ) mv -n "$f" "$DEST/Drivers/SerialIO/";;
    *thunderbolt*|*tbt* )      mv -n "$DEST/Drivers/Thunderbolt/";;
    *rst*|*vmd*|*f6* )         mv -n "$f" "$DEST/Drivers/IRST/";;
    * ) : ;;
  esac
done
echo "Driver packs in: $DEST/Drivers"
