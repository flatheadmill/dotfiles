if [[ $OSTYPE == darwin* && -e "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc" ]]; then
    source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
fi

if [[ -e "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

if [[ -e "$HOME/.gvim/scripts/gvm" ]]; then
    source /home/homeport/.gvm/scripts/gvm
fi
