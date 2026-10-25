/* POSIX pieces anthy-unicode uses that MinGW lacks. It is also force-included on Windows. */
#ifndef ANTHY_WINDOWS_PWD_H
#define ANTHY_WINDOWS_PWD_H

#include <direct.h>
#include <io.h>
#include <malloc.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#define mkdir(path, mode) _mkdir(path)
#define lstat stat
#define S_ISLNK(mode) 0
#define fchmod(fd, mode) 0

struct passwd {
    char *pw_dir;
};

static inline int getuid(void) { return 1; }

static inline struct passwd *getpwuid(int uid) {
    static struct passwd pw;
    (void)uid;
    pw.pw_dir = getenv("USERPROFILE");
    return pw.pw_dir ? &pw : NULL;
}

static inline int anthy_windows_dprintf(int fd, const char *format, ...) {
    char buf[4096];
    va_list ap;
    va_start(ap, format);
    int len = vsnprintf(buf, sizeof(buf), format, ap);
    va_end(ap);
    if (len < 0) {
        return len;
    }
    if (len >= (int)sizeof(buf)) {
        len = sizeof(buf) - 1;
    }
    return write(fd, buf, len);
}
#define dprintf anthy_windows_dprintf

#endif
