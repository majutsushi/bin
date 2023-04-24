#!/usr/bin/env bash

run_vim() {
    # Remove script dir from $PATH to avoid infinite recursion
    MYDIR="$(dirname "$(readlink -f "$0")")"
    MYNAME="$(basename "$0")"
    NEWPATH=$(echo "$PATH" | sed -r -e "s,${MYDIR}/?:,,")
    VIMBIN=$(PATH=$NEWPATH command -v "$MYNAME")

    if [[ -n $RANGER_LEVEL && -n $TMUX ]]; then
        CMD="command $VIMBIN$(printf " %q" "$@")"

        tmux new-window -a -c '#{pane_current_path}' "$CMD"
    elif [[ -n $RANGER_LEVEL && "$TERM" == xterm-kitty ]]; then
        kitty @ launch --type tab --no-response --cwd current "$VIMBIN" "$@"
    else
        command $VIMBIN "$@"
    fi
}

if [[ -n $TMUX ]]; then
    [[ -z "$SUDO_USER" ]] && OLDTITLE=$(tmux display-message -p "#{pane_title}")

    run_vim "$@"
    RET=$?

    [[ -z "$SUDO_USER" ]] && printf '\e]0;%s\e'\\ "${OLDTITLE}"

    exit $RET
else
    run_vim "$@"
fi
