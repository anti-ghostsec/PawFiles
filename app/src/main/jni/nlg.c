/*
 * libnlg ("no log"): Android's log functions, doing nothing.
 *
 * Native libraries that come built (libarchive-jni, libselinux-jni) link to
 * Android's log library, liblog. The build points them at this library
 * instead (see silenceNativeLogs in build.gradle), so what they would log
 * goes nowhere.
 */

#include <stdarg.h>
#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))

EXPORT int __android_log_print(int prio, const char *tag, const char *fmt, ...) {
    (void) prio; (void) tag; (void) fmt;
    return 0;
}

EXPORT int __android_log_vprint(int prio, const char *tag, const char *fmt, va_list ap) {
    (void) prio; (void) tag; (void) fmt; (void) ap;
    return 0;
}

EXPORT int __android_log_write(int prio, const char *tag, const char *text) {
    (void) prio; (void) tag; (void) text;
    return 0;
}

EXPORT int __android_log_buf_write(int buf, int prio, const char *tag, const char *text) {
    (void) buf; (void) prio; (void) tag; (void) text;
    return 0;
}

EXPORT int __android_log_buf_print(int buf, int prio, const char *tag, const char *fmt, ...) {
    (void) buf; (void) prio; (void) tag; (void) fmt;
    return 0;
}

EXPORT int __android_log_is_loggable(int prio, const char *tag, int default_prio) {
    (void) prio; (void) tag; (void) default_prio;
    return 0;
}

/* An assertion that failed: stop, as liblog would, but say nothing. */
EXPORT void __android_log_assert(const char *cond, const char *tag, const char *fmt, ...) {
    (void) cond; (void) tag; (void) fmt;
    abort();
}
