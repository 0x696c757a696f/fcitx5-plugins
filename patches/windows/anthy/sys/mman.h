/* The part of mmap() anthy's filemap.c uses, on top of Win32 file mappings. */
#ifndef ANTHY_WINDOWS_SYS_MMAN_H
#define ANTHY_WINDOWS_SYS_MMAN_H

#include <io.h>
#include <stddef.h>
#include <sys/types.h>
/* Lean, so winsock.h stays out and doesn't clash with the gethostname shim. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define PROT_READ 1
#define PROT_WRITE 2
#define MAP_SHARED 1
#define MAP_FAILED ((void *)-1)

static inline void *mmap(void *addr, size_t len, int prot, int flags, int fd, off_t off) {
    (void)addr;
    (void)flags;
    HANDLE file = (HANDLE)_get_osfhandle(fd);
    if (file == INVALID_HANDLE_VALUE) {
        return MAP_FAILED;
    }
    int writable = prot & PROT_WRITE;
    HANDLE mapping = CreateFileMappingA(file, NULL, writable ? PAGE_READWRITE : PAGE_READONLY, 0, 0, NULL);
    if (!mapping) {
        return MAP_FAILED;
    }
    void *ptr = MapViewOfFile(mapping, writable ? FILE_MAP_WRITE : FILE_MAP_READ, 0, (DWORD)off, len);
    /* The view keeps the mapping alive. */
    CloseHandle(mapping);
    return ptr ? ptr : MAP_FAILED;
}

static inline int munmap(void *addr, size_t len) {
    (void)len;
    return UnmapViewOfFile(addr) ? 0 : -1;
}

#endif
