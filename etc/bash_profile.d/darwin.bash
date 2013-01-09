if [ "$(uname)" = "Darwin" ]; then
  export CLICOLOR=1
  export LSCOLORS=ExFxBxDxCxegedabagacad

  if [ -e /opt/etc/bash_completion.d/git-completion.bash ]; then
    . /opt/etc/bash_completion.d/git-completion.bash
  fi
fi
