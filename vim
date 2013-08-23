#!/bin/bash

run_vim() {
    # Remove current dir from $PATH to avoid infinite recursion
    MYDIR="$(dirname $(readlink -f "$0"))"
    NEWPATH=$(echo $PATH | sed -r -e "s,${MYDIR}/?:,,")
    VIMBIN=$(PATH=$NEWPATH which vim)
    command $VIMBIN "$@"
}

if [[ -n $TMUX ]]; then
    OLDTITLE=$(tmux display-message -p "#{pane_title}")

    run_vim "$@"

    echo -e "\e]0;${OLDTITLE}\e\\"
else
    run_vim "$@"
fi
