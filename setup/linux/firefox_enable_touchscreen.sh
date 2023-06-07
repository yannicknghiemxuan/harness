#!/usr/bin/env bash
# source:
# - https://www.youtube.com/watch?v=GsaH9ZWDWY8
# some guides mention a need to set this value to 1 (=enabled)
#   dom.w3c.touch_events.enabled
# the fact is as of Firefox 108, this value is set to 2 (=autodetect)
# so no need to do that.
# source:
# - https://stackoverflow.com/questions/25024197/how-to-make-sure-touch-events-are-enabled-in-firefox-desktop-browser
# wayland virtual keyboard issue:
# - https://askubuntu.com/questions/1405312/no-on-screen-keyboard-in-firefox
if [[ ! -f /etc/profile.d/use-xinput2.sh ]]; then
    echo export MOZ_USE_XINPUT2=1 | sudo tee /etc/profile.d/use-xinput2.sh
    echo "log out and back in now"
    echo "note: as of 17/12/2022, to be able to use the virtual keyboard in firefox you need to use Xorg instead of Wayland"
fi
