# TODO Notes on a faster installer.
#
# This part would run
#   sudo sh -c "$(wget -qO - https://flatheadmill.github.io/install.sh)"
# and that would redirect to the right place.
#
# No that's too much typing...
#
#   curl https://dotctl.sh | sudo sh
#
# It would detect the platform and distribution and then install all the basic
# dependencies and any missing locales.
#
# It would then call the `zsh` installer. It's been years and I haven't had to
# install this on a machine where I didn't have root.
