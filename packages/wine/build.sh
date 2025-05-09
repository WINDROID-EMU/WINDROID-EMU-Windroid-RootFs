#!/usr/bin/env bash

PKG_VER="10.1-9-esync-xinput-apc-patch"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine ($PKG_VER)"

BLACKLIST_ARCH=aarch64

GIT_URL="https://github.com/KreitinnSoftware/wine"
GIT_COMMIT=36b176851ffce636fc052fab773fb2be8990fe5c

HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"

# Diretório dos patches
PATCH_DIR="$INIT_DIR/packages/wine/patches"

CONFIGURE_ARGS="--enable-archs=i386,x86_64 \
                --host=$TOOLCHAIN_TRIPLE \
                --with-wine-tools=$INIT_DIR/workdir/$package/wine-tools \
                --prefix=$OVERRIDE_PREFIX \
                --without-oss \
                --disable-winemenubuilder \
                --disable-win16 \
                --disable-tests \
                --with-x \
                --x-libraries=$PREFIX/lib \
                --x-includes=$PREFIX/include \
                --with-pulse \
                --with-gstreamer \
                --with-opengl \
                --with-gnutls \
                --with-mingw=gcc \
                --with-xinput \
                --with-xinput2 \
                --enable-nls \
                --without-xshm \
                --without-xxf86vm \
                --without-osmesa \
                --without-usb \
                --without-sdl \
                --without-cups \
                --without-netapi \
                --without-pcap \
                --without-gphoto \
                --without-v4l2 \
                --without-pcsclite \
                --without-wayland \
                --without-opencl \
                --without-dbus \
                --without-sane \
                --without-udev \
                --without-capi \
                --enable-staging \
                --with-patch-options=-f -s"

prepare() {
  cd "$SRC_DIR/wine" || exit 0

  echo "==> Aplicando patches (só os que passarem no dry-run)"

  for p in "$PATCH_DIR"/*.patch; do
    echo "--> Testando $(basename "$p")"
    # Dry-run para verificar se aplica sem rejeição
    if patch --dry-run -p1 < "$p" >/dev/null 2>&1; then
      echo "✔ Aplicando $(basename "$p")"
      patch -p1 < "$p"
    else
      echo "⚠ Pulando $(basename "$p") — não aplicável ao código atual"
    fi
  done
}

build() {
  prepare

  cd "$SRC_DIR/wine"

  # Build host tools
  mkdir -p "$HOST_BUILD_FOLDER"
  cd "$HOST_BUILD_FOLDER"
  eval $HOST_BUILD_CONFIGURE_ARGS
  $HOST_BUILD_MAKE

  # Build Wine
  cd "$SRC_DIR/wine"
  ./configure $CONFIGURE_ARGS
  make -j"$(nproc)"
}

package() {
  cd "$SRC_DIR/wine"
  make DESTDIR="$pkgdir" install
}
