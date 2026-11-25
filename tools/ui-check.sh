#!/bin/sh
# Installs a built Files on a running emulator (adb) and takes screenshots,
# to see the themes work without a phone:
#
#   tools/ui-check.sh APK OUT_DIR
#
# OUT_DIR gets:
#   1-system-light.png   the file list, the phone in light mode
#   2-system-dark.png    the same, the phone in dark mode
#   3-settings.png       Settings, the phone in light mode
#   4-night-on.png       Settings after choosing Night mode: On
#   5-after-night-on.png the file list after that, the phone still light
#   6-archive.png        what tapping an archive in Download does
#   app-log.txt          everything the app wrote to Android's log (should
#                        be nothing)

set -eu
apk=$1
out=$2
pkg=io.github.files.app
mkdir -p "$out"
tools=$(dirname "$0")

adb install -r "$apk"
# All-files access, so the file list shows files rather than asking.
adb shell appops set "$pkg" MANAGE_EXTERNAL_STORAGE allow || true
adb shell pm grant "$pkg" android.permission.POST_NOTIFICATIONS || true
adb logcat -c || true
# An archive to tap.
python3 -I -c "import sys, zipfile; zipfile.ZipFile(sys.argv[1], 'w').writestr('hello.txt', 'hello')" "$out/archive-check.zip"
adb push "$out/archive-check.zip" /sdcard/Download/archive-check.zip >/dev/null

shot() {
    sleep 5
    adb exec-out screencap -p >"$out/$1.png"
}
open_files() {
    adb shell am force-stop "$pkg"
    adb shell am start -W -n "$pkg/me.zhanghai.android.files.filelist.FileListActivity" >/dev/null
}
# Taps the middle of the first thing on screen whose text is $1.
tap() {
    adb shell uiautomator dump /sdcard/ui.xml >/dev/null
    adb shell cat /sdcard/ui.xml >"$out/ui.xml"
    xy=$(python3 -I "$tools/ui-find.py" "$out/ui.xml" "$1")
    echo "tap '$1' at $xy"
    adb shell input tap $xy
}

adb shell cmd uimode night no
open_files
shot 1-system-light

adb shell cmd uimode night yes
open_files
shot 2-system-dark

adb shell cmd uimode night no
adb shell am force-stop "$pkg"
adb shell am start -W -n "$pkg/me.zhanghai.android.files.settings.SettingsActivity" >/dev/null
shot 3-settings
tap "Night mode"
sleep 2
tap "On"
shot 4-night-on

open_files
shot 5-after-night-on

tap "Download"
sleep 3
tap "archive-check.zip"
shot 6-archive

# Whatever the app logged while all that ran: its process, by uid.
uid=$(adb shell pm list packages -U "$pkg" | sed -n 's/.*uid:\([0-9]*\).*/\1/p' | head -n 1)
adb logcat -d --uid="$uid" >"$out/app-log.txt" 2>/dev/null || adb logcat -d >"$out/all-log.txt"
echo "app log lines: $(wc -l <"$out/app-log.txt" 2>/dev/null || echo '?')"
