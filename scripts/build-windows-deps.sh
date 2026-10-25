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
cmake --build build/deps-$ARCH/libhangul -- -k 0
install_dep libhangul
package_dep libhangul
fi

# libchewing
if ! cached libchewing; then
# A static libchewing has to export the Rust library it wraps.
git -C deps/libchewing apply $(cygpath -m $ROOT)/patches/windows/libchewing.patch
configure libchewing -DBUILD_DOC=OFF -DWITH_SQLITE3=OFF
cmake --build build/deps-$ARCH/libchewing -- -k 0
install_dep libchewing
# libchewing.a only wraps the Rust static library, which is what plugins link.
cp $(find build/deps-$ARCH/libchewing -name libchewing_capi.a | head -1) build/deps-$ARCH/libchewing-install/usr/lib/libchewing.a
package_dep libchewing
fi

# m17n-lib, without loading external modules through dlopen
if ! cached m17n-cmake; then
git -C deps/m17n-cmake/m17n-lib apply $(cygpath -m $ROOT)/patches/windows/m17n-lib.patch
configure m17n-cmake \
  "-DCMAKE_C_FLAGS=-I$(cygpath -m $ROOT/patches/windows/m17n) -include glob.h -DM17NDIR=\\\"/usr/share/m17n\\\""
cmake --build build/deps-$ARCH/m17n-cmake -- -k 0
install_dep m17n-cmake
package_dep m17n-cmake
fi

# m17n-db is plain data, released by m17n-cmake.
[[ -f $CACHE_DIR/m17n-db-$ARCH.tar.bz2 ]] ||
  curl --retry 3 -fsSL -o $(cygpath -m $CACHE_DIR)/m17n-db-$ARCH.tar.bz2 \
    https://github.com/fcitx-contrib/m17n-cmake/releases/download/latest/m17n-db.tar.bz2

# anthy-unicode; its dictionary is built by autotools, so it comes from the macOS prebuilt data.
if ! cached anthy-cmake; then
configure anthy-cmake \
  "-DCMAKE_C_FLAGS=-I$(cygpath -m $ROOT/patches/windows/anthy) -include pwd.h"
cmake --build build/deps-$ARCH/anthy-cmake -- -k 0
install_dep anthy-cmake
curl --retry 3 -fsSL -o $(cygpath -m $ROOT)/build/deps-$ARCH/anthy-macos.tar.bz2 \
  https://github.com/fcitx-contrib/fcitx5-prebuilder/releases/download/macos/anthy-cmake-arm64.tar.bz2
tar xf build/deps-$ARCH/anthy-macos.tar.bz2 -C build/deps-$ARCH/anthy-cmake-install/usr share/anthy
package_dep anthy-cmake
fi

# libxkbcommon, only for its keysym functions
if ! cached libxkbcommon; then
git -C deps/libxkbcommon apply $(cygpath -m $ROOT)/patches/windows/libxkbcommon.patch
# meson wants an absolute prefix with a drive on Windows; DESTDIR drops the drive again.
PATH="$PATH:$(cygpath -u "$MSYS2_ROOT")/usr/bin" meson setup build/deps-$ARCH/libxkbcommon deps/libxkbcommon \
  --buildtype=release --default-library=static --prefix=C:/usr \
  -Denable-tools=false -Denable-x11=false -Denable-docs=false -Denable-wayland=false \
  -Denable-bash-completion=false -Denable-xkbregistry=false
ninja -C build/deps-$ARCH/libxkbcommon
rm -rf build/deps-$ARCH/libxkbcommon-install
DESTDIR=$(cygpath -m $ROOT/build/deps-$ARCH/libxkbcommon-install) meson install -C build/deps-$ARCH/libxkbcommon
package_dep libxkbcommon
fi

