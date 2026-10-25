set -e

macos=(
  anthy
  bamboo
  chewing
  chinese-addons
  cskk
  hallelujah
  hangul
  jyutping
  keyman
  kkc
  lua
  m17n
  mozc
  rime
  sayura
  skk
  table-extra
  table-other
  thai
  unikey
  zhuyin
)

windows=(
  anthy
  bamboo
  chewing
  chinese-addons
  cskk
  hallelujah
  hangul
  jyutping
  lua
  m17n
  rime
  sayura
  table-extra
  table-other
  thai
  unikey
  zhuyin
)

js=(
  anthy
  bamboo
  chewing
  chinese-addons
  cskk
  hallelujah
  hangul
  jyutping
  keyman
  kkc
  lua
  m17n
  mozc
  rime
  sayura
  skk
  thai
  unikey
  zhuyin
)

. scripts/platform.sh "$@"

ROOT=`pwd`
CACHE_DIR=$ROOT/cache/$PLATFORM
TARGET_DIR=$ROOT/build/$TARGET

if [[ $PLATFORM == "windows" ]]; then
  if [[ $2 == "arm64" ]]; then
    SYSROOT=${MSYS2_ROOT:-C:/msys64}/clangarm64
  else
    SYSROOT=${MSYS2_ROOT:-C:/msys64}/clang64
  fi
fi

has_plugin() {
  local plugin
  for plugin in "${plugins[@]}"; do
    [[ $plugin == "$1" ]] && return 0
  done
  return 1
}

extract_dep() {
  local plugin=$1
  local dep=$2
  local file=$dep$POSTFIX.tar.bz2
  tar xf $CACHE_DIR/$file -C $TARGET_DIR/$plugin/usr --exclude include --exclude lib
}

package() {
  local plugin=$1
  shift
  local input_methods=("$@")
  pushd $TARGET_DIR/$plugin/usr > /dev/null
  python $ROOT/scripts/generate-descriptor.py "${input_methods[@]}"

  if [[ $PLATFORM == "macos" || $PLATFORM == "windows" ]]; then
    # --no-xattrs fixes tar: Special header too large: %llu
    tar cjf ../../$plugin$POSTFIX.tar.bz2 --no-xattrs *
    cd ../data
    tar cjf ../../$plugin-any.tar.bz2 --no-xattrs *
  else
    rm -f ../../$plugin$POSTFIX.zip # zip adds content to existing zip file.
    zip -r ../../$plugin$POSTFIX.zip *
  fi
  popd > /dev/null
}

cache_plugin() {
  local file=$1
  [[ -f $ROOT/cache/$file ]] || curl --retry 3 -fsSLO --output-dir $ROOT/cache https://github.com/fcitx-contrib/fcitx5-plugins/releases/download/macos-latest/$file
}

for plugin in "${plugins[@]}"; do
  DESTDIR=$TARGET_DIR/$plugin cmake --install build/$TARGET/fcitx5-$plugin
  if [[ $PLATFORM == "js" && $plugin == "bamboo" ]]; then
    cp build/$TARGET/fcitx5-bamboo/bamboo/bamboo-core.wasm $TARGET_DIR/$plugin/usr/lib/fcitx5
  fi
  rm -rf $TARGET_DIR/$plugin/usr/include
  rm -rf $TARGET_DIR/$plugin/usr/lib/cmake
  rm -rf $TARGET_DIR/$plugin/usr/share/metainfo # only useful for linux
  if [[ $PLATFORM == "macos" ]]; then
    find $TARGET_DIR/$plugin/usr -name '*.so' -exec strip -x {} \;
  elif [[ $PLATFORM == "windows" ]]; then
    find $TARGET_DIR/$plugin/usr -name '*.dll' -exec strip -x {} \;
    python $ROOT/scripts/bundle-windows-dlls.py $TARGET_DIR/$plugin/usr $SYSROOT/bin $TARGET_DIR/usr/bin
  elif [[ $PLATFORM == "js" ]]; then
    rm -rf $TARGET_DIR/$plugin/usr/share/icons
  fi
done

if [[ $PLATFORM == "windows" ]]; then
  has_plugin anthy && extract_dep anthy anthy-cmake
  has_plugin chewing && extract_dep chewing libchewing
  has_plugin cskk && extract_dep cskk cskk
  has_plugin hangul && extract_dep hangul libhangul
  has_plugin m17n && extract_dep m17n m17n-db
fi

if [[ $PLATFORM != "windows" ]]; then
extract_dep anthy anthy-cmake
extract_dep chewing libchewing
if [[ $PLATFORM == "macos" ]]; then
  extract_dep chinese-addons opencc
else
  file=chinese-addons-any.tar.bz2
  cache_plugin $file
  tar xf $ROOT/cache/$file -C $TARGET_DIR/chinese-addons/usr lib/libime share/fcitx5/pinyin share/libime share/opencc
  file=jyutping-any.tar.bz2
  cache_plugin $file
  tar xf $ROOT/cache/$file -C $TARGET_DIR/jyutping/usr lib/libime share/libime
fi
extract_dep cskk cskk
extract_dep hangul libhangul
extract_dep m17n m17n-db
# JS doesn't embed mozc.data to libmozc.so.
if [[ $PLATFORM == "js" ]]; then
  extract_dep mozc libmozc
fi
fi

if [[ $PLATFORM == "windows" ]]; then
  OPENCC_DIR=$SYSROOT/share/opencc
