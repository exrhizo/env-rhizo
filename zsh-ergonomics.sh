# ============================================================================
#  zsh-ergonomics.sh – lightweight quality-of-life add-ons (no auto-updates)
#  • History-substring search on ↑ / ↓
#  • Smarter, fuzzy-ish completion (case-insensitive, inner-substring, menus)
#  • Optional fzf power-ups if fzf is present
#  Put this file anywhere (e.g. $HOME/.config/zsh/zsh-ergonomics.sh)
#  and   source zsh-ergonomics.sh   from your main ~/.zshrc
# ============================================================================

# ---------------------------------------------------------------------------
# 0.  Baseline initialisation
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit -u    # -u => skip “insecure dirs” warning
autoload -Uz colors   && colors         # $fg[…] & friends
setopt prompt_subst                      # lets $(…) run inside PROMPTs

# ---------------------------------------------------------------------------
# 1.  History-substring search on ↑ / ↓
# ---------------------------------------------------------------------------
# Prefix-search ↑/↓ even after VS Code’s shell-integration
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N  up-line-or-beginning-search
zle -N  down-line-or-beginning-search

__prefix_rebind() {
  for km in main emacs viins vicmd; do
    bindkey -M $km '^[[A' up-line-or-beginning-search   # Up
    bindkey -M $km '^[[B' down-line-or-beginning-search # Down
  done
}

__prefix_rebind

# ---------------------------------------------------------------------------
# 2.  Fuzzy / forgiving tab-completion
# ---------------------------------------------------------------------------
# Case-insensitive & partial-substring matching
zstyle ':completion:*' matcher-list \
       'm:{a-zA-Z}={A-Za-z}' \
       'r:|[._-]=* r:|=*' \
       'l:|=* r:|=*'

# Menu-style completion after first ambiguous Tab
unsetopt menu_complete    # Don't auto-fill first match
setopt auto_menu          # Show menu on 2nd Tab
setopt list_ambiguous     # Complete up to ambiguity point
setopt glob_complete      # treat incomplete path chunks as globs (en/env*)

# ---------------------------------------------------------------------------
# 3.  Optional fzf integrations  (only if you installed fzf)
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null; then
  # Key-bindings:  Ctrl-T files,  Alt-C cd-into-dir,  Ctrl-R history, …
  for f in key-bindings.zsh completion.zsh; do
    source "$(dirname $(command -v fzf))/../share/fzf/$f" 2>/dev/null
  done
  # Faster default search (fd + ripgrep); falls back gracefully
  FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_DEFAULT_COMMAND
fi
