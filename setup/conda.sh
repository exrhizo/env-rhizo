#!/usr/bin/env bash
#
# Fresh-install Miniconda (same version as louie/Docker), add libmamba solver,
# and optionally delete every existing env.  Idempotent.

set -euo pipefail

MINICONDA_VER="py312_25.1.1-2"
INSTALL_PREFIX="$HOME/miniconda3"
CONDA_SH="$INSTALL_PREFIX/etc/profile.d/conda.sh"

echo "→ Target prefix: $INSTALL_PREFIX"
read -rp "⚠️  Delete *all* current conda environments under that prefix? [y/N] " yn
WIPE=${yn:-n}

if [[ $WIPE =~ ^[Yy]$ ]]; then
  echo "Removing $INSTALL_PREFIX …"
  rm -rf "$INSTALL_PREFIX"
fi

if [[ ! -d $INSTALL_PREFIX ]]; then
  echo "Downloading Miniconda $MINICONDA_VER …"
  curl -L "https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VER}-MacOSX-arm64.sh" -o /tmp/mini.sh
  bash /tmp/mini.sh -b -p "$INSTALL_PREFIX"
  rm /tmp/mini.sh
fi

# Activate freshly installed base
source "$CONDA_SH"
conda activate base

# Add mamba *first* (so the next step can use it)
conda install -y -n base -c conda-forge mamba

# Add the plugin that lets plain `conda` call the same fast engine
mamba install -y -n base -c conda-forge conda-libmamba-solver

# Make libmamba the default solver for every future `conda`
conda config --set solver libmamba

conda config --set auto_activate false

echo -e "\n✅  Done.  Every future 'conda' or 'conda-lock install' call uses libmamba speed."
echo "   If ~/.zshrc doesn’t already source conda, add:"
echo "       source \"$CONDA_SH\""
