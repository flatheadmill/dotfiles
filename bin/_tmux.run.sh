#!/bin/bash

# When you shutdown, you want to kill only the program you're debugging and it's
# children, not these monitors. You're going to trust them to shutdown on their
# own, or else you can have a super kill that KILLs the entire process group.

if [ -e ~/.usr/tmp/tmux.run.pid ]; then
    echo "previous instance $(<~/.usr/tmp/tmux.run.pid) still running"
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
echo "${psaxo[0]}" > ~/.usr/tmp/tmux.run.pid
echo 1 > ~/.usr/tmp/tmux.run.run

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
    [ -e ~/.usr/tmp/tmux.run.run ]
}

# Utility to send a signal to all the processes in the process group.
function tmux_run_signal () {
    local signal=$1
    [ -z "$signal" ] && signal=TERM
    echo perl "$tmux_run_path/_tmux.setpgrp.pl" "$tmux_run_path/_tmux.signal.sh" $signal
}

# Export utilities.
export -f tmux_run_is_running tmux_run_signal

if [ -e ~/.tmux.run.rc ]; then
    . ~/.tmux.run.rc
fi

program=~/.usr/bin/tmux.run.sh

programs=(./{.,}tmux.run.*)
if [ ${#programs[@]} -ne 0 ]; then
    program=$(ls ./{.,}tmux.run.* | sort | head -n 1)
fi

# Run the development script.
if [ ! -x "$program" ] && [[ "$program" = *.sh ]]; then
    /bin/bash "$program" >> ~/.usr/tmp/tmux.run.log 2>&1 &
else
    "$program" >> ~/.usr/tmp/tmux.run.log 2>&1 &
fi

# Wait for the script to finish.
wait $!

# Wait for everyone in the process group to finish.
while true; do
    pids=$(perl "$tmux_run_path/_tmux.setpgrp.pl" "$tmux_run_path/_tmux.children.sh" ${psaxo[@]})
    [ -z "$pids" ] && break
    sleep 0.25
done

# Remove run files.
rm -f ~/.usr/tmp/tmux.run.run
rm -f ~/.usr/tmp/tmux.run.pid

# Quietly exit.
exit 0
