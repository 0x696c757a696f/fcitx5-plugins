# Build the libraries that MSYS2 doesn't package as static archives, the way
# fcitx5-prebuilder does for macOS: each dependency becomes
# cache/windows/<dep>-<arch>.tar.bz2 and is unpacked into build/windows-<arch>/usr.
set -e

ARCH=$1
ROOT=$PWD
CACHE_DIR=$ROOT/cache/windows
USR=$ROOT/build/windows-$ARCH/usr
mkdir -p $CACHE_DIR $USR

configure() {
  local dep=$1
  shift
  cmake -S deps/$dep -B build/deps-$ARCH/$dep -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    "$@"
}

install_dep() {
  local dep=$1
  local dest=$ROOT/build/deps-$ARCH/$dep-install
  rm -rf $dest
  DESTDIR=$(cygpath -m $dest) cmake --install build/deps-$ARCH/$dep
}

package_dep() {
  local dep=$1
  pushd $ROOT/build/deps-$ARCH/$dep-install/usr > /dev/null
  # Plugins only need headers, static libraries and data.
  rm -rf bin share/doc share/man share/locale
  tar cjf $CACHE_DIR/$dep-$ARCH.tar.bz2 *
  popd > /dev/null
  tar xf $CACHE_DIR/$dep-$ARCH.tar.bz2 -C $USR
}

# Reuse an archive restored from the CI cache, whose key covers the sources and this script.
cached() {
  local file=$CACHE_DIR/$1-$ARCH.tar.bz2
  if [[ -f $file ]]; then
    tar xf $file -C $USR
    return 0
  fi
  return 1
}

# libhangul
if ! cached libhangul; then
configure libhangul -DENABLE_EXTERNAL_KEYBOARDS=OFF -DENABLE_UNIT_TEST=OFF -DENABLE_TOOLS=OFF
cmake --build build/deps-$ARCH/libhangul
install_dep libhangul
package_dep libhangul
fi

# libchewing
if ! cached libchewing; then
configure libchewing -DBUILD_DOC=OFF -DWITH_SQLITE3=OFF
cmake --build build/deps-$ARCH/libchewing
install_dep libchewing
# libchewing.a only wraps the Rust static library, which is what plugins link.
cp $(find build/deps-$ARCH/libchewing -name libchewing_capi.a | head -1) build/deps-$ARCH/libchewing-install/usr/lib/libchewing.a
package_dep libchewing
fi
