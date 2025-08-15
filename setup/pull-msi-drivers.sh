#!/usr/bin/env bash
# pull-msi-z690-carbon.sh
# wget-only, flat output, light logs
set -euo pipefail

MODEL="MPG-Z690-CARBON-WIFI"
SUPPORT_URL="https://www.msi.com/Motherboard/${MODEL}/support"
DEST="${1:-.}"
OUT="$DEST/Drivers"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127 Safari/537.36'
REF='https://www.msi.com/support/download/'

want_w11=true
want_bios=true
want_ubuntu=false

# Flags: --w11 / --bios / --ubuntu  (defaults: w11+bios)
for arg in "${@:2}"; do
  case "$arg" in
    --w11) want_w11=true ;;
    --no-w11) want_w11=false ;;
    --bios) want_bios=true ;;
    --no-bios) want_bios=false ;;
    --ubuntu) want_ubuntu=true ;;
    --no-ubuntu) want_ubuntu=false ;;
  esac
done

log()  { printf '%s %s\n' "[INFO]" "$*"; }
warn() { printf '%s %s\n' "[WARN]" "$*" >&2; }
err()  { printf '%s %s\n' "[ERR ]" "$*"  >&2; }

mkdir -p "$OUT"
TMP_HTML="$(mktemp)"
LINKS="$(mktemp)"

# --- 1) Try to harvest direct CDN links from MSI support HTML (works if they inline them as JSON) ---
log "Model: $MODEL"
log "Dest : $OUT"
log "Fetching support page (to sniff any direct CDN links)..."
if wget -q --user-agent="$UA" --header="Referer: $REF" -O "$TMP_HTML" "${SUPPORT_URL}?os=Windows%2011%2064-bit#down-driver"; then
  # Extract both escaped https:\/\/ and literal https://, unescape, keep only MSI CDN buckets
  grep -Eo 'https:\\/\\/download\.msi\.com[^"\\ ]+|https://download\.msi\.com[^"'\'' <>]+' "$TMP_HTML" \
    | sed 's#\\/#/#g' \
    | grep -Ei '/(dvr_exe|uti_exe|bos_exe)/' \
    | sort -u > "$LINKS" || true
  # Optional pass for BIOS tab too
  if $want_bios; then
    wget -q --user-agent="$UA" --header="Referer: $REF" -O "$TMP_HTML" "${SUPPORT_URL}#down-bios" || true
    grep -Eo 'https:\\/\\/download\.msi\.com[^"\\ ]+|https://download\.msi\.com[^"'\'' <>]+' "$TMP_HTML" \
      | sed 's#\\/#/#g' \
      | grep -Ei '/bos_exe/' \
      | sort -u >> "$LINKS" || true
    sort -u "$LINKS" -o "$LINKS"
  fi
else
  warn "Support page 403/blocked. Will use curated fallbacks."
fi

# --- 2) Curated fallback URLs (minimal, battle-tested names) ---
# Windows 11 x64 driver packs commonly listed for 600-series on MSI:
FALLBACK_W11_URLS=(
  "https://download.msi.com/dvr_exe/mb/intel_chipset_600_700.zip"
  "https://download.msi.com/dvr_exe/mb/intel_me_adl_16.1.zip"
  "https://download.msi.com/dvr_exe/mb/Intel_Network_i225_inf.zip"
  "https://download.msi.com/dvr_exe/mb/intel_wifi_driver_W11.zip"
  "https://download.msi.com/dvr_exe/mb/bt_driver_W11.zip"
  "https://download.msi.com/dvr_exe/mb/realtek_audio_USB_R.zip"
  "https://download.msi.com/dvr_exe/mb/intel_Serial_IO_adl.zip"
  "https://download.msi.com/dvr_exe/mb/intel_rst_19.0.zip"
  "https://download.msi.com/dvr_exe/mb/intel_vga_adl.zip"
)

# BIOS package (board code MS-7D30; versions roll, this is the recent series)
FALLBACK_BIOS_URLS=(
  "https://download.msi.com/bos_exe/mb/7D30v1L.zip"
)

# Ubuntu/Linux: MSI rarely posts Linux drivers for this board; kernel usually covers it.
# If MSI publishes any, they’ll appear in LINKS harvest above as /dvr_exe/... with linux/ubuntu in name.
FALLBACK_UBUNTU_URLS=(
  # Intentionally empty unless MSI provides a Linux tarball; kernel has igc (I225), iwlwifi, btusb, snd-usb-audio.
)

# --- 3) Build the final URL set ---
> "$OUT/.urls"
if [ -s "$LINKS" ]; then
  log "Parsed $(wc -l < "$LINKS" | tr -d ' ') URLs from MSI HTML."
  # Filter by selection
  if ! $want_w11; then grep -viE '/(dvr_exe|uti_exe)/' "$LINKS" > "${LINKS}.tmp" && mv "${LINKS}.tmp" "$LINKS"; fi
  if ! $want_bios; then grep -viE '/bos_exe/' "$LINKS" > "${LINKS}.tmp" && mv "${LINKS}.tmp" "$LINKS"; fi
  if ! $want_ubuntu; then :; fi  # linux filtering is fuzzy; we keep them if present
  cat "$LINKS" >> "$OUT/.urls"
else
  warn "No CDN links sniffed; falling back to curated lists."
  $want_w11   && printf "%s\n" "${FALLBACK_W11_URLS[@]}"   >> "$OUT/.urls"
  $want_bios  && printf "%s\n" "${FALLBACK_BIOS_URLS[@]}"  >> "$OUT/.urls"
  $want_ubuntu&& printf "%s\n" "${FALLBACK_UBUNTU_URLS[@]}">> "$OUT/.urls"
fi

# Dedupe and sanity
sort -u "$OUT/.urls" -o "$OUT/.urls"
total=$(wc -l < "$OUT/.urls" | tr -d ' ')
if [ "$total" = "0" ]; then
  err "No URLs to download. Check network or tweak the fallback list."
  exit 2
fi

log "Downloading $total file(s) to $OUT (flat)..."
download_one () {
  local url="$1"
  local base="${url##*/}"
  printf '[GET ] %s\n' "$base"
  if ! wget -q --show-progress --progress=bar:force:noscroll \
        --tries=3 --timeout=25 --max-redirect=20 --timestamping \
        --user-agent="$UA" --header="Referer: $REF" \
        -P "$OUT" "$url"
  then
    # Quick mirror retry: download-2.msi.com
    if [[ "$url" == https://download.msi.com/* ]]; then
      local alt="${url/download.msi.com/download-2.msi.com}"
      printf '[MIR ] %s\n' "${alt##*/}"
      wget -q --show-progress --progress=bar:force:noscroll \
        --tries=3 --timeout=25 --max-redirect=20 --timestamping \
        --user-agent="$UA" --header="Referer: $REF" \
        -P "$OUT" "$alt" || printf '[FAIL] %s\n' "$base"
    else
      printf '[FAIL] %s\n' "$base"
    fi
  fi
}
export -f download_one
export OUT UA REF

# Serial download (simple & readable logs). Swap to xargs -P if you want parallel later.
while IFS= read -r url; do
  download_one "$url"
done < "$OUT/.urls"

log "Done. Files in $OUT"
