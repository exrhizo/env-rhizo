# ============================================================================
#  zsh-ergonomics.sh – lightweight quality-of-life add-ons (no auto-updates)
#  • History-substring search on ↑ / ↓
#  • Smarter, fuzzy-ish completion (case-insensitive, inner-substring, menus)
#  • Optional fzf power-ups if fzf is present
#  Put this file anywhere (e.g. $HOME/.config/zsh/zsh-ergonomics.sh)
#  and   source zsh-ergonomics.sh   from your main ~/.zshrc
# ============================================================================

# Guard against double-loading
[[ -n ${ZSH_ERGONOMICS_LOADED:-} ]] && return
export ZSH_ERGONOMICS_LOADED=1

# ---------------------------------------------------------------------------
# 0.  Baseline initialisation
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit -u    # -u => skip “insecure dirs” warning
autoload -Uz colors   && colors         # $fg[…] & friends
setopt prompt_subst                      # lets $(…) run inside PROMPTs

# ---------------------------------------------------------------------------
# 1.  History-substring search on ↑ / ↓
# ---------------------------------------------------------------------------
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N  up-line-or-beginning-search
zle -N  down-line-or-beginning-search

# Bind in both emacs & vi-insert keymaps
for km in emacs viins; do
  bindkey -M $km '^[[A' up-line-or-beginning-search   # ↑
  bindkey -M $km '^[[B' down-line-or-beginning-search # ↓
done

# ---------------------------------------------------------------------------
# 2.  Fuzzy / forgiving tab-completion
# ---------------------------------------------------------------------------
# Case-insensitive & partial-substring matching
zstyle ':completion:*' matcher-list \
       'm:{a-zA-Z}={A-Za-z}' \
       'r:|[._-]=* r:|=*' \
       'l:|=* r:|=*'

# Menu-style completion after first ambiguous Tab
setopt menu_complete      # 1st Tab: longest common prefix
setopt auto_menu          # 2nd Tab: interactive menu
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
