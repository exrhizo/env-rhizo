############################################################
# conda-ergonomics.sh  (VS Code + Zsh, no more IndexError)
############################################################

### 1) keep PATH unique
typeset -U path PATH

### 2) If we're inside VS Code and Conda already bootstrapped the env,
###    finish the job so later `conda activate …` calls succeed.
if [[ "$TERM_PROGRAM" == "vscode" && -n "$CONDA_PREFIX" ]]; then
  # Bring in the full Conda hook once so that `conda activate` is a shell func
  if ! type conda &>/dev/null; then
    source "$CONDA_ROOT/etc/profile.d/conda.sh"
  fi

  env_bin="${CONDA_PREFIX}/bin"
  env_lib="${CONDA_PREFIX}/Library/bin"

  # Re-build $PATH with env_lib inserted *right after* env_bin
  new=()
  inserted=0
  for seg in ${(ps.:.)PATH}; do
    new+=("$seg")
    if [[ "$seg" == "$env_bin" && $inserted -eq 0 ]]; then
      new+=("$env_lib")
      inserted=1
    fi
  done
  # If VS Code ever changes and env_bin isn't present, prepend the pair.
  (( inserted )) || new=("$env_bin" "$env_lib" "${new[@]}")
  PATH="${(j.:.)new}"
fi

### 3) Outside VS Code, auto-activate whatever env you like.
if [[ "$TERM_PROGRAM" != "vscode" && -z "$CONDA_DEFAULT_ENV" ]]; then
  conda activate base          # or lu-client, or none – your call
fi
