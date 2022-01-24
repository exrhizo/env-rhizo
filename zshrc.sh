#Setup zsh

export ENV_DIR=$HOME/env-rhizo
export ENV_COMPETION=$ENV_DIR/completions

export ZSH=$HOME/.oh-my-zsh
ZSH_PLUGIN_DIR=$HOME/.oh-my-zsh/plugins
ZSH_THEME="eastwood"
# ZSH_THEME="gnzh"

plugins=(
	git
	zsh-autosuggestions
	zsh-completions
	docker
	docker-compose
)

source $ZSH/oh-my-zsh.sh

# Init completions
zstyle ':completion:*:*:git:*' script $ENV_COMPETION/git-completion.bash
zstyle ':completion:*:*:hasura:*' script $ENV_COMPETION/hasura-completion.bash
. $ENV_COMPETION/npm-completion.bash

# Load completions
autoload -Uz compinit && compinit
# may need to run this to reset completions:
# rm ~/.zcompdum

# Delete % at the beginning
# unsetopt PROMPT_SP

# Highlight commands
source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

