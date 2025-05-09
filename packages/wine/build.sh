#!/usr/bin/env bash

# build-all.sh: Script de build completo para Wine com patches
# ----------------------------------------------------------------------------
# Configurações iniciais
set -euo pipefail
IFS=$'\n\t'

# Diretórios
INIT_DIR=$(pwd)
PREFIX="${PREFIX:-/usr/local}"
WORKDIR="$INIT_DIR/workdir/wine"
PATCH_DIR="$INIT_DIR/packages/wine/patches"

# Fonte Git
GIT_URL="https://github.com/KreitinnSoftware/wine"
GIT_COMMIT="36b176851ffce636fc052fab773fb2be8990fe5c"

# Prefix alternativo para instalação
OVERRIDE_PREFIX="$(realpath "$PREFIX/../wine")"

# Toolchain
TOOLCHAIN_TRIPLE="$(gcc -dumpmachine || echo "x86_64-pc-linux-gnu")"

# Função de clone e limpeza
prepare_source() {
  echo "==> Preparando fonte Wine"
  rm -rf "$WORKDIR"
  git clone "$GIT_URL" "$WORKDIR"
  cd "$WORKDIR"
  git checkout "$GIT_COMMIT"
}

# Função de aplicação de patches (ignora erros)
apply_patches() {
  echo "==> Aplicando patches"
  cd "$WORKDIR" || { echo "Aviso: diretório $WORKDIR não encontrado, pulando patches"; return; }

  # Desliga exit-on-error temporariamente
  set +e

  for p in "$PATCH_DIR"/*.patch; do
    echo "--> Aplicando $(basename "$p")"
    patch -p1 < "$p"
    if [ $? -ne 0 ]; then
      echo "⚠ Falha ao aplicar patch $(basename "$p") — continuando" >&2
    else
      echo "✔ Patch $(basename "$p") aplicado"
    fi
  done

  # Religa exit-on-error
  set -e
}

# Função de configuração
configure_build() {
  echo "==> Configurando build"
  cd "$WORKDIR"
  ./configure \
    --enable-archs=i386,x86_64 \
    --host="$TOOLCHAIN_TRIPLE" \
    --prefix="$OVERRIDE_PREFIX" \
    --with-wine-tools="$WORKDIR/wine-tools" \
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
}

# Função de compilação
build() {
  echo "==> Compilando"
  cd "$WORKDIR"
  make -j"$(nproc)" __tooldeps__ nls/all
}

# Função de instalação
install_pkg() {
  echo "==> Instalando"
  cd "$WORKDIR"
  make DESTDIR="$INIT_DIR/pkg" install
}

# Execução das etapas
prepare_source
apply_patches
configure_build
build
install_pkg

echo "\n*** Build concluído com sucesso! ***"
