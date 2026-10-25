import os
import shutil
import subprocess
import sys
import tarfile

extra_plugins = {
    "array": [
        "array30",
        "array30-large",
    ],
    "boshiamy": [
        "boshiamy"
    ],
    "cangjie": [
        "cangjie5",
        "cangjie3",
        "cangjie-large",
        "scj6"
    ],
    "cantonese": [
        "cantonese",
        "cantonhk",
        "jyutping-table"
    ],
    "quick": [
        "quick5",
        "quick3",
        "quick-classic",
        "easy-large"
    ],
    "stroke": [
        "t9",
        "stroke5"
    ],
    "wu": [
        "wu"
    ],
    "wubi86": [
        "wubi-large"
    ],
    "wubi98": [
        "wubi98",
        "wubi98-single",
        "wubi98-large",
        "wubi98-pinyin"
    ],
    "zhengma": [
        "zhengma",
        "zhengma-large",
        "zhengma-pinyin"
    ]
}

other_plugins = {
    "table-amharic": ["amharic"],
    "table-arabic": ["arabic"],
    "table-cns11643": ["cns11643"],
    "table-compose": ["compose"],
    "table-emoji": ["emoji"],
    "table-ipa-x-sampa": ["ipa-x-sampa"],
    "table-latex": ["latex"],
    "table-malayalam-phonetic": ["malayalam-phonetic"],
    "table-rustrad": ["rustrad"],
    "table-tamil-remington": ["tamil-remington"],
    "table-thai": ["thai"],
    "table-translit-ua": ["translit-ua"],
    "table-translit": ["translit"],
    "table-viqr": ["viqr"],
    "table-yawerty": ["yawerty"],
}


build_dir = os.getcwd()
scripts_dir = os.path.dirname(os.path.abspath(__file__))

# split table-extra to plugins and keep directory structures so the package script can be reused
for repo, plugins in (("table-extra", extra_plugins), ("table-other", other_plugins)):
    for plugin, ims in plugins.items():
        for sub in ("inputmethod", "table"):
            os.makedirs(f"{plugin}/data/share/fcitx5/{sub}", exist_ok=True)
        os.makedirs(f"{plugin}/usr", exist_ok=True)

        for im in ims:
            shutil.move(f"{repo}/usr/share/fcitx5/inputmethod/{im}.conf", f"{plugin}/data/share/fcitx5/inputmethod")
            shutil.move(f"{repo}/usr/share/fcitx5/table/{im}.main.dict", f"{plugin}/data/share/fcitx5/table")

        subprocess.run(
            [sys.executable, os.path.join(scripts_dir, "generate-descriptor.py"), ims[0]],
            cwd=f"{plugin}/usr",
            check=True,
        )
        data_dir = os.path.join(plugin, "data")
        with tarfile.open(f"{plugin}-any.tar.bz2", "w:bz2") as tar:
            for name in sorted(os.listdir(data_dir)):
                tar.add(os.path.join(data_dir, name), arcname=name)
