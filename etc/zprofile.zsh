return

if [[ $OSTYPE = darwin* ]]; then
    if [[ $(uname -m) = arm64 && -e /opt/homebrew/bin ]]; then
        export PATH=/opt/homebrew/bin:$PATH
    fi
    if [[ -e "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc" ]]; then
        source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
    fi
fi

if [[ -e "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

if [[ -e "$HOME/.gvm/scripts/gvm" ]]; then
    source "$HOME/.gvm/scripts/gvm"
fi

if [[ -e "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

if whence kapp > /dev/null; then
    source <(kapp completion zsh | sed '/Succeeded/d')
fi
