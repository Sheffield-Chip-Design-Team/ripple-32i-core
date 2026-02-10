#!/usr/bin/env bash
set -euo pipefail

# Install Verilator from official repo, checkout "stable", install globally (/usr/local).
# Based on Verilator official install guide (Git Quick Install + Install System Globally).
# https://verilator.org/guide/latest/install.html

SRC_DIR="${SRC_DIR:-$HOME/.cache/verilator-src}"
JOBS="${JOBS:-$(nproc)}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "[FAIL] missing command: $1"; exit 2; }; }

echo "== 0) Prerequisites (apt) =="
sudo apt-get update

# Required packages per official guide (some optional/perf packages omitted)
sudo apt-get install -y \
  git help2man perl python3 make autoconf g++ flex bison ccache \
  libfl2 libfl-dev zlib1g zlib1g-dev

# Some distros mention zlibc; on Ubuntu it may not exist. Ignore if fails.
sudo apt-get install -y zlibc || true

need git
need autoconf
need make
need g++
need perl

echo
echo "== 1) Obtain/Update sources =="
if [[ ! -d "$SRC_DIR/.git" ]]; then
  rm -rf "$SRC_DIR"
  git clone https://github.com/verilator/verilator "$SRC_DIR"
fi

cd "$SRC_DIR"
git fetch --tags --prune
# Official guide: use stable for most recent stable release
git checkout stable
git pull

# Official guide: do not set VERILATOR_ROOT when installing system-wide
unset VERILATOR_ROOT || true

echo
echo "== 2) Build =="
autoconf
./configure
make -j "$JOBS"

echo
echo "== 3) Install globally (/usr/local) =="
sudo make install

# refresh shell command cache
hash -r || true

echo
echo "== 4) Verify =="
echo "which -a verilator:"
which -a verilator || true
echo
echo "verilator --version:"
verilator --version

# Ensure /usr/local/bin/verilator is the one being used
VERI_PATH="$(command -v verilator || true)"
if [[ "$VERI_PATH" != "/usr/local/bin/verilator" ]]; then
  echo
  echo "[WARN] verilator resolves to: $VERI_PATH"
  echo "       Expected: /usr/local/bin/verilator"
  echo "       Check your PATH order: /usr/local/bin should come before /usr/bin."
fi

echo
echo "[OK] Done."

