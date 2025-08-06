#!/bin/zsh

# This DIR
export ENVDIR=$HOME/env-rhizo

export EDITOR='subl -w'
export VISUAL=$EDITOR

FILE=$ENVDIR/secrets.sh && test -f $FILE && source $FILE

case $OS_TYPE in
  darwin*) source $ENVDIR/env-mac.sh;;
  *) source $ENVDIR/env-ubuntu.sh;;
esac