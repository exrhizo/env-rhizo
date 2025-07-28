#!/bin/zsh

# Easy find commands
function hgrep() { cat -n ~/.zsh_history | grep "$1"; }

# Use Gnu utils instead of mac's old crapy versions
# https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$HOME/env-rhizo/bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"


# export FREESURFER_HOME=/Applications/freesurfer
# export PATH="/opt/homebrew/Caskroom/freesurfer/7.4.1/freesurfer/bin:$PATH"


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
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

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
export NVM_DIR="${nvm_path}"
[ -s "${brew_opt_path}/nvm/nvm.sh" ] && . "${brew_opt_path}/nvm/nvm.sh"  # This loads nvm

# Docker compose menu
export COMPOSE_MENU=false


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/exrhizo/installs/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/exrhizo/installs/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
