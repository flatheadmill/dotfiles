aws_zsh_completer=$(which aws_zsh_completer.sh 2> /dev/null)
if [[ $? -eq 0 ]]; then
    source $aws_zsh_completer
fi
