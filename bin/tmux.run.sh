#!/bin/bash

# When you shutdown, you want to kill only the program you're debugging and it's
# children, not these monitors. You're going to trust them to shutdown on their
# own, or else you can have a super kill that KILLs the entire process group.

if [ -e ~/.local/var/tmux.run.pid ]; then
    echo "previous instance $(<~/.local/var/tmux.run.pid) still running"
    exit 1
fi

# Get the script path.
cd "$(dirname "${BASH_SOURCE[0]}")"
tmux_run_path=$PWD

# Indices used to lookup `tmux` properties.
window_index=$1
pane_index=$2

# Get the parent process id and process group id.
psaxo=( $(ps axo pid,ppid | awk -v pid=$$ '$1 == pid { print }') )
echo "${psaxo[0]}" > ~/.local/var/tmux.run.pid
echo 1 > ~/.local/var/tmux.run.run

# Read a tmux variable that matches the current window and pane index.
function get_tmux_variable () {
    local variable_name=$1
    tmux list-panes -s -F "#{window_index} #{pane_index} #{$variable_name}" | \
    awk -v window=$window_index \
        -v pane=$pane_index \
        '$1 == window && $2 == pane { gsub(/^[0-9]+ [0-9]+ /, ""); print }'
}

# Change directory to the likely current working directory of the pane that
# launched the program.
cd "$(get_tmux_variable pane_current_path)"

# Utility to cehck if we should still be running.
function tmux_run_is_running () {
    [ -e ~/.local/var/tmux.run.run ]
}

# Utility to send a signal to all the processes in the process group.
function tmux_run_kill () {
    local signal=$1
    [ -z "$signal" ] && signal=TERM
    echo perl "$tmux_run_path/tmux.setpgrp.pl" "$tmux_run_path/tmux.kill.sh" $signal
}

# Export utilities.
export -f tmux_run_is_running tmux_run_kill

if [ -e ~/.tmux.run.rc ]; then
    . ~/.tmux.run.rc
fi

program=~/.local/var/tmux.run.sh

programs=(./{.,}tmux.run.*)
if [ ${#programs[@]} -ne 0 ]; then
    program=$(ls ./{.,}tmux.run.* | sort | head -n 1)
fi

# Run the development script.
if [ ! -x "$program" ] && [[ "$program" = *.sh ]]; then
    /bin/bash "$program" >> ~/.local/var/tmux.run.log 2>&1 &
else
    "$program" >> ~/.local/var/tmux.run.log 2>&1 &
fi

# Funny story. In a program I was launching a child in the background and
# getting the pid using `server=$?` instead of `server=$!` . The value of `$?`
# was `0` at that point in the program.  Then at the end of the program I kill
# the server so I `kill 0`. This meant that this script would exit here, after
# the program but before the wait.
#
# This left the PID file on the filesystem preventing me from running this
# script again without checking that the PID was indeed gone and removing it
# manually.
#
# Disheartening to find it exiting here when I'd yet to determine the cause. It
# seems like this utility has run without incident since I created it. When I
# found that I wasn't killing the background process, but was instead killing
# `0`. `kill 0` sends a `TERM` to all the members of the process group, so of
# course this program exited immediately. It was in the `wait` and it got a
# `TERM`. Going to leave this note here. The for the next time it happens.

# Wait for the script to finish.
wait $!

# Wait for everyone in the process group to finish.
while true; do
    pids=$(perl "$tmux_run_path/tmux.setpgrp.pl" "$tmux_run_path/tmux.children.sh" ${psaxo[@]})
    [ -z "$pids" ] && break
    sleep 0.25
done

# Remove run files.
rm -f ~/.local/var/tmux.run.run
rm -f ~/.local/var/tmux.run.pid

# Quietly exit.
exit 0
