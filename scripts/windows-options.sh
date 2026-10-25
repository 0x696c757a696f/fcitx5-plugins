#!/bin/bash
# Print the CMake options that build exactly the plugins listed for Windows in install.sh.
set -e

options=(
  ANTHY:anthy
  BAMBOO:bamboo
  CHEWING:chewing
  CHINESE_ADDONS:chinese-addons
  CSKK:cskk
  HALLELUJAH:hallelujah
  HANGUL:hangul
  JYUTPING:jyutping
  KEYMAN:keyman
  KKC:kkc
  M17N:m17n
  MOZC:mozc
  RIME:rime
  SAYURA:sayura
  SKK:skk
  TABLE_EXTRA:table-extra
  THAI:thai
  UNIKEY:unikey
  ZHUYIN:zhuyin
)

windows=$(sed -n '/^windows=(/,/^)/p' "$(dirname "$0")/install.sh")
for option in "${options[@]}"; do
  name=${option%%:*}
  plugin=${option#*:}
  if grep -qx "  $plugin" <<< "$windows"; then
    printf -- '-D%s=ON ' "$name"
  else
    printf -- '-D%s=OFF ' "$name"
  fi
done
echo
