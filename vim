#!/bin/bash

run_vim() {
    # Remove current dir from $PATH to avoid infinite recursion
    MYDIR="$(dirname $(readlink -f "$0"))"
    MYNAME="$(basename "$0")"
    NEWPATH=$(echo $PATH | sed -r -e "s,${MYDIR}/?:,,")
    VIMBIN=$(PATH=$NEWPATH which "$MYNAME")

    if [[ -n $RANGER_LEVEL && -n $TMUX ]]; then
        # Hacky quoting preservation
        declare -a files
        for i in "$@"; do
            i=\"$i\"
            files=( $files "$i" )
        done
        CMD="command $VIMBIN "${files[@]}""

        tmux new-window -a -c '#{pane_current_path}' "$CMD"
    else
        command $VIMBIN "$@"
    fi
}

if [[ -n $TMUX ]]; then
    [[ -z "$SUDO_USER" ]] && OLDTITLE=$(tmux display-message -p "#{pane_title}")

    run_vim "$@"
    RET=$?

    [[ -z "$SUDO_USER" ]] && echo -e "\e]0;${OLDTITLE}\e\\"

    exit $RET
else
    run_vim "$@"
fi
