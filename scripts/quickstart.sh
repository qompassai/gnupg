#!/bin/sh
# /qompassai/gnupg/scripts/quickstart.sh
# Qompass AI GnuPG Quick Start
# Copyright (C) 2025 Qompass AI, All rights reserved
#####################################################
set -eu
IFS='
'
detect_os() {
  case "$(uname -s)" in
  Linux*) echo "linux" ;;
  Darwin*) echo "macos" ;;
  CYGWIN* | MINGW* | MSYS*) echo "windows" ;;
  *) echo "unknown" ;;
  esac
}
install_gnupg() {
  OS=$(detect_os)
  case "$OS" in
  linux)
    if command -v apt >/dev/null 2>&1; then
      echo "→ Installing gnupg via apt..."
      sudo apt update && sudo apt install -y gnupg
    elif command -v pacman >/dev/null 2>&1; then
      echo "→ Installing gnupg via pacman..."
      sudo pacman -S --needed gnupg
    elif command -v dnf >/dev/null 2>&1; then
      echo "→ Installing gnupg via dnf..."
      sudo dnf install -y gnupg
    else
      echo "❌ Please install gnupg with your package manager."
      exit 1
    fi
    ;;
  macos)
    if command -v brew >/dev/null 2>&1; then
      echo "→ Installing gnupg via Homebrew..."
      brew install gnupg
    else
      echo "❌ Homebrew not found. Please install Homebrew and then run: brew install gnupg"
      exit 1
    fi
    ;;
  windows)
    echo "❌ Automated GnuPG installation unavailable on Windows."
    echo "➡ Please download & install from: https://www.gpg4win.org/"
    exit 1
    ;;
  *)
    echo "❌ Unsupported OS. Please install GnuPG manually."
    exit 1
    ;;
  esac
}
GPG_BIN="${GPG_BIN:-gpg}"
GPG_HOME="${GNUPGHOME:-$HOME/.gnupg}"
if ! command -v "$GPG_BIN" >/dev/null 2>&1; then
  echo "❌ gpg (GnuPG) is not installed. Attempting to install..."
  install_gnupg
  if ! command -v "$GPG_BIN" >/dev/null 2>&1; then
    echo "❌ gpg still not installed. Please check and install manually."
    exit 1
  fi
fi
echo "╭──────────────────────────────────────╮"
echo "│     Qompass AI GnuPG · Quick Start   │"
echo "╰──────────────────────────────────────╯"
echo "    (Re)generate personal GPG keys"
echo
printf "Real Name [%s]: " "$(whoami)"
read -r REALNAME
[ -n "$REALNAME" ] || REALNAME="$(whoami)"
DEFAULT_EMAIL="$(whoami)@$(hostname -d 2>/dev/null || echo 'localhost')"
printf "Email address [%s]: " "$DEFAULT_EMAIL"
read -r EMAIL
[ -n "$EMAIL" ] || EMAIL="$DEFAULT_EMAIL"
printf "Comment [optional]: "
read -r COMMENT
echo "Select key type:"
echo " 1) default (RSA and RSA)"
echo " 2) Ed25519 and Curve25519"
echo " 3) Custom"
while :; do
  printf 'Enter your choice [1]: '
  read -r choice
  [ -z "$choice" ] && choice=1
  case $choice in
  1)
    TYPEVAL="default"
    break
    ;;
  2)
    TYPEVAL="ed25519"
    break
    ;;
  3)
    TYPEVAL="custom"
    break
    ;;
  *) echo "Invalid selection. Please enter 1, 2, or 3." ;;
  esac
done
KEYLEN=4096
PRIMTYPE="rsa"
if [ "$TYPEVAL" = "custom" ]; then
  echo "Available key types: 1) rsa 2) ed25519 3) ecc"
  printf "Primary Key Type (rsa/ed25519/ecc) [rsa]: "
  read -r PRIMTYPE
  [ -n "$PRIMTYPE" ] || PRIMTYPE="rsa"
  if [ "$PRIMTYPE" = "rsa" ]; then
    printf "Key length [4096]: "
    read -r KEYLEN
    [ -n "$KEYLEN" ] || KEYLEN=4096
  fi
elif [ "$TYPEVAL" = "ed25519" ]; then
  PRIMTYPE="ed25519"
fi
printf "Set key expiration? (e.g. 1y, 2y, 0 for no expiry) [0]: "
read -r EXPIRE
[ -n "$EXPIRE" ] || EXPIRE=0
printf "Enter passphrase for the new key (will NOT echo, leave blank for no passphrase): "
stty -echo
read -r PASSPHRASE
stty echo
echo
BATCH_FILE=$(mktemp)
if [ "$PRIMTYPE" = "ed25519" ]; then
  {
    echo "Key-Type: ed25519"
    echo "Key-Curve: ed25519"
    echo "Subkey-Type: cv25519"
    echo "Subkey-Curve: cv25519"
    [ -n "$REALNAME" ] && echo "Name-Real: $REALNAME"
    [ -n "$COMMENT" ] && echo "Name-Comment: $COMMENT"
    [ -n "$EMAIL" ] && echo "Name-Email: $EMAIL"
    [ -n "$EXPIRE" ] && echo "Expire-Date: $EXPIRE"
    [ -n "$PASSPHRASE" ] && echo "Passphrase: $PASSPHRASE"
  } >"$BATCH_FILE"
else
  {
    echo "Key-Type: RSA"
    echo "Key-Length: $KEYLEN"
    echo "Subkey-Type: RSA"
    echo "Subkey-Length: $KEYLEN"
    [ -n "$REALNAME" ] && echo "Name-Real: $REALNAME"
    [ -n "$COMMENT" ] && echo "Name-Comment: $COMMENT"
    [ -n "$EMAIL" ] && echo "Name-Email: $EMAIL"
    [ -n "$EXPIRE" ] && echo "Expire-Date: $EXPIRE"
    [ -n "$PASSPHRASE" ] && echo "Passphrase: $PASSPHRASE"
  } >"$BATCH_FILE"
fi
echo "==> Generating GPG key..."
"$GPG_BIN" --batch --gen-key "$BATCH_FILE"
rm -f "$BATCH_FILE"
echo "✅ Done. Your GPG key has been created and stored in $GPG_HOME."
"$GPG_BIN" --list-keys --with-subkey-fingerprints --keyid-format LONG
echo "→ Next: You may want to export your public key: gpg --armor --export $EMAIL"
echo "→ Or edit your key: gpg --edit-key $EMAIL"
exit 0
