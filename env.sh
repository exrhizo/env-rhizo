#!/bin/zsh

# This DIR
export ENVDIR=$HOME/env-rhizo

export EDITOR='subl -w'
export VISUAL=$EDITOR

FILE=$ENVDIR/secrets.sh && test -f $FILE && source $FILE

# FileSearch
function f() { find . -iname "*$1*" ${@:2} }
function r() { grep "$1" ${@:2} -R . }

# Easy find commands
function hgrep() {history 0 | grep "$1"}

alias rip="rip --graveyard ~/.local/share/Trash"
alias dc="docker-compose"
alias scripts="jq '.scripts' package.json"

# Use sublimetext for editing config files
alias zshconfig="subl $ENVDIR/zshrc.sh"
alias envconfig="subl $ENVDIR/env.sh"

# Use Gnu utils instead of mac's old crapy versions
# https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# Virtual Environment
# export WORKON_HOME=$HOME/.virtualenvs
# export PROJECT_HOME=$HOME/projects
# source /usr/local/bin/virtualenvwrapper.sh


# What? mac is always indexing nodemodules? dumb
# open your profile with `vim ~/.bash_profile`
# and paste the function below
# https://aurelio.me/blog/Yarn-Npm-Faster/
function npmi {
    mkdir node_modules 2>/dev/null
    touch ./node_modules/.metadata_never_index
    if [ -f yarn.lock ]; then
        yarn install $@
    else
        npm install $@
    fi
}

# Skip husky?
# export HUSKY_SKIP_HOOKS=1

# Set up dual node environment
# see readme
export IS_ROSETTA_X86="$(sysctl -n sysctl.proc_translated)"

if [ $IS_ROSETTA_X86 = "1" ]; then
    local brew_path="/usr/local/homebrew/bin"
    local brew_opt_path="/usr/local/opt"
    local nvm_path="$HOME/.nvm-x86"
else
    local brew_path="/opt/homebrew/bin"
    local brew_opt_path="/opt/homebrew/opt"
    local nvm_path="$HOME/.nvm"
fi

export PATH="${brew_path}:${PATH}"
export NVM_DIR="${nvm_path}"

[ -s "${brew_opt_path}/nvm/nvm.sh" ] && . "${brew_opt_path}/nvm/nvm.sh"  # This loads nvm
[ -s "${brew_opt_path}/nvm/etc/bash_completion.d/nvm" ] && . "${brew_opt_path}/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


#pyenv and virtualenv
# export PATH=$(pyenv root)/shims:$PATH
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/exrhizo/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/exrhizo/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/exrhizo/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/exrhizo/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
