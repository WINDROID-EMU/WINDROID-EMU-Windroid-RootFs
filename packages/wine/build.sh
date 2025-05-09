# — PKGBUILD —
pkgname=wine-esync-xinput-apc
pkgver=10.1-9
pkgrel=1
pkgdesc="Wine with esync, xinput and APC patches"
arch=('i686' 'x86_64')
url="https://github.com/KreitinnSoftware/wine"
license=('LGPL')
depends=('wine-mono' 'vulkan-icd-loader' 'libpulse' 'gstreamer' 'gnutls' 'libx11' 'libxrandr' 'libxrender' 'libxinerama' 'libxcursor' 'libxi')
makedepends=('git' 'flex' 'bison' 'mingw-w64-gcc' 'gcc-libs' 'libxcb' 'libx11' 'libxext')
provides=('wine')
conflicts=('wine')
  
# fonte: repo + patches locais
source=(
  "git+${GIT_URL}#commit=${GIT_COMMIT}"
  "0001-ntdll-APC-Performance.patch"
  "0001-wined3d-Use-UBO-for-vertex-shader-float-constants-if.patch"
)
sha256sums=('SKIP'  # git
            'e3b0c44298fc1c149afbf4c8996fb924…'  # ajustar com sha256 reais
            'd41d8cd98f00b204e9800998ecf8427e…')

prepare() {
  cd "$srcdir/wine"

  # aplica com fuzz=3 para tentar encaixar pequenas divergências
  patch -p1 --fuzz=3 < "$srcdir/0001-ntdll-APC-Performance.patch"
  patch -p1 --fuzz=3 < "$srcdir/0001-wined3d-Use-UBO-for-vertex-shader-float-constants-if.patch"
}

build() {
  cd "$srcdir/wine"
  ./configure \
    --enable-archs=i386,x86_64 \
    --host="$TOOLCHAIN_TRIPLE" \
    --prefix="${OVERRIDE_PREFIX}" \
    --with-wine-tools="$srcdir/wine-tools" \
    --without-oss \
    --disable-winemenubuilder \
    --disable-win16 \
    --disable-tests \
    --with-x \
    --x-libraries="$PREFIX/lib" \
    --x-includes="$PREFIX/include" \
    --with-pulse \
    --with-gstreamer \
    --with-opengl \
    --with-gnutls \
    --with-mingw=gcc \
    --with-xinput \
    --with-xinput2 \
    --enable-nls \
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
    --with-patch-options='-f -s'
  make -j"$(nproc)"
}

package() {
  cd "$srcdir/wine"
  make DESTDIR="$pkgdir" install
}
