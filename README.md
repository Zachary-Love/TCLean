# TCLean

Debloats a TCL Google TV over ADB. Apps are disabled, not uninstalled, so everything is reversible.

Tested on a TCL Google TV with Android 12, a Realtek chip and 1.8 GB RAM (low-RAM build). Package names vary by model. Missing ones are skipped.

## Setup

1. On the TV: Settings → System → About → press **Android TV OS build** 7 times.
2. Settings → System → Developer options → turn on **USB debugging**.
3. On the Mac: `brew install --cask android-platform-tools`
4. Find the TV's IP (Settings → Network & Internet) and export it: `export TV=192.168.1.50`
5. Run `./tclean.sh list` and accept the "Allow debugging?" prompt on the TV (tick "Always allow").

## Usage

```sh
./tclean.sh list    # show enabled packages
./tclean.sh clean   # disable bloat, halve animations
./tclean.sh undo    # restore everything
```

Reboot the TV after `clean`: `adb -s $TV:5555 reboot`

Before running `clean`, edit the `BLOAT` list in `tclean.sh` and delete the lines for any streaming apps you use.

## What `clean` does

- **Disables:** TCL extras (TV Guard, TCL Channel, store demo mode, promos, telemetry), the TCL firmware updater, preinstalled streaming apps, and minor Google/Android apps. See the `BLOAT` list.
- **Samba TV:** removes it for user 0. It tracks what's on screen for ads, and the firmware re-enables it on boot if it is only disabled.
- **Animations:** sets them to 0.5×.

It leaves alone the TV and tuner services, Realtek drivers, Google Play Services, Assistant/voice, Chromecast and AirPlay.

## Optional: replace the home screen with Projectivy

The Google TV launcher is the heaviest thing on a low-RAM TV.

1. Install **Projectivy Launcher** from the Play Store.
2. Make it the home screen and disable the stock launcher and setup wizard:
   ```sh
   adb -s $TV:5555 shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity
   adb -s $TV:5555 shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
   adb -s $TV:5555 shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
   ```
   `setupwraith` has to be disabled too while `launcherx` is off, or it shows a recovery screen. `./tclean.sh undo` re-enables both.
3. Google TV has no built-in browser. Install **TV Bro** from the Play Store if you want one.

### Photo slideshow wallpaper

Projectivy can rotate photos from a folder (Settings → Appearance → Wallpaper → Launcher Wallpaper → User-defined folder; needs Premium). To convert iPhone photos to 1920px JPEGs and push them to the TV:

```sh
mkdir -p /tmp/photos && for f in /path/to/photos/*; do b=$(basename "${f%.*}"); sips -s format jpeg -Z 1920 "$f" --out "/tmp/photos/$b.jpg"; done
adb -s $TV:5555 shell mkdir -p /sdcard/Pictures/Wallpaper
adb -s $TV:5555 push /tmp/photos/. /sdcard/Pictures/Wallpaper/
```

## Updating later

- **Apps:** Play Store auto-updates them, unless you turned that off.
- **TCL firmware:**
  1. `adb -s $TV:5555 shell pm enable com.tcl.ttvs`
  2. Check for updates in Settings → System.
  3. `./tclean.sh clean` to turn the updater back off.

## If something breaks

- **The TV drops off Wi-Fi:** wait a minute or power-cycle it. ADB comes back once it reconnects.
- **An app you use stopped working:** `adb -s $TV:5555 shell pm enable <package>`
- **To go back to the stock setup:** `./tclean.sh undo`, then reboot.
- **Last resort:** factory reset from the TV's recovery menu. This undoes everything, including your sign-ins.
