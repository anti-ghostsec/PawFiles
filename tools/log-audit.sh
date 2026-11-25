#!/bin/sh
# Looks through a built APK for anything left that can write to Android's
# log, in the app and every library it ships:
#
#   tools/log-audit.sh APK BUILD_TOOLS_DIR [MAPPING] [--strict]
#
# MAPPING is R8's mapping.txt, to show classes by their real names.
#
# Java and Kotlin code (every classes*.dex): calls to android.util.Log,
# Slog and EventLog, Throwable.printStackTrace, and System.out and
# System.err (Android sends both to the log). Uses of java.util.logging are
# listed apart: the app switches it off as it starts.
# Native code (every lib/*/*.so): links to liblog (Android's log). It also
# fails, always, if a library needs one that isn't in the APK.
#
# Prints what it finds, by class or library. With --strict, finding
# anything fails.

set -eu
apk=$1
tools=$2
mapping=
strict=
for a in "${3:-}" "${4:-}"; do
    case "$a" in --strict) strict=--strict ;; "") ;; *) mapping=$a ;; esac
done
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
        if (match($0, /Landroid\/util\/(Log|Slog|EventLog);\.[A-Za-z]+/)) {
            what = substr($0, RSTART + 1, RLENGTH - 1); gsub(/\//, ".", what); sub(/;/, "", what)
        }
        else if ($0 ~ /Ljava\/lang\/Throwable;\.printStackTrace:/) what = "printStackTrace"
        else if (match($0, /sget-object .*Ljava\/lang\/System;\.(out|err):/)) what = "System.out/err"
        else if (match($0, /Ljava\/util\/logging\/[A-Za-z]+;\.[A-Za-z<>]+/)) {
            what = substr($0, RSTART + 1, RLENGTH - 1); gsub(/\//, ".", what); sub(/;/, "", what)
        }
        if (what != "") print what "\t" where
    }
' >"$work/raw.txt"
if [ -n "$mapping" ] && [ -f "$mapping" ]; then
    # R8 mapping lines "real.Name -> short:" give each class its real name.
    awk -F'\t' '
        NR == FNR { if ($0 ~ /^[^ #].* -> .*:$/) { split($0, p, " -> "); sub(/:$/, "", p[2]); real[p[2]] = p[1] } next }
        { cls = $2; meth = ""; if (match(cls, /\.[^.]*$/)) { meth = substr(cls, RSTART); cls = substr(cls, 1, RSTART - 1) }
          if (cls in real) cls = real[cls]; print $1 "\t" cls meth }
    ' "$mapping" "$work/raw.txt" >"$work/named.txt"
    mv "$work/named.txt" "$work/raw.txt"
fi
grep -v '^java\.util\.logging' "$work/raw.txt" | sort | uniq -c | sort -k2,2 -k3,3 >"$work/java.txt" || true
grep '^java\.util\.logging' "$work/raw.txt" | sort | uniq -c | sort -k2,2 -k3,3 >"$work/jul.txt" || true
if [ -s "$work/java.txt" ]; then
    found=1
    cat "$work/java.txt"
else
    echo "none"
fi

echo
echo "== java.util.logging (switched off when the app starts) =="
if [ -s "$work/jul.txt" ]; then cat "$work/jul.txt"; else echo "none"; fi

echo
echo "== Native code =="
# What Android itself provides to apps; any other library one needs must be
# in the APK beside it, or it won't load.
system=" libc.so libm.so libdl.so liblog.so libandroid.so libz.so libjnigraphics.so libEGL.so libGLESv2.so libGLESv3.so libvulkan.so libOpenSLES.so libmediandk.so libnativewindow.so "
missing=0
if ls "$work"/lib/*/*.so >/dev/null 2>&1; then
    for so in "$work"/lib/*/*.so; do
        name=${so#"$work"/}
        dir=$(dirname "$so")
        needs=$(readelf -d --wide "$so" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p' | tr '\n' ' ')
        hits=$(readelf --dyn-syms --wide "$so" | awk '$7 == "UND" { print $8 }' | sed 's/@.*//' |
            grep -E '^(__android_log_|android_set_abort_message|syslog|vsyslog|openlog)' | sort -u | tr '\n' ' ' || true)
        line="$name (needs: $needs)"
        case " $needs " in
            *" liblog.so "*) found=1; line="$line: LOGS, through liblog.so: $hits" ;;
            *) if [ -n "$hits" ]; then line="$line: none (its log calls go to libnlg.so, which does nothing)"; else line="$line: none"; fi ;;
        esac
        for n in $needs; do
            case "$system" in *" $n "*) ;; *)
                if [ ! -f "$dir/$n" ]; then missing=1; line="$line; MISSING $n"; fi ;;
            esac
        done
        echo "$line"
    done
else
    echo "no native libraries"
fi

if [ "$missing" = 1 ]; then
    echo "log-audit: a native library needs one that isn't in the APK, so it won't load" >&2
    exit 1
fi
if [ "$found" = 1 ] && [ "$strict" = --strict ]; then
    echo "log-audit: something in the APK can still write to Android's log" >&2
    exit 1
fi
