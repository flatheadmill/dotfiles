aws_zsh_completer=$(which aws_zsh_completer.sh)
if [[ $? -eq 0 ]]; then
    source $aws_zsh_completer
fi
