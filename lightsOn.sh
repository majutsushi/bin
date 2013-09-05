#!/bin/bash
# lightsOn.sh

# Copyright (c) 2011 iye.cba at gmail com
# url: https://github.com/iye/lightsOn
# This script is licensed under GNU GPL version 2.0 or above

# Description: Bash script that prevents the screensaver and display power
# management (DPMS) to be activated when you are watching Flash Videos
# fullscreen on Firefox and Chromium.
# Can detect mplayer and VLC when they are fullscreen too but I have disabled
# this by default.
# lightsOn.sh needs xscreensaver, kscreensaver or gnome-screensaver to work.

# HOW TO USE: Start the script with the number of seconds you want the checks
# for fullscreen to be done. Example:
# "./lightsOn.sh 120 &" will Check every 120 seconds if Mplayer,
# VLC, Firefox or Chromium are fullscreen and delay screensaver and Power Management if so.
# You want the number of seconds to be ~10 seconds less than the time it takes
# your screensaver or Power Management to activate.
# If you don't pass an argument, the checks are done every 50 seconds.


# enumerate all the attached screens
displays=""
while read id
do
    displays="$displays $id"
done< <(xvinfo | sed -n 's/^screen #\([0-9]\+\)$/\1/p')

# Detect screensaver been used (xscreensaver, kscreensaver, gnome-screensaver or none)
if [ $(pgrep -c xscreensaver) -ge 1 ]; then
    screensaver=xscreensaver
elif [ $(pgrep -c gnome-screensav) -ge 1 ]; then
    screensaver=gnome-screensav
elif [ $(pgrep -c kscreensaver) -ge 1 ]; then
    screensaver=kscreensaver
else
    screensaver=None
    echo "No screensaver detected"
fi


checkFullscreen()
{
    # loop through every display looking for a fullscreen window
    for display in $displays; do
        # get id of active window and clean output
        activ_win_id=$(DISPLAY=:0.${display} xprop -root _NET_ACTIVE_WINDOW)
        # activ_win_id=${activ_win_id#*# } # gives error if xprop returns extra ", 0x0" (happens on some distros)
        activ_win_id=${activ_win_id:40:9}

        if [[ $activ_win_id == 0x0 ]]; then
             continue
        fi

        # Check if Active Window (the foremost window) is in fullscreen state
        isActivWinFullscreen=$(DISPLAY=:0.${display} xprop -id $activ_win_id | grep _NET_WM_STATE_FULLSCREEN)
        if [[ $isActivWinFullscreen =~ NET_WM_STATE_FULLSCREEN ]]; then
            if isAppRunning; then
                delayScreensaver
            fi
        fi
    done
}

isAppRunning()
{
    # Get title of active window
    activ_win_title=$(xprop -id $activ_win_id | grep "WM_CLASS(STRING)")

    # Firefox Flash
    if [[ $activ_win_title =~ unknown || $activ_win_title =~ plugin-container ]]; then
        if [[ $(pgrep -c plugin-containe) -ge 1 ]]; then
            return 0
        fi
    fi

    # Chromium Flash
    if [[ $activ_win_title =~ exe ]]; then
        if [[ $(pgrep -fc "chromium-browser --type=plugin --plugin-path=/usr/lib/adobe-flashplugin") -ge 1 || $(pgrep -fc "chromium-browser --type=plugin --plugin-path=/usr/lib/flashplugin-installer") -ge 1 ]]; then
            return 0
        fi
    fi

    # html5 (Firefox or Chromium full-screen)
    if [[ $activ_win_title =~ chromium-browser || $activ_win_title =~ Firefox ]]; then
        if [[ $(pgrep -c firefox) -ge 1 || $(pgrep -c chromium-browse) -ge 1 ]]; then
            return 0
        fi
    fi

    # MPlayer
    if [[ $activ_win_title =~ mplayer || $activ_win_title =~ MPlayer ]]; then
        if [[ $(pgrep -c mplayer) -ge 1 ]]; then
            return 0
        fi
    fi

    # VLC
    if [[ $activ_win_title =~ vlc ]]; then
        if [[ $(pgrep -c vlc) -ge 1 ]]; then
            return 0
        fi
    fi

    # Higan
    if [[ $activ_win_title =~ phoenix ]]; then
        if [[ $(pgrep -c higan) -ge 1 ]]; then
            return 0
        fi
    fi

    # Wine (for games)
    if [[ $activ_win_title =~ Wine ]]; then
        if [[ $(pgrep -c wine) -ge 1 ]]; then
            return 0
        fi
    fi

    return 1
}


delayScreensaver()
{
    xdotool key shift
    # # reset inactivity time counter so screensaver is not started
    # if [[ $screensaver == xscreensaver ]]; then
    #     # This tells xscreensaver to pretend that there has just been user
    #     # activity. This means that if the screensaver is active (the screen
    #     # is blanked), then this command will cause the screen to un-blank as
    #     # if there had been keyboard or mouse activity. If the screen is
    #     # locked, then the password dialog will pop up first, as usual. If the
    #     # screen is not blanked, then this simulated user activity will
    #     # re-start the countdown (so, issuing the -deactivate command
    #     # periodically is one way to prevent the screen from blanking.)
    #     xscreensaver-command -deactivate > /dev/null
    # elif [[ $screensaver == gnome-screensav ]]; then
    #     dbus-send --session --type=method_call --dest=org.gnome.ScreenSaver --reply-timeout=20000 /org/gnome/ScreenSaver org.gnome.ScreenSaver.SimulateUserActivity > /dev/null
    # elif [[ $screensaver == kscreensaver ]]; then
    #     qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    # fi


    # # Check if DPMS is on. If it is, deactivate and reactivate again. If it is
    # # not, do nothing.
    # dpmsStatus=$(xset -q | grep -ce 'DPMS is Enabled')
    # if [ $dpmsStatus == 1 ]; then
    #     xset -dpms
    #     xset +dpms
    # fi
}


delay=$1

if [ -z "$1" ];then
    delay=5m
fi

while true
do
    checkFullscreen
    sleep $delay
done
