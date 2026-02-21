#!/bin/bash
set -e

FREETZ_DIR="./freetz-ng"

# Ensure the symlink exists (e.g. after a fresh clone)
if [ ! -L "$FREETZ_DIR/.config" ]; then
    ln -sf ../.config "$FREETZ_DIR/.config"
    echo "Recreated symlink: freetz-ng/.config -> ../.config"
fi

exec make -C "$FREETZ_DIR" menuconfig "$@"
