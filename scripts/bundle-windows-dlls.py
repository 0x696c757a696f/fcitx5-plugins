"""Copy the MSYS2 DLLs that a Windows plugin needs into its usr/bin.

usage: bundle-windows-dlls.py PLUGIN_USR SYSROOT_BIN FCITX_BIN

DLLs shipped by Fcitx5 itself (FCITX_BIN) and by Windows are not copied.
"""
import os
import shutil
import sys

import pefile

# Fcitx5 for Windows ships these runtime libraries next to its own DLLs.
CORE_RUNTIME = {
    "libc++.dll",
    "libunwind.dll",
    "libwinpthread-1.dll",
}

plugin_usr, sysroot_bin, fcitx_bin = sys.argv[1:4]


def lower_names(directory: str) -> dict[str, str]:
    if not os.path.isdir(directory):
        return {}
    return {name.lower(): name for name in os.listdir(directory)}


available = lower_names(sysroot_bin)
provided = set(lower_names(fcitx_bin)) | CORE_RUNTIME


def imports(path: str) -> list[str]:
    pe = pefile.PE(path, fast_load=True)
    pe.parse_data_directories(directories=[
        pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_IMPORT"],
        pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT"],
    ])
    names = []
    for attribute in ("DIRECTORY_ENTRY_IMPORT", "DIRECTORY_ENTRY_DELAY_IMPORT"):
        for entry in getattr(pe, attribute, []):
            names.append(entry.dll.decode().lower())
    pe.close()
    return names


pending = []
for dirpath, _, filenames in os.walk(plugin_usr):
    for filename in filenames:
        if filename.lower().endswith((".dll", ".exe")):
            pending.append(os.path.join(dirpath, filename))

bin_dir = os.path.join(plugin_usr, "bin")
copied: set[str] = set()
while pending:
    for name in imports(pending.pop()):
        if name in provided or name in copied or name not in available:
            continue
        copied.add(name)
        os.makedirs(bin_dir, exist_ok=True)
        destination = os.path.join(bin_dir, available[name])
        shutil.copy2(os.path.join(sysroot_bin, available[name]), destination)
        pending.append(destination)

for name in sorted(copied):
    print(f"{plugin_usr}: bundled {available[name]}")
