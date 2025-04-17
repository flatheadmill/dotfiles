#!/bin/sh

# Implemented in POSIX shell.

# Abenormal end.
abend() {
    local message=$(printf "$@")
    printf 'fatal: %s\n' "$message" 1>&2
    exit 1
}

create_rc() {
    local home_file=$1 skel_file=$2
    local home_path="$HOME/$home_file" skel_path="$HOME/.dotfiles/skel/$skel_file"
    local destination
    if [ -e "$home_path" ] && ! diff -q "$home_path" "$skel_path" > /dev/null; then
        mkdir -p "$HOME/.local/var/dotfiles/replaced/$stamp"
        destination="$HOME/.local/var/dotfiles/replaced/$stamp/$skel_file"
        mkdir -p "${destination%/*}"
        mv "$home_path" "$destination"
    fi
    mkdir -p "${home_path%/*}"
    cp "$skel_path" "$home_path"
    local local_path="$HOME/.local/etc/$skel_file"
    if [ ! -e "$local_path" ]; then
        mkdir -p "$HOME/.local/etc"
        mkdir -p "${local_path%/*}"
        touch "$local_path"
    fi
}

announce_copy() {
cat <<EOF
Existing configuration files where replaced. The replaced files have been
moved to:

  ~/.local/var/dotfiles/replaced/$stamp

Files swept.

$(cd ~ && find .local/var/dotfiles/replaced/$stamp -type f | sed 's,^,  ~/,')

Fish out anything you want to keep and move it to the file with the same name in
the directory:

  ~/.local/etc

This is where your machine specific settings should be kept.
EOF
}

main() {
    # `git` is required to install.
    which git > /dev/null || abend 'git is not installed' 
    local git_version
    git_version=$(git version) || abend 'cannot read git version'
    git_version=${git_version##* }
    [ "${git_version%%.*}" -ge 2 ] || abend 'git is at version %s but must be at least 2.0.0' "$git_version"
    # Create a `~/.ssh/known_hosts`.
    (
        umask 077
        mkdir -p ~/.ssh || abend 'cannot create `~/.ssh`'
        touch ~/.ssh/known_hosts || abend 'cannot create `~/.ssh/known_hosts`'
    )
    # Timestamp for our rc file sweep.
    local stamp=$(date +'%F-%T' | sed 's/:/-/g')
    # Emplace our Zsh configuration.
    create_rc .zshenv zshenv.zsh
    create_rc .zprofile zprofile.zsh
    create_rc .zshrc zshrc.zsh
    create_rc .zlogin zprofile.zsh
    create_rc .zlogout zprofile.zsh
    # Emplace our Bash configuration.
    create_rc .profile profile
    create_rc .bashrc bashrc
    # Emplace our TMUX configuration.
    create_rc .tmux.conf tmux.conf
    # Emplace our Vim configuration.
    create_rc .vimrc vimrc
    # Emplace our `git` configuration.
    create_rc .gitconfig gitconfig
    # Emplace our `ssh` configuration.
    create_rc .ssh/config ssh/config
    touch ~/.ssh/homeport.config
    if [ -z "$(ssh-keygen -F github.com)" ]; then
        local key hosts
        # Get the public key from the `github.com` server.
        key=$(ssh-keyscan -t ed25519 github.com 2> /dev/null | cut -f3 -d' ') ||
            abend 'unable to fetch `github.com` SSH keys'
        # Create a comma delimited list of host ip addresses and the domain.
        hosts=$(printf '%sgithub.com' "$(dig -t a +short github.com  | tr '\n' ',')") ||
            abend 'unable to resolve `github.com` DNS'
        # Get that fingerprint.
        fp=$(printf '%s ssh-ed25519 %s' "$hosts" "$key" | ssh-keygen -qlf - | cut -f2 -d' ')
        # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
        [ "$fp" = "SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU" ] ||
            abend 'bad `github.com` SSH fingerprint %s' "$fp"
        printf '%s ssh-ed25519 %s\n' $hosts $key >> ~/.ssh/known_hosts
    fi
    # Assert that we can call `git`.
    # https://superuser.com/questions/227509/git-ping-check-if-remote-repository-exists
    git ls-remote git@github.com:flatheadmill/dotfiles.git unlikely_reference ||
        abend 'unable to reach `flatheadmill/dotfiles.git`, did you forget to forward SSH?'
    # Clone dotfiles.
    if [ ! -e "$HOME/.dotfiles" ]; then
        git clone --recursive git@github.com:flatheadmill/dotfiles.git "$HOME/.dotfiles"
    fi
    # Create our `~/.local` filesystem.
    mkdir -p ~/.local/etc/zshrc.d
    local dir
    for dir in bin share state tmp var; do
        mkdir -p ~/.local/$dir
    done
    touch ~/.local/var/tmux.run.log
    curl -sSL https://raw.githubusercontent.com/subnixr/minimal/master/minimal.zsh > ~/.local/etc/zshrc.d/minimal.zsh
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git ls-remote https://github.com/tmux-plugins/tpm unlikely_reference ||
            abend 'unable to reach `tmux-plugins/tpm.git`'
        git clone -q https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    # Bash configuration.
    mkdir -p ~/.config/bash/plugins
    git_clone ~/.config/bash/plugins/aphrodite https://github.com/win0err/aphrodite-terminal-theme
    # Could as easily be in my standard config, but I keep it here to
    # remind myself that this is how you tweak local installations.
    git config --file ~/.local/etc/gitconfig --add user.name 'Alan Gutierrez'
    git config --file ~/.local/etc/gitconfig --add user.email 'alan@prettyrobots.com'
    git config --file ~/.local/etc/gitconfig --add github.user 'flatheadmill'
    if [ -d "$HOME/.local/var/dotfiles/replaced/$stamp" ]; then
        announce_copy
    fi
}

git_clone() {
    local directory=$1 url=$2
    if [ ! -d "$directory" ]; then
        git clone --quiet "$url" "$directory" || abend 'unabled to clone `%s`.' "$url"
    fi
}

main
