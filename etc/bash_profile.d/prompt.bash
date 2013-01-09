# I prefer a verbose naming convention for AWS servers, so I shorten the names
# that match that AWS server pattern. It might be better to simply shorten any
# name that is more than four parts and assume it is a machine named according
# to some convention that is recongnizable by the first letter of each part.
function generate_prompt()
{
    hostname=$(/bin/hostname)
    pattern="^([a-z]+)\\."
    pattern+="(user|data|balance|image)\\."
    pattern+="(north|south|east|west)\\."
    pattern+="(california|louisiana|oregon|virginia)\\."
    pattern+="runpup\\.(com|net)$"
    if [[ $hostname =~ $pattern ]]; then
        terse=
        separator=
        i=1
        n=${#BASH_REMATCH[*]}
        let n--
        while [[ $i -lt $n ]]
        do
            terse="${terse}${separator}${BASH_REMATCH[$i]:0:1}"
            separator=.
            let i++
        done
        echo $terse
    else
        echo $hostname | sed 's/^\([^.][^.]*\)\.[^.][^.]*$/\1/' | sed 's/\(\.[^.][^.]*\)\{2\}$//'
    fi
}

# Set variable identifying the chroot you work in (used in the prompt below).
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Set a fancy prompt (non-color, unless we know we "want" color).
case "$TERM" in
    xterm-*color) color_prompt=yes;;
    screen-*color) color_prompt=yes;;
esac

# Uncomment for a colored prompt, if the terminal has the capability; turned off
# by default to not distract the user: the focus in a terminal window should be
# on the output of commands, not on the prompt
#force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48 (ISO/IEC-6429).
  # (Lack of such support is extremely rare, and such a case would tend to
  # support setf rather than setaf.)
  color_prompt=yes
    else
	color_prompt=
   fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}[\[\033[01;32m\]\u@'`generate_prompt`'\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$] '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
export PS1
unset color_prompt force_color_prompt
