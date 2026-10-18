#!/usr/bin/env bash
# Isolated rtl_fm baseline build and verification.
# Does not install system binaries, shared libraries, firmware, or udev rules.
set -euo pipefail
cd "$(dirname "$0")/.."
cmake -S . -B build-fm-isolation \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DINSTALL_UDEV_RULES=OFF \
  -DDETACH_KERNEL_DRIVER=OFF
cmake --build build-fm-isolation --target rtl_fm -j "$(nproc)"
binary="$PWD/build-fm-isolation/src/rtl_fm"
libdir="$PWD/build-fm-isolation/src"
echo "=== Built rtl_fm ==="
sha256sum "$binary"
echo "=== Linked librtlsdr (must be within build-fm-isolation) ==="
LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ldd "$binary" | grep -E 'librtlsdr|libusb'
echo "=== Check actual ELF runtime path before live test ==="
echo "Command:"
printf 'LD_LIBRARY_PATH=%q %q\n' "$libdir" "$binary"
