# Ignore all operating specific configuration. Take complete ownership of Zsh.
unsetopt GLOBAL_RCS

# TMUX will always start us as a login shell, so we are always going to
# inherit the `$PATH` of the terminal. We reset it here and set it explicitly.
export PATH=/bin:/usr/bin

# Operating systems in which we currently run are OS X, Ubuntu, and Apache.
case $OSTYPE in
    linux-gnu )
        ;;
esac
