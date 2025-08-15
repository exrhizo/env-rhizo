#!/usr/bin/env bash
# pull-msi-z690-win11-flat.sh — Win11 drivers for MPG-Z690-CARBON-WIFI
set -euo pipefail

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127 Safari/537.36'
REF='https://www.msi.com/support/download/'

urls=(
  # Core Win11 drivers commonly posted for 600/700-series
  "https://download.msi.com/dvr_exe/mb/intel_chipset_600_700.zip"
  "https://download.msi.com/dvr_exe/mb/intel_me_adl_16.1.zip"
  "https://download.msi.com/dvr_exe/mb/intel_wifi_driver_W11.zip"
  "https://download.msi.com/dvr_exe/mb/bt_driver_W11.zip"
  "https://download.msi.com/dvr_exe/mb/realtek_audio_USB_R.zip"
  "https://download.msi.com/dvr_exe/mb/intel_Serial_IO_adl.zip"
  "https://download.msi.com/dvr_exe/mb/intel_rst_19.0.zip"
  "https://download.msi.com/dvr_exe/mb/intel_vga_adl.zip"
  # LAN: Win11 often has it inbox; MSI’s i225 INF link is flaky so omitted by default.
  # BIOS (optional): uncomment if you want it here too
  # "https://download.msi.com/bos_exe/mb/7D30v1L.zip"
)

for u in "${urls[@]}"; do
  f="${u##*/}"
  echo "[get] $f"
  curl -fL -A "$UA" -e "$REF" -C - -o "$f" "$u" || echo "[fail] $f"
done

echo "[unzip] flattening into ./"
shopt -s nullglob
for z in *.zip; do unzip -j -o "$z" -d .; done

# Quick sanity: how many driver INF files landed?
echo -n "[info] INF files: "
find . -maxdepth 1 -type f -iname '*.inf' | wc -l | tr -d ' '

echo
echo "[ok] done — everything is in the current directory."
