#!/usr/bin/env bash
set -e

DEST_MNT="/media/$USER/DRIVERS"
SUPPORT_URL="https://www.msi.com/Motherboard/MPG-Z690-CARBON-WIFI/support"

mkdir -p "$DEST_MNT/Drivers/all"

# Pull links for Win11 x64 driver zips/exes from the support page
curl -Ls "$SUPPORT_URL?os=Windows%2011%2064-bit#down-driver" \
| grep -Eo 'https://download\.msi\.com[^"'\'' ]+' \
| grep -E '/(dvr_exe|utility)/' \
| sort -u > /tmp/msi_links.txt

# Download with parallel segments; fallback to wget if aria2c is not your vibe
aria2c -c -x16 -s16 -d "$DEST_MNT/Drivers/all" -i /tmp/msi_links.txt || \
  wget -c -P "$DEST_MNT/Drivers/all" -i /tmp/msi_links.txt

# Categorize by filename keywords (rough but works)
while IFS= read -r f; do :; done < /dev/null
mkdir -p "$DEST_MNT/Drivers"/{Chipset,ME,LAN,WiFi,Bluetooth,Audio,SerialIO,Thunderbolt,IRST} || true
shopt -s nullglob
for f in "$DEST_MNT/Drivers/all"/*; do
  name=$(basename "$f" | tr '[:upper:]' '[:lower:]')
  case "$name" in
    *chipset* )    mv -n "$f" "$DEST_MNT/Drivers/Chipset/";;
    *management*|*mei*|*me_* ) mv -n "$f" "$DEST_MNT/Drivers/ME/";;
    *lan*|*i225*|*ethernet* )  mv -n "$f" "$DEST_MNT/Drivers/LAN/";;
    *wifi*|*wireless*|*ax210*|*ax211* ) mv -n "$f" "$DEST_MNT/Drivers/WiFi/";;
    *bt*|*bluetooth* )         mv -n "$f" "$DEST_MNT/Drivers/Bluetooth/";;
    *audio*|*nahimic*|*realtek* ) mv -n "$f" "$DEST_MNT/Drivers/Audio/";;
    *serial*io*|*gpio*|*i2c* ) mv -n "$f" "$DEST_MNT/Drivers/SerialIO/";;
    *thunderbolt*|*tbt* )      mv -n "$DEST_MNT/Drivers/Thunderbolt/";;
    *rst*|*vmd*|*f6* )         mv -n "$f" "$DEST_MNT/Drivers/IRST/";;
    * ) : ;;
  esac
done
echo "Driver packs in: $DEST_MNT/Drivers"