else
  OPENCC_DIR=$TARGET_DIR/usr/share/opencc
fi
if [[ $PLATFORM == "windows" ]] && has_plugin chinese-addons; then
  cp -r $OPENCC_DIR $TARGET_DIR/chinese-addons/usr/share
fi

# rime
if has_plugin rime; then
rime_dir=$TARGET_DIR/rime/usr/share/rime-data
mkdir -p $rime_dir
pushd $ROOT/fcitx5-rime-data > /dev/null
cp rime-prelude/*.yaml $rime_dir
cp rime-essay/essay.txt $rime_dir
cp rime-luna-pinyin/*.yaml $rime_dir
cp rime-stroke/*.yaml $rime_dir
cp default.yaml $rime_dir
popd > /dev/null
cp -r $OPENCC_DIR $rime_dir
fi

# skk
if [[ $PLATFORM != "windows" ]]; then
skk_share_dir=$TARGET_DIR/skk/usr/share
mkdir -p $skk_share_dir/skk
cp -r $TARGET_DIR/usr/share/libskk $skk_share_dir
skk_dict=SKK-JISYO.L.gz
[[ -f $ROOT/cache/$skk_dict ]] || curl --retry 3 -fsSLO --output-dir $ROOT/cache https://skk-dev.github.io/dict/$skk_dict
gunzip -fc $ROOT/cache/$skk_dict > $skk_share_dir/skk/SKK-JISYO.L
fi

# zhuyin
if has_plugin zhuyin; then
  zhuyin_data=zhuyin-data.tar.bz2
  [[ -f $ROOT/cache/$zhuyin_data ]] || curl --retry 3 -fsSLO --output-dir $ROOT/cache https://github.com/fcitx-contrib/zhuyin-data/releases/download/latest/$zhuyin_data
  tar xf $ROOT/cache/$zhuyin_data -C $TARGET_DIR/zhuyin/usr
fi

if [[ $PLATFORM == "macos" || $PLATFORM == "windows" ]]; then
  # split arch-specific files with data
  for plugin in "${plugins[@]}"; do
    if [[ $plugin == "table-extra" || $plugin == "table-other" ]]; then
      continue
    fi
    pushd $TARGET_DIR/$plugin > /dev/null
    mkdir -p data
    rm -rf data/*
    for dir in "include" "share"; do
      if [[ -d usr/$dir ]]; then
        mv usr/$dir data/$dir
      fi
    done
    popd > /dev/null
  done
fi

# chinese-addons
if [[ $PLATFORM == "macos" || $PLATFORM == "windows" ]] && has_plugin chinese-addons; then
  DESTDIR=$TARGET_DIR/libime-install cmake --install $TARGET_DIR/libime
  if [[ $PLATFORM == "macos" ]]; then
    cp -r $TARGET_DIR/libime-install/usr/bin $TARGET_DIR/chinese-addons/usr
  fi
  cp -r $TARGET_DIR/libime-install/usr/share $TARGET_DIR/chinese-addons/data
  # Install zh_CN.lm and zh_CN.lm.predict which are not in share
  mkdir -p $TARGET_DIR/chinese-addons/data/lib
  cp -r $TARGET_DIR/libime-install/usr/lib/libime $TARGET_DIR/chinese-addons/data/lib
fi

# jyutping
if has_plugin jyutping; then
  rm -f $TARGET_DIR/jyutping/usr/lib/libIMEJyutping.a
  if [[ $PLATFORM == "macos" || $PLATFORM == "windows" ]]; then
    # Install zh_HK.lm and zh_HK.lm.predict which are not in share
    mkdir -p $TARGET_DIR/jyutping/data/lib
    mv $TARGET_DIR/jyutping/usr/lib/libime $TARGET_DIR/jyutping/data/lib
  fi
fi

# kkc
if [[ $PLATFORM != "windows" ]]; then
  libkkc_data=libkkc-data.tar.bz2
  [[ -f $ROOT/cache/$libkkc_data ]] || curl --retry 3 -fsSLO --output-dir $ROOT/cache https://github.com/fcitx-contrib/libkkc-data/releases/download/latest/$libkkc_data
  # Model files are under lib/
  if [[ $PLATFORM == "macos" ]]; then
    tar xf $ROOT/cache/$libkkc_data -C $TARGET_DIR/kkc/data
  else
    tar xf $ROOT/cache/$libkkc_data -C $TARGET_DIR/kkc/usr
  fi
fi

has_plugin anthy && package anthy anthy
has_plugin bamboo && package bamboo bamboo
has_plugin chewing && package chewing chewing
has_plugin chinese-addons && package chinese-addons pinyin
has_plugin cskk && package cskk cskk
has_plugin hangul && package hangul hangul
has_plugin jyutping && package jyutping jyutping
has_plugin keyman && package keyman
has_plugin kkc && package kkc kkc
has_plugin lua && package lua
has_plugin m17n && package m17n
has_plugin mozc && package mozc mozc
has_plugin rime && package rime rime
has_plugin skk && package skk skk
has_plugin zhuyin && package zhuyin zhuyin
has_plugin hallelujah && package hallelujah hallelujah
has_plugin sayura && package sayura sayura
has_plugin thai && package thai libthai
has_plugin unikey && package unikey unikey

if [[ $PLATFORM == "macos" || $PLATFORM == "windows" ]] && has_plugin table-extra; then
  # table-extra
  pushd $TARGET_DIR > /dev/null
  python $ROOT/scripts/package-table-extra.py
  popd > /dev/null
fi
