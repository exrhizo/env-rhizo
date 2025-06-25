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
function hgrep() { history | grep "$1"; }

# Use sublimetext for editing config files
alias zshconfig="subl $ENVDIR/zshrc.sh"
alias envconfig="subl $ENVDIR/env.sh"

# Use Gnu utils instead of mac's old crapy versions
# https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$HOME/env-rhizo:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"


# Graphistry related
alias ssh-dev="ssh -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem ubuntu@louie-dev.grph.xyz"
alias ssh-prod="ssh -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem ubuntu@den.louie.ai"
alias ssh-precog="ssh -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem ubuntu@louie-precog.grph.xyz"
alias scp-dev="scp -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem"
alias scp-prod="scp -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem"

alias mymy="fswatch -o --exclude '.*cache.*' graphistrygpt | while read -r; do MYPY_OUTPUT=\$(mypy --config-file graphistrygpt/mypy.ini graphistrygpt 2>&1); RUFF_OUTPUT=\$(ruff check ./graphistrygpt 2>&1); reset; echo \"\$MYPY_OUTPUT\"; echo \"\$RUFF_OUTPUT\"; done"
alias lupg='(set -a; source system.env; set +a; echo "postgresql://${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}"; PGPASSWORD=$POSTGRES_PASSWORD psql "postgresql://${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}")'
export PYTEST_DC=./dcc

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

loadenv () {
  [ -f "$1" ] || { echo "usage: loadenv <file>"; return 1; }
  set -a
  source "$1"
  set +a
}

# Skip husky?
# export HUSKY_SKIP_HOOKS=1

# Set up dual node environment
# see readme
export IS_ROSETTA_X86="$(sysctl -n sysctl.proc_translated)"

if [ $IS_ROSETTA_X86 = "1" ]; then
    brew_path="/usr/local/homebrew/bin"
    brew_opt_path="/usr/local/opt"
    nvm_path="$HOME/.nvm-x86"
else
    brew_path="/opt/homebrew/bin"
    brew_opt_path="/opt/homebrew/opt"
    nvm_path="$HOME/.nvm"
fi

export PATH="${brew_path}:${PATH}"

# brew did keg only so it didn't conflict with mysql package
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export NVM_DIR="${nvm_path}"

# Docker compose menu
export COMPOSE_MENU=false

[ -s "${brew_opt_path}/nvm/nvm.sh" ] && . "${brew_opt_path}/nvm/nvm.sh"  # This loads nvm

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/exrhizo/installs/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/exrhizo/installs/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.




