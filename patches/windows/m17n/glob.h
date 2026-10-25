/* POSIX pieces m17n-lib uses that MinGW lacks. It is also force-included on Windows. */
#ifndef M17N_WINDOWS_GLOB_H
#define M17N_WINDOWS_GLOB_H

#include <direct.h>
#include <io.h>
#include <locale.h>
#include <malloc.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define mkdir(path, mode) _mkdir(path)

/* The Windows CRT has no LC_MESSAGES category. */
#ifndef LC_MESSAGES
#define LC_MESSAGES LC_CTYPE
#endif

__declspec(dllimport) int __stdcall CreateHardLinkA(const char *, const char *, void *);

static inline int link(const char *from, const char *to) {
    return CreateHardLinkA(to, from, NULL) ? 0 : -1;
}

/* Only what database.c needs: a wildcard in the last path component. */
#define GLOB_NOSORT 0
#define GLOB_NOMATCH 3

typedef struct {
    size_t gl_pathc;
    char **gl_pathv;
} glob_t;

static inline void globfree(glob_t *g) {
    for (size_t i = 0; i < g->gl_pathc; i++) {
        free(g->gl_pathv[i]);
    }
    free(g->gl_pathv);
    g->gl_pathc = 0;
    g->gl_pathv = NULL;
}

static inline int glob(const char *pattern, int flags, void *errfunc, glob_t *g) {
    (void)flags;
    (void)errfunc;
    g->gl_pathc = 0;
    g->gl_pathv = NULL;
    const char *slash = strrchr(pattern, '/');
    const char *backslash = strrchr(pattern, '\\');
    if (backslash && (!slash || backslash > slash)) {
        slash = backslash;
    }
    size_t dirlen = slash ? (size_t)(slash - pattern + 1) : 0;
    struct _finddata_t data;
    intptr_t h = _findfirst(pattern, &data);
    if (h == -1) {
        return GLOB_NOMATCH;
    }
    size_t capacity = 0;
    do {
        if (data.attrib & _A_SUBDIR) {
            continue;
        }
        if (g->gl_pathc == capacity) {
            capacity = capacity ? capacity * 2 : 16;
            char **grown = (char **)realloc(g->gl_pathv, capacity * sizeof(char *));
            if (!grown) {
                break;
            }
            g->gl_pathv = grown;
        }
        size_t namelen = strlen(data.name);
        char *path = (char *)malloc(dirlen + namelen + 1);
        if (!path) {
            break;
        }
        memcpy(path, pattern, dirlen);
        memcpy(path + dirlen, data.name, namelen + 1);
        g->gl_pathv[g->gl_pathc++] = path;
    } while (_findnext(h, &data) == 0);
    _findclose(h);
    return g->gl_pathc ? 0 : GLOB_NOMATCH;
}

#endif