# cskk; the xkbcommon crate is Unix-only, so it builds from a copy limited to the keysym functions.
if ! cached cskk; then
git -C deps/cskk apply $(cygpath -m $ROOT)/patches/windows/cskk.patch
pushd deps/cskk > /dev/null
cargo fetch
xkbcommon_src=$(find "${CARGO_HOME:-$USERPROFILE/.cargo}/registry/src" -maxdepth 2 -type d -name 'xkbcommon-0.8.*' | head -1)
xkbcommon_copy=$ROOT/build/deps-$ARCH/xkbcommon-crate
rm -rf $xkbcommon_copy
cp -r "$xkbcommon_src" $xkbcommon_copy
sed -i 's/^    pub fn new_from_locale(/    #[cfg(unix)]\n    pub fn new_from_locale(/' $xkbcommon_copy/src/xkb/compose.rs
cargo build --release --features=capi \
  --config "patch.crates-io.xkbcommon.path='$(cygpath -m $xkbcommon_copy)'"
cbindgen --output libcskk.h cskk
cskk_usr=$ROOT/build/deps-$ARCH/cskk-install/usr
rm -rf $ROOT/build/deps-$ARCH/cskk-install
mkdir -p $cskk_usr/include $cskk_usr/lib/pkgconfig $cskk_usr/share/libcskk
cp libcskk.h $cskk_usr/include
cp target/release/libcskk.a $cskk_usr/lib
cp -r assets/rule assets/rules $cskk_usr/share/libcskk
popd > /dev/null
cat > $cskk_usr/lib/pkgconfig/cskk.pc <<PC
prefix=$(cygpath -m $USR)
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: libcskk
Description: SKK (Simple Kana Kanji) henkan library
Version: 4.0.0
Libs: -L\${libdir} -lcskk -lxkbcommon -lkernel32 -lntdll -luserenv -lws2_32 -ldbghelp -lunwind
Cflags: -I\${includedir}
PC
package_dep cskk
fi

# kyotocabinet
if ! cached kyotocabinet; then
# The configure script needs a POSIX shell, so compile the library objects directly.
kc_build=$(cygpath -m $ROOT/build/deps-$ARCH/kyotocabinet)
kc_usr=$(cygpath -m $ROOT/build/deps-$ARCH/kyotocabinet-install/usr)
rm -rf $kc_build $ROOT/build/deps-$ARCH/kyotocabinet-install
mkdir -p $kc_build $kc_usr/include $kc_usr/lib
for obj in kcutil kcthread kcfile kccompress kccompare kcmap kcregex \
  kcdb kcplantdb kcprotodb kcstashdb kccachedb \
  kchashdb kcdirdb kctextdb kcpolydb kcdbext kclangc; do
  clang++ -std=gnu++11 -O2 -fsigned-char -DNDEBUG -D_FILE_OFFSET_BITS=64 -D_REENTRANT \
    -Ideps/kyotocabinet -c deps/kyotocabinet/$obj.cc -o $kc_build/$obj.o
done
llvm-ar rcs $kc_usr/lib/libkyotocabinet.a $kc_build/*.o
cp deps/kyotocabinet/k*.h $kc_usr/include
package_dep kyotocabinet
fi

# libpinyin, which also provides libzhuyin
if ! cached libpinyin; then
git -C deps/libpinyin apply $(cygpath -m $ROOT)/patches/windows/libpinyin.patch
configure libpinyin -DBUILD_UTILS=OFF -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_PREFIX_PATH=$(cygpath -m $USR)
cmake --build build/deps-$ARCH/libpinyin -- -k 0
install_dep libpinyin
for pc in $ROOT/build/deps-$ARCH/libpinyin-install/usr/lib/pkgconfig/*.pc; do
  sed -i "s|^prefix=.*|prefix=$(cygpath -m $USR)|; s|^exec_prefix=.*|exec_prefix=\${prefix}|; s|^libdir=.*|libdir=\${prefix}/lib|; s|^includedir=.*|includedir=\${prefix}/include|" $pc
done
package_dep libpinyin
fi
