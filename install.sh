#!/usr/bin/env bash
# Install the monofoundry CLI from a GitHub Release (single-file binary).
#
# Usage:
#   ./install.sh            # install the latest release
#   ./install.sh v0.2.0     # install a specific release tag
#
# Env:
#   MONOFOUNDRY_INSTALL_DIR   target dir for the binary (default: ~/.local/bin)
#
# The binary is self-contained and the release assets are publicly
# downloadable over plain HTTPS.
#
# Windows users: download monofoundry-win32-x64.exe from the Releases page.
main() {
set -euo pipefail

REPO="monoai-labs/mono-foundry"
TAG="${1:-}"

# Detect OS/arch and map to the release asset naming scheme.
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Linux) os_name="linux" ;;
  Darwin) os_name="darwin" ;;
  *) echo "error: unsupported OS '$os'. On Windows, download monofoundry-win32-x64.exe from the Releases page." >&2; exit 1 ;;
esac
case "$arch" in
  x86_64 | amd64) arch_name="x64" ;;
  arm64 | aarch64) arch_name="arm64" ;;
  *) echo "error: unsupported architecture '$arch'." >&2; exit 1 ;;
esac
asset="monofoundry-${os_name}-${arch_name}"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required to download the release asset." >&2
  exit 1
fi

# GitHub serves release assets at stable redirect URLs — no auth needed:
#   latest:  https://github.com/<repo>/releases/latest/download/<asset>
#   pinned:  https://github.com/<repo>/releases/download/<tag>/<asset>
if [ -z "$TAG" ]; then
  url="https://github.com/$REPO/releases/latest/download/$asset"
  echo "Downloading latest monofoundry release ($asset)..."
else
  url="https://github.com/$REPO/releases/download/$TAG/$asset"
  echo "Downloading monofoundry release $TAG ($asset)..."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bin="$tmp/$asset"
if [ -z "$TAG" ]; then
  sums_url="https://github.com/$REPO/releases/latest/download/SHASUMS256.txt"
else
  sums_url="https://github.com/$REPO/releases/download/$TAG/SHASUMS256.txt"
fi
sums="$tmp/SHASUMS256.txt"

if ! curl -fsSL -o "$bin" "$url"; then
  echo "error: failed to download '$asset' from $url" >&2
  echo "Check that the release exists at https://github.com/$REPO/releases" >&2
  exit 1
fi

if ! curl -fsSL -o "$sums" "$sums_url"; then
  echo "error: failed to download release checksums from $sums_url" >&2
  exit 1
fi

# Require exactly one well-formed entry for this asset before changing the target.
expected="$(awk -v asset="$asset" '
  $0 ~ /^[[:xdigit:]]{64}[[:space:]][[:space:]][^[:space:]]+$/ && NF == 2 && $2 == asset {
    count++
    hash = $1
  }
  END {
    if (count != 1) exit 1
    print hash
  }
' "$sums")" || {
  echo "error: release checksums are missing or malformed for '$asset'" >&2
  exit 1
}

if command -v sha256sum >/dev/null 2>&1; then
  if ! printf '%s  %s\n' "$expected" "$bin" | sha256sum -c - >/dev/null; then
    echo "error: checksum mismatch for '$asset'" >&2
    exit 1
  fi
elif command -v shasum >/dev/null 2>&1; then
  if ! printf '%s  %s\n' "$expected" "$bin" | shasum -a 256 -c - >/dev/null; then
    echo "error: checksum mismatch for '$asset'" >&2
    exit 1
  fi
else
  echo "error: sha256sum or shasum -a 256 is required to verify '$asset'" >&2
  exit 1
fi

install_dir="${MONOFOUNDRY_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$install_dir"
chmod +x "$bin"
mv "$bin" "$install_dir/monofoundry"

# macOS: the binary is only ad-hoc signed, so clear the download quarantine
# flag to avoid a Gatekeeper block on first run.
if [ "$os_name" = "darwin" ]; then
  xattr -d com.apple.quarantine "$install_dir/monofoundry" 2>/dev/null || true
fi

echo "Installed to $install_dir/monofoundry"

# Offer to put the install dir on PATH if it isn't already.
case ":$PATH:" in
  *":$install_dir:"*) ;;
  *)
    export_line="export PATH=\"$install_dir:\$PATH\""
    # Pick the rc file for the user's shell, preferring an existing
    # login-shell profile where that's the convention (zsh keeps PATH in
    # .zprofile; macOS bash login shells read .bash_profile).
    case "$(basename "${SHELL:-}")" in
      zsh)
        if [ -f "$HOME/.zprofile" ]; then rc_file="$HOME/.zprofile"; else rc_file="$HOME/.zshrc"; fi
        ;;
      bash)
        if [ -f "$HOME/.bash_profile" ]; then rc_file="$HOME/.bash_profile"; else rc_file="$HOME/.bashrc"; fi
        ;;
      *) rc_file="$HOME/.profile" ;;
    esac
    # Make it available in the current shell too. This only persists if the
    # script is sourced (a child process can't mutate its parent's PATH);
    # it's harmless otherwise, and lets the printed one-liner work as-is.
    export PATH="$install_dir:$PATH"
    if [ -t 0 ]; then
      printf "note: %s is not on your PATH.\n" "$install_dir"
      printf "Without it you'll have to run the tool by its full path\n"
      printf "(%s/monofoundry) instead of just 'monofoundry'.\n" "$install_dir"
      printf "Add it to %s now? [y/N] " "$rc_file"
      read -r reply
      case "$reply" in
        [yY]*)
          if [ -f "$rc_file" ] && grep -qF "$export_line" "$rc_file"; then
            echo "Already present in $rc_file."
          else
            printf '\n# Added by monofoundry installer\n%s\n' "$export_line" >> "$rc_file"
            echo "Added to $rc_file (applies to new shells)."
          fi
          echo "To use it in this terminal now, run:"
          echo "      $export_line"
          ;;
        *)
          echo "Skipped. Run it by its full path ($install_dir/monofoundry), or add it later with:"
          echo "      $export_line"
          ;;
      esac
    else
      # Non-interactive (e.g. curl | bash): can't prompt, so just advise.
      echo "note: $install_dir is not on your PATH."
      echo "Until you add it, run the tool by its full path: $install_dir/monofoundry"
      echo "Add it with:"
      echo "      $export_line"
    fi
    ;;
esac
echo "Run 'monofoundry --help' to get started."
}

main "$@"
