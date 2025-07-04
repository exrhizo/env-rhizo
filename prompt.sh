
setopt prompt_subst            # let $(cmd) run inside PROMPT
autoload -Uz colors && colors  # defines $fg[...] / %F{…} colours


arch_indicator() {             # M1 vs Rosetta
  [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" == 1 ]] && echo x86 || echo M1
}

git_prompt_info() {            # [branch] or [branch*] if dirty
  local ref
  ref=$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
        || git rev-parse  --quiet --short HEAD 2>/dev/null) || return
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    echo "%F{yellow}[${ref}*]%f"
  else
    echo "%F{green}[${ref}]%f"
  fi
}


# • cyan arch, bold-blue path, git info, arrow
# • RPROMPT: red “✘ <status>” if last cmd failed
PROMPT="%F{cyan}\$(arch_indicator)%f %B%F{blue}%~%f%b \$(git_prompt_info)%F{cyan}➜%f "
# RPROMPT='%(?..%F{red}✘ %?%f)'
