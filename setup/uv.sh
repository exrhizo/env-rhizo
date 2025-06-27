#!/usr/bin/env bash
#
# Create an isolated uv virtual-env with a modern M1-friendly data-science stack,
# including Graphistry from the same Git commit you pin in conda.
#
# • Installs uv with Homebrew if missing.
# • Creates or reuses ~/venvs/uv-ds
# • Installs wheels only once and reuses the local cache on re-runs.

set -euo pipefail

ENV_HOME="$HOME/venvs"
ENV_NAME="uv-ds"
GRAPHISTRY_COMMIT="afefc3b258360e2d92bd535e80ec0775299e18c1"

# 1. Ensure uv is present (brew puts it at /opt/homebrew/bin/uv)
if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv via Homebrew…"
  brew install uv
fi

# 2. Create (or reuse) the venv
uv venv "$ENV_HOME/$ENV_NAME"

# 3. Install packages
uv pip install \
  numpy pandas scipy scikit-learn numba \
  matplotlib pillow opencv-python moviepy \
  pyarrow pdfminer.six PyPDF2 \
  sentence-transformers faiss-cpu \
  umap-learn networkx \
  "graphistry @ git+https://github.com/graphistry/pygraphistry.git@$GRAPHISTRY_COMMIT"

echo "✅  uv env ready. Activate with:"
echo "    source \"$ENV_HOME/$ENV_NAME/bin/activate\""
