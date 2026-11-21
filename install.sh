#!/bin/sh
# Install b64, the Base64 command-line tool from https://base64hub.com/cli/
#
#   curl -fsSL https://base64hub.com/install.sh | sh
#
# Downloads the release archive for this system from GitHub, verifies it
# against the release's SHA256SUMS and installs the b64 binary to
# /usr/local/bin (directly or with sudo), else to ~/.local/bin.
#
# Environment:
#   B64_VERSION      install this version (for example 1.0.0) instead of the latest
#   B64_INSTALL_DIR  install into this directory
#   B64_BASE_URL     download from this base URL instead of GitHub releases
set -eu

releases="https://github.com/base64hub-com/base64hub-cli/releases"

say() { printf '%s\n' "$*"; }
die() {
	printf 'install.sh: %s\n' "$*" >&2
	exit 1
}

if [ -n "${B64_BASE_URL:-}" ]; then
	base="${B64_BASE_URL%/}"
elif [ -n "${B64_VERSION:-}" ]; then
	base="$releases/download/v${B64_VERSION#v}"
else
	base="$releases/latest/download"
fi

case "$(uname -s)" in
Darwin) os=darwin ;;
Linux) os=linux ;;
*) die "unsupported OS $(uname -s); see https://base64hub.com/cli/ for other ways to install" ;;
esac

case "$(uname -m)" in
x86_64 | amd64) arch=amd64 ;;
arm64 | aarch64 | armv8*) arch=arm64 ;;
*) die "unsupported CPU $(uname -m); see https://base64hub.com/cli/ for other ways to install" ;;
esac
# An x86_64 shell under Rosetta 2 on Apple silicon: install the native build.
if [ "$os" = darwin ] && [ "$arch" = amd64 ] &&
	[ "$(sysctl -n sysctl.proc_translated 2>/dev/null || true)" = 1 ]; then
	arch=arm64
fi

asset="b64_${os}_${arch}.tar.gz"

if command -v curl >/dev/null 2>&1; then
	download() { curl -fsSL --retry 2 -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
	download() { wget -q -O "$2" "$1"; }
else
	die "curl or wget is required"
fi

if command -v sha256sum >/dev/null 2>&1; then
	sha256() { sha256sum "$1" | cut -d ' ' -f 1; }
elif command -v shasum >/dev/null 2>&1; then
	sha256() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
else
	die "sha256sum or shasum is required to verify the download"
fi

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t b64)"
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

say "Downloading $base/$asset"
download "$base/$asset" "$tmp/$asset" || die "download failed: $base/$asset"
download "$base/SHA256SUMS" "$tmp/SHA256SUMS" || die "download failed: $base/SHA256SUMS"

expected="$(awk -v f="$asset" '$2 == f || $2 == "*" f { print $1; exit }' "$tmp/SHA256SUMS")"
[ -n "$expected" ] || die "$asset is not listed in SHA256SUMS"
actual="$(sha256 "$tmp/$asset")"
if [ "$actual" != "$expected" ]; then
	die "checksum mismatch for $asset: expected $expected, got $actual"
fi
say "Checksum verified"

mkdir "$tmp/x"
tar -xzf "$tmp/$asset" -C "$tmp/x"
[ -f "$tmp/x/b64" ] || die "b64 binary not found in $asset"
chmod 0755 "$tmp/x/b64"
version="$("$tmp/x/b64" --version 2>/dev/null)" || die "the downloaded b64 does not run on this system"

# put <dir> [sudo]: copy the binary into dir, creating it if needed.
put() {
	$2 mkdir -p "$1" && $2 cp "$tmp/x/b64" "$1/b64.tmp" && $2 chmod 0755 "$1/b64.tmp" &&
		$2 mv -f "$1/b64.tmp" "$1/b64"
}

if [ -n "${B64_INSTALL_DIR:-}" ]; then
	dir="$B64_INSTALL_DIR"
	put "$dir" "" || die "can't write to $dir"
else
	dir=/usr/local/bin
	if [ -d "$dir" ] && [ -w "$dir" ] || { [ ! -e "$dir" ] && [ -w /usr/local ]; }; then
		put "$dir" "" || die "can't write to $dir"
	elif [ "$(id -u)" != 0 ] && command -v sudo >/dev/null 2>&1 &&
		say "Installing to $dir with sudo" && put "$dir" sudo; then
		:
	else
		dir="$HOME/.local/bin"
		put "$dir" "" || die "can't write to $dir"
	fi
fi

say "Installed $version to $dir/b64"
case ":$PATH:" in
*":$dir:"*) ;;
*) say "Note: $dir is not on your PATH. Add it, for example: export PATH=\"$dir:\$PATH\"" ;;
esac
