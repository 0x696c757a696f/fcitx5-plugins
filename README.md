# Fcitx5 plugins

Windows (x86_64 and arm64) plugin builds for
[fcitx5-windows-next](https://github.com/0x696c757a696f/fcitx5-windows-next),
forked from [fcitx-contrib/fcitx5-plugins](https://github.com/fcitx-contrib/fcitx5-plugins).

* Every build of `master` is published as a dated `windows-YYYYMMDD-N` release,
  and the `windows` release always points to the newest one.
* `Sync upstream` applies new upstream commits (outside `.github`) every day on the
  `upstream-sync` branch. Once the Windows build passes there, `master` is fast-forwarded and released.
* Dependabot updates the GitHub Actions. Its pull requests are merged when the build passes.

## Plugins

### Chinese
* [chinese-addons](https://github.com/fcitx/fcitx5-chinese-addons): LGPL-2.1-or-later
* [table-extra](https://github.com/fcitx/fcitx5-table-extra): GPL-3.0-or-later
* [chewing](https://github.com/fcitx/fcitx5-chewing): LGPL-2.1-or-later
* [jyutping](https://github.com/fcitx/libime-jyutping): LGPL-2.1-or-later
* [zhuyin](https://github.com/fcitx/fcitx5-zhuyin): GPL-2.0-or-later

### Japanese
* [mozc](https://github.com/fcitx/mozc): BSD-3-Clause
* [skk](https://github.com/fcitx/fcitx5-skk): GPL-3.0-or-later
* [anthy](https://github.com/fcitx/fcitx5-anthy): GPL-2.0-or-later
* [kkc](https://github.com/fcitx/fcitx5-kkc): GPL-3.0-or-later
* [cskk](https://github.com/fcitx/fcitx5-cskk): GPL-3.0-or-later

### Korean
* [hangul](https://github.com/fcitx/fcitx5-hangul): GPL-2.0-or-later

### English
* [hallelujah](https://github.com/fcitx-contrib/fcitx5-hallelujah): GPL-3.0-only

### Sinhala
* [sayura](https://github.com/fcitx/fcitx5-sayura): GPL-2.0-or-later

### Thai
* [thai](https://github.com/fcitx/fcitx5-libthai): GPL-2.0-or-later

### Vietnamese
* [bamboo](https://github.com/fcitx/fcitx5-bamboo): LGPL-2.1-or-later
* [unikey](https://github.com/fcitx/fcitx5-unikey): GPL-2.0-or-later

### Generic
* [rime](https://github.com/fcitx/fcitx5-rime): LGPL-2.1-or-later
  * [librime](https://github.com/rime/librime): BSD-3-Clause
  * [librime-lua](https://github.com/hchunhui/librime-lua): BSD-3-Clause
  * [librime-octagram](https://github.com/lotem/librime-octagram): GPL-3.0-only
  * [librime-predict](https://github.com/rime/librime-predict): BSD-3-Clause
  * [librime-qjs](https://github.com/HuangJian/librime-qjs): BSD-3-Clause
* [m17n](https://github.com/fcitx/fcitx5-m17n): LGPL-2.1-or-later
* [table-other](https://github.com/fcitx/fcitx5-table-other): GPL-3.0-only
* [keyman](https://github.com/fcitx/fcitx5-keyman): GPL-2.0-or-later

### Other
* [lua](https://github.com/fcitx/fcitx5-lua): LGPL-2.1-or-later
