#!/bin/zsh

# This DIR
export ENVDIR=$HOME/env-rhizo

export EDITOR='subl -w'
export VISUAL=$EDITOR

FILE=$ENVDIR/secrets.sh && test -f $FILE && source $FILE

if [[$OS_TYPE == 'darwin'* ]]; then
  source $ENVDIR/env-mac.sh
else
  source $ENVDIR/env-ubuntu.sh
fi
