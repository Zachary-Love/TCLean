#!/usr/bin/env bash
# Debloat a TCL Google TV over ADB. Disables (doesn't uninstall) so everything is reversible.
# usage: TV=<tv-ip> ./tclean.sh [list|clean|undo]
set -u
TV=${TV:?set TV to the TV IP, e.g. TV=192.168.1.50 ./tclean.sh list}

# ponytail: conservative starter list; names vary by model, missing ones are skipped. Grow it from `./tclean.sh list`.
BLOAT=(
  tv.samba.ssm.ui                # Samba TV: screen-content tracking (ACR)
  com.tcl.guard                  # "TV Guard" scanner, a known CPU hog
  com.tcl.channelplus            # TCL Channel ads/FAST
  com.tcl.esticker               # store-demo sticker overlay
  com.tcl.exhibit                # store-demo mode
  com.tcl.hotelmenu
  com.tcl.repairguide
  com.tcl.ocean.instructions     # on-screen manual
  com.tcl.messagebox             # TCL push messages/promos
  com.tcl.logkit                 # TCL telemetry/logging
  com.tcl.usercenter             # TCL account
  com.tcl.ttvs                   # TCL firmware updater (~76MB); enable to update
  com.tcl.gamebar
  com.tcl.smartalexa
  com.google.android.feedback
  com.google.android.marvin.talkback
  com.google.android.play.games
  com.android.printspooler
  com.android.wallpaper.livepicker
  # preinstalled streaming apps; delete the lines for ones you use
  com.amazon.amazonvideo.livingroom
  com.apple.atve.androidtv.appletv
  com.crunchyroll.crunchyroid
  com.google.android.youtube.tvmusic
  com.google.android.youtube.tvunplugged
  com.hulu.livingroomplus
  com.iqiyi.i18n.tv
  com.peacocktv.peacockandroid
  com.tubitv
  com.wbd.stream
  tv.pluto.android
)

adb connect "$TV:5555" >/dev/null
adb -s "$TV:5555" get-state >/dev/null 2>&1 || { echo "Not connected. Accept the prompt on the TV and rerun."; exit 1; }
sh() { adb -s "$TV:5555" shell "$@"; }

case "${1:-list}" in
  list) sh pm list packages -e | sed 's/package://' | sort ;;
  clean)
    for p in "${BLOAT[@]}"; do sh pm disable-user --user 0 "$p" 2>/dev/null | grep -q 'disabled' && echo "disabled $p"; done
    # Firmware re-enables Samba TV on boot, so remove it for user 0 instead.
    sh pm uninstall --user 0 tv.samba.ssm.ui >/dev/null 2>&1 && echo "removed tv.samba.ssm.ui"
    # Halving animations is the biggest perceived speedup.
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do sh settings put global $k 0.5; done
    echo "Done. Reboot the TV: adb -s $TV:5555 reboot" ;;
  undo)
    sh cmd package install-existing tv.samba.ssm.ui >/dev/null 2>&1
    # Projectivy swap: setupwraith first, or it shows its recovery screen.
    sh pm enable --user 0 com.google.android.tungsten.setupwraith >/dev/null 2>&1
    sh pm enable --user 0 com.google.android.apps.tv.launcherx >/dev/null 2>&1
    sh cmd package set-home-activity com.google.android.apps.tv.launcherx/.home.HomeActivity >/dev/null 2>&1
    for p in "${BLOAT[@]}"; do sh pm enable --user 0 "$p" >/dev/null 2>&1; done
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do sh settings put global $k 1; done
    echo "Restored." ;;
  *) echo "usage: $0 [list|clean|undo]"; exit 1 ;;
esac
