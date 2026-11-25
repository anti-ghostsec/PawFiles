#!/bin/sh
# Looks through a built APK for anything left that can write to Android's
# log, in the app and every library it ships:
#
#   tools/log-audit.sh APK BUILD_TOOLS_DIR [--strict]
#
# Java and Kotlin code (every classes*.dex): calls to android.util.Log,
# Slog and EventLog, Throwable.printStackTrace, System.out and System.err
# (Android sends both to the log), and java.util.logging.
# Native code (every lib/*/*.so): imports of liblog (__android_log_*) and
# syslog.
#
# Prints what it finds, by class or library. With --strict, finding
# anything fails.

set -eu
apk=$1
tools=$2
strict=${3:-}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unzip -q -o "$apk" 'classes*.dex' 'lib/*' -d "$work" 2>/dev/null || unzip -q -o "$apk" 'classes*.dex' -d "$work"

found=0

echo "== Java and Kotlin code =="
for dex in "$work"/classes*.dex; do
    "$tools/dexdump" -d "$dex" 2>/dev/null
done | awk '
    /^  Class descriptor  :/ { cls = $4; next }
    /\|\[[0-9a-f]+\] / { where = $0; sub(/^.*\|\[[0-9a-f]+\] /, "", where); sub(/:\(.*$/, "", where); next }
    {
        what = ""
        if ($0 ~ /invoke-[a-z\/]+ .*Landroid\/util\/Log;\./) what = "android.util.Log"
        else if ($0 ~ /Landroid\/util\/(Slog|EventLog);\./) what = "android.util.Slog/EventLog"
        else if ($0 ~ /Ljava\/lang\/Throwable;\.printStackTrace:/) what = "printStackTrace"
        else if ($0 ~ /sget-object .*Ljava\/lang\/System;\.(out|err):/) what = "System.out/err"
        else if ($0 ~ /Ljava\/util\/logging\//) what = "java.util.logging"
        if (what != "") print what "\t" where
    }
' | sort | uniq -c | sort -k2,2 -k1,1nr >"$work/java.txt"
if [ -s "$work/java.txt" ]; then
    found=1
    cat "$work/java.txt"
else
    echo "none"
fi

echo
echo "== Native code =="
if ls "$work"/lib/*/*.so >/dev/null 2>&1; then
    for so in "$work"/lib/*/*.so; do
        name=${so#"$work"/}
        needs=$(readelf -d --wide "$so" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p' | tr '\n' ' ')
        hits=$(readelf --dyn-syms --wide "$so" | awk '$7 == "UND" { print $8 }' | sed 's/@.*//' |
            grep -E '^(__android_log_|android_set_abort_message|syslog|vsyslog|openlog)' | sort -u | tr '\n' ' ' || true)
        if [ -n "$hits" ]; then
            found=1
            echo "$name: logs through: $hits(needs: $needs)"
        else
            echo "$name: none (needs: $needs)"
        fi
    done
else
    echo "no native libraries"
fi

if [ "$found" = 1 ] && [ "$strict" = --strict ]; then
    echo "log-audit: something in the APK can still write to Android's log" >&2
    exit 1
fi
