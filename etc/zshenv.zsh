# Ignore all operating specific configuration. Take complete ownership of Zsh.
unsetopt GLOBAL_RCS

# +------+
# | PATH |
# +------+

# Build a deterministic PATH for every shell, not just interactive ones. This
# lives in zshenv rather than zshrc because a non-interactive shell -- a
# `zsh -c` from a script, from cron, or from an agent reaching in over Wicket --
# sources zshenv and skips zshrc, and a headless command wants the same tools on
# its path that an interactive shell has. Reset to a clean base, then prepend
# each toolchain directory that exists, skipping any already present.
export PATH=/bin:/usr/bin

function {
    typeset part directories=(
        ~/.local/bin
        ~/.dotfiles/bin
        ~/.asdf/shims
        /home/linuxbrew/.linuxbrew/bin
        /opt/homebrew/bin
        /usr/local/bin
        ~/.cargo/bin
        ~/go/bin
    )
    for part in "${(@Oa)directories}"; do
        if [[ -d $part ]] && (( ! ${path[(Ie)$part]} )); then
            export PATH=$part:$PATH
        fi
    done
}
