
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

function hgrep() { cat -n ~/.zsh_history | grep "$1"; }

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/env-rhizo/bin:$PATH"


# https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py
export FSLDIR="$HOME/opt/fsl"
. "$FSLDIR/etc/fslconf/fsl.sh"
export PATH="$FSLDIR/bin:$PATH"
export FSLOUTPUTTYPE=NIFTI_GZ
# export PATH="$HOME/opt/mrtrix3/bin:$PATH"
export PATH="$HOME/pkg/MRtrix3Tissue/bin:$PATH"

export EDITOR=vim

HISTFILE=$HOME/.zsh_history
HISTSIZE=200000
SAVEHIST=200000

setopt APPEND_HISTORY        # don’t clobber on exit
setopt INC_APPEND_HISTORY    # write each command as you run it
setopt SHARE_HISTORY         # merge across terminals
setopt EXTENDED_HISTORY      # timestamps & durations
setopt HIST_IGNORE_SPACE     # lines starting with space aren’t saved
setopt HIST_REDUCE_BLANKS