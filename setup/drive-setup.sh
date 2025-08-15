# Recreate scratch + temp setup
# - /dev/nvme2n1p1 => XFS labeled "wrk", mounted at /wrk
# - bind-mount /var/tmp -> /wrk/var_tmp
# - install /etc/profile.d/wrk-cache.sh
# - Optional: blank /dev/nvme1n1 for Windows (set PREP_WINDOWS=1)

set -euo pipefail

WRK_DEV="/dev/nvme2n1"
WRK_PART="${WRK_DEV}p1"
WRK_LABEL="wrk"
WRK_MP="/wrk"

WIN_DEV="/dev/nvme1n1"
PREP_WINDOWS=0   # <-- set to 1 if you want to blank the Windows disk again

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 2; }; }
[[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }
need sgdisk; need blkid; need lsblk; need mkfs.xfs

ensure_wrk_partition() {
  if [[ ! -e "$WRK_PART" ]]; then
    sgdisk -n1:0:0 -t1:8300 -c1:"$WRK_LABEL" "$WRK_DEV"
    partprobe "$WRK_DEV" || udevadm settle
  fi
}

ensure_wrk_fs() {
  local lbl; lbl=$(blkid -s LABEL -o value "$WRK_PART" || true)
  local fstype; fstype=$(lsblk -no FSTYPE "$WRK_PART" || true)
  if [[ "$lbl" != "$WRK_LABEL" || "$fstype" != "xfs" ]]; then
    mkfs.xfs -f -L "$WRK_LABEL" "$WRK_PART"
  fi
}

ensure_wrk_mount() {
  mkdir -p "$WRK_MP"
  grep -qE "LABEL=${WRK_LABEL}[[:space:]]+${WRK_MP}[[:space:]]+xfs" /etc/fstab || \
    echo "LABEL=${WRK_LABEL} ${WRK_MP} xfs noatime 0 2" >> /etc/fstab
  mountpoint -q "$WRK_MP" || mount "$WRK_MP"
}

ensure_var_tmp_bind() {
  mkdir -p "${WRK_MP}/var_tmp"
  chmod 1777 "${WRK_MP}/var_tmp"
  # add bind line if missing
  grep -qE "^[[:space:]]*${WRK_MP}/var_tmp[[:space:]]+/var/tmp[[:space:]]+none[[:space:]]+bind" /etc/fstab || \
    echo "${WRK_MP}/var_tmp /var/tmp none bind 0 0" >> /etc/fstab
  # mount (handles both fresh and already-mounted)
  mountpoint -q /var/tmp || mount /var/tmp
}

install_cache_profile() {
  mkdir -p "${WRK_MP}/cache"/{pip,uv,hf,torch}
  cat >/etc/profile.d/wrk-cache.sh <<'EOF'
export XDG_CACHE_HOME=/wrk/cache
export PIP_CACHE_DIR=/wrk/cache/pip
export UV_CACHE_DIR=/wrk/cache/uv
export HF_HOME=/wrk/cache/hf
export TRANSFORMERS_CACHE=/wrk/cache/hf
export TORCH_HOME=/wrk/cache/torch
EOF
}

prep_windows_disk() {
  # DANGEROUS: wipes ${WIN_DEV}
  wipefs -af "$WIN_DEV" || true
  sgdisk -Zo "$WIN_DEV"
  blkdiscard -f "$WIN_DEV" || true
}

main() {
  ensure_wrk_partition
  ensure_wrk_fs
  ensure_wrk_mount
  ensure_var_tmp_bind
  install_cache_profile
  [[ "$PREP_WINDOWS" -eq 1 ]] && prep_windows_disk

  echo "=== State ==="
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | egrep 'nvme2|wrk|/wrk|/var/tmp' || true
  echo
  echo "/etc/fstab:"
  grep -E 'LABEL=wrk|/var/tmp' /etc/fstab || true
  echo
  echo "Mounts:"
  mount | egrep ' /wrk | /var/tmp ' || true
}
main "$@"
