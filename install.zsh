#!/usr/bin/env zsh

# Abnormal end.
function abend {
    typeset message
    printf -v message "$@"
    print -u 2 "fatal: $message"
}

# We don't want the operating system's Zsh skeleton rc and we don't want the
# garbage that installers append to our rc files. We wipe them out and we
# don't worry about losing anything.
#
# We source two files on startup, `~/.dotfiles/etc/foo.rc` is our `git`
# managed installation of `foo`. `~/.local/etc/foo.rc` is our local, untracked
# changes specific to the current machine.
function create_rc {
    typeset home_file=$1 skel_file=$2
    typeset home_path="$HOME/$home_file" skel_path="$HOME/.dotfiles/skel/$skel_file"
    if [[ -e $home_path ]] && ! diff -q "$home_path" "$skel_path" > /dev/null; then
        mkdir -p "$HOME/.dotfiles/replaced/$stamp"
        mv "$home_path" "$HOME/.dotfiles/replaced/$stamp/$skel_file"
    fi
    cp "$skel_path" "$home_path"
    typeset local_path="$HOME/.local/etc/$skel_file"
    if [[ ! -e "$local_path" ]]; then
        mkdir -p "$HOME/.local/etc"
        touch "$local_path"
    fi
}

# Anonymous function, run once.
function {
    typeset tmp
    tmp=$(mktemp -d) || abend 'cannot create temporary directory'
    {
        # Must change shell to Zsh before installation. Why?
        [[ ${SHELL:t} = zsh ]] || abend 'change your shell to Zsh before installing'
        # `git` is required to install.
        whence git > /dev/null || abend 'git is not installed' 
        typeset git_version
        git_version=${"$(git version)"##* } || abend 'cannot read git version'
        (( ${git_version%%.*} >= 2 )) || abend 'git is at version %s but must be at least 2.0.0' $git_version
        # Create an `~/.ssh/known_hosts`.
        umask 077
        {
            mkdir -p ~/.ssh || abend 'cannot create `~/.ssh`'
            touch ~/.ssh/known_hosts || abend 'cannot create `~/.ssh/known_hosts`'
        } always {
            umask 022
        }
        # Add a verified `github.com` host key to our `~/.ssh/known_hosts`.
        typeset key hosts
        # If we have a key for `github.com` already, do nothing.
        if [[ $(ssh-keygen -F github.com | wc -c) -eq 0 ]]; then
            # Get the public key from the `github.com` server.
            key=$(ssh-keyscan -t ed25519 github.com 2> /dev/null | cut -f3 -d' ') ||
                abend 'unable to fetch `github.com` SSH keys'

            # Create a comma delimited list of host ip addresses and the domain.
            hosts=$(print $(dig -t a +short github.com  | tr '\n' ',')github.com) ||
                abend 'unable to resolve `github.com` DNS'

            # Get that fingerprint.
            fp=$(ssh-keygen -t ed25519 -q -l -f <(printf '%s ssh-ed25519 %s\n' $hosts $key) -F github.com | cut -f3 -d' ')

            # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
            [[ $fp = "SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU" ]] ||
                abend 'bad `github.com` SSH fingerprint %s' $fp
            printf '%s ssh-ed25519 %s\n' >> ~/.ssh/known_hosts
        fi
        # Assert that we can call `git`.
        # https://superuser.com/questions/227509/git-ping-check-if-remote-repository-exists
        git ls-remote git@github.com:flatheadmill/dotfiles.git unlikely_reference ||
            abend 'unable to reach `flatheadmill/dotfiles.git`, did you forget to port forward?'
        # Clone dotfiles.
        if [[ ! -e "$HOME/.dotfiles" ]]; then
            git clone --recursive git@github.com:flatheadmill/dotfiles.git "$HOME/.dotfiles"
        fi
        # Create our `~/.local` filesystem.
        mkdir -p ~/.local/{bin,share,state,tmp,var}
        touch ~/.local/var/tmux.run.log
        # Bootstrap `vim` by installing `vim-plug`.
        curl --fail -sSfLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim ||
                abend 'unable to install `vim-plug`'
        # Create a directory for extensions.
        mkdir -p ~/.dotfiles/vendor
        # Install `subnixr/minimal` theme.
        # https://github.com/subnixr/minimal
        curl -sL https://raw.githubusercontent.com/subnixr/minimal/master/minimal.zsh > ~/.dotfiles/vendor/minimal.zsh
        # Add TMUX Plugin Manager.
        # https://github.com/tmux-plugins/tpm
        if [[ ! -d ~/.tmux/plugins/tpm ]]; then
            git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        fi
        # Timestamp for our rc file sweep.
        typeset stamp=$(date +'%F-%T' | sed 's/:/-/g')
        # Emplace our Zsh configuration.
        create_rc .zshenv zshenv.zsh
        create_rc .zprofile zprofile.zsh
        create_rc .zshrc zshrc.zsh
        create_rc .zlogin zprofile.zsh
        create_rc .zlogout zprofile.zsh
        # Emplace our TMUX configuration.
        create_rc .tmux.conf tmux.conf
        # Emplace our Vim configuration.
        create_rc .vimrc vimrc
        # Emplace our `git` configuration.
        create_rc .gitconfig gitconfig
        # Could as easily be in my standard config, but I keep it here to
        # remind myself that this is how you tweak local installations.
        git config --file ~/.local/etc/gitconfig --add user.name 'Alan Gutierrez'
        git config --file ~/.local/etc/gitconfig --add user.email 'alan@prettyrobots.com'
        git config --file ~/.local/etc/gitconfig --add github.user 'flatheadmill'
        # Announce. TODO Sweep to `~/.local`.
        if [[ -d "$HOME/.dotfiles/replaced/$stamp" ]]; then
            cat <<'            EOF' | sed 's/^            //'
            Existing configuration files where replaced. The replaced files have been
            moved to:

              ~/.dotfiles/replaced/$stamp

            Fish out anything you want to keep and move it to the file with the same name in
            the directory:

              ~/.dotfiles/rc

            This is where your machine specific settings should be kept.
            EOF
        fi
    } always {
        [[ -d $tmp ]] && rm -rf $tmp
    }
}
