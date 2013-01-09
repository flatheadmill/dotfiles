git_path=$(which git)
git_prefix=${git_path%/*/git}

if [ -e "${git_prefix}/etc/bash_completion.d/git-completion.bash" ]; then
  . "${git_prefix}/etc/bash_completion.d/git-completion.bash"
fi
