#Setup zsh

export ENVDIR=$HOME/env-rhizo

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
zstyle ':completion:*:*:git:*' script $ENVDIR/completions/git-completion.bash
zstyle ':completion:*:*:hasura:*' script $ENVDIR/completions/hasura-completion.bash
# This caused a wierd error and the completion was slow...
# fpath=($ENVDIR/completions $fpath)

# Load completions
autoload -Uz compinit && compinit

# Delete % at the beginning
# unsetopt PROMPT_SP

# Highlight commands
source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

