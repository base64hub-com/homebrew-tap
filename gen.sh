#!/usr/bin/env bash
# Regenerate every package manifest for a b64 release from its SHA256SUMS.
#
#   ./gen.sh <version> <path to SHA256SUMS>
#
# Writes Formula/b64.rb (Homebrew), bucket/b64.json (Scoop),
# winget/manifests/b/base64hub/b64/<version>/ (winget) and aur/b64-bin/
# (PKGBUILD and .SRCINFO).
set -euo pipefail

die() {
	echo "gen.sh: $*" >&2
	exit 1
}

[ $# -eq 2 ] || die "usage: ./gen.sh <version> <path to SHA256SUMS>"
version="${1#v}"
sums="$2"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must look like 1.2.3, got '$1'"
[ -r "$sums" ] || die "can't read $sums"
sums="$(cd "$(dirname "$sums")" && pwd)/$(basename "$sums")"
cd "$(dirname "$0")"

repo="https://github.com/base64hub-com/base64hub-cli"
base="$repo/releases/download/v$version"
desc="Encode, decode and validate Base64 from the command line"
winget_schema="1.28.0"

# sha <asset>: the checksum of an asset from SHA256SUMS ("<hash>  <name>").
sha() {
	local h
	h="$(awk -v f="$1" '$2 == f || $2 == "*" f { print $1; exit }' "$sums")"
	[[ "$h" =~ ^[0-9a-f]{64}$ ]] || die "no SHA-256 for $1 in $sums"
	printf '%s' "$h"
}

darwin_amd64="$(sha b64_darwin_amd64.tar.gz)"
darwin_arm64="$(sha b64_darwin_arm64.tar.gz)"
linux_amd64="$(sha b64_linux_amd64.tar.gz)"
linux_arm64="$(sha b64_linux_arm64.tar.gz)"
windows_amd64="$(sha b64_windows_amd64.zip)"
windows_arm64="$(sha b64_windows_arm64.zip)"
upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

# Homebrew formula.
mkdir -p Formula
cat >Formula/b64.rb <<EOF
class B64 < Formula
  desc "$desc"
  homepage "https://base64hub.com/cli/"
  version "$version"
  license "MIT"

  on_macos do
    on_arm do
      url "$base/b64_darwin_arm64.tar.gz"
      sha256 "$darwin_arm64"
    end
    on_intel do
      url "$base/b64_darwin_amd64.tar.gz"
      sha256 "$darwin_amd64"
    end
  end

  on_linux do
    on_arm do
      url "$base/b64_linux_arm64.tar.gz"
      sha256 "$linux_arm64"
    end
    on_intel do
      url "$base/b64_linux_amd64.tar.gz"
      sha256 "$linux_amd64"
    end
  end

  def install
    bin.install "b64"
  end

  test do
    assert_equal "b64 #{version}", shell_output("#{bin}/b64 --version").strip
    assert_equal "SGVsbG8sIGh1YiE=", shell_output("#{bin}/b64 'Hello, hub!'").strip
  end
end
EOF

# Scoop manifest.
mkdir -p bucket
cat >bucket/b64.json <<EOF
{
    "version": "$version",
    "description": "$desc",
    "homepage": "https://base64hub.com/cli/",
    "license": "MIT",
    "architecture": {
        "64bit": {
            "url": "$base/b64_windows_amd64.zip",
            "hash": "$windows_amd64"
        },
        "arm64": {
            "url": "$base/b64_windows_arm64.zip",
            "hash": "$windows_arm64"
        }
    },
    "bin": "b64.exe",
    "checkver": {
        "github": "$repo"
    },
    "autoupdate": {
        "architecture": {
            "64bit": {
                "url": "$repo/releases/download/v\$version/b64_windows_amd64.zip"
            },
            "arm64": {
                "url": "$repo/releases/download/v\$version/b64_windows_arm64.zip"
            }
        },
        "hash": {
            "url": "\$baseurl/SHA256SUMS"
        }
    }
}
EOF

# winget manifests (one version directory, ready to copy into winget-pkgs).
rm -rf winget/manifests/b/base64hub/b64
wdir="winget/manifests/b/base64hub/b64/$version"
mkdir -p "$wdir"
cat >"$wdir/base64hub.b64.yaml" <<EOF
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.version.$winget_schema.schema.json

PackageIdentifier: base64hub.b64
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: $winget_schema
EOF
cat >"$wdir/base64hub.b64.locale.en-US.yaml" <<EOF
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.defaultLocale.$winget_schema.schema.json

PackageIdentifier: base64hub.b64
PackageVersion: $version
PackageLocale: en-US
Publisher: base64hub
PublisherUrl: https://base64hub.com
PublisherSupportUrl: $repo/issues
Author: base64hub
PackageName: b64
PackageUrl: https://base64hub.com/cli/
License: MIT
LicenseUrl: $repo/blob/main/LICENSE
Copyright: Copyright (c) 2026 base64hub
ShortDescription: $desc
Description: |-
  b64 encodes and decodes Base64 with the standard or URL-safe alphabet, validates input, wraps lines and builds data URIs.
  Decoding is lenient: whitespace, missing padding and a data: URI prefix are accepted. Input of any size is streamed in constant memory.
Moniker: b64
Tags:
- base64
- cli
- data-uri
- decode
- encode
- url-safe
ReleaseNotesUrl: $repo/releases/tag/v$version
Documentations:
- DocumentLabel: Documentation
  DocumentUrl: https://base64hub.com/docs/cli/
ManifestType: defaultLocale
ManifestVersion: $winget_schema
EOF
cat >"$wdir/base64hub.b64.installer.yaml" <<EOF
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.installer.$winget_schema.schema.json

PackageIdentifier: base64hub.b64
PackageVersion: $version
InstallerType: zip
NestedInstallerType: portable
NestedInstallerFiles:
- RelativeFilePath: b64.exe
  PortableCommandAlias: b64
Commands:
- b64
Installers:
- Architecture: x64
  InstallerUrl: $base/b64_windows_amd64.zip
  InstallerSha256: $(upper "$windows_amd64")
- Architecture: arm64
  InstallerUrl: $base/b64_windows_arm64.zip
  InstallerSha256: $(upper "$windows_arm64")
ManifestType: installer
ManifestVersion: $winget_schema
EOF

# AUR package b64-bin. The release assets carry no version in their names,
# so the local file names add it to keep makepkg's source cache correct.
mkdir -p aur/b64-bin
cat >aur/b64-bin/PKGBUILD <<EOF
# Maintainer: base64hub <hello at base64hub dot com>
pkgname=b64-bin
pkgver=$version
pkgrel=1
pkgdesc="$desc"
arch=('x86_64' 'aarch64')
url="https://base64hub.com/cli/"
license=('MIT')
provides=('b64')
conflicts=('b64')
options=('!strip' '!debug')
source_x86_64=("b64-\${pkgver}-x86_64.tar.gz::$repo/releases/download/v\${pkgver}/b64_linux_amd64.tar.gz")
source_aarch64=("b64-\${pkgver}-aarch64.tar.gz::$repo/releases/download/v\${pkgver}/b64_linux_arm64.tar.gz")
sha256sums_x86_64=('$linux_amd64')
sha256sums_aarch64=('$linux_arm64')

package() {
  install -Dm755 b64 "\$pkgdir/usr/bin/b64"
  install -Dm644 LICENSE "\$pkgdir/usr/share/licenses/\$pkgname/LICENSE"
  install -Dm644 README.md "\$pkgdir/usr/share/doc/\$pkgname/README.md"
}
EOF
# Same output as \`makepkg --printsrcinfo\` for the PKGBUILD above.
cat >aur/b64-bin/.SRCINFO <<EOF
pkgbase = b64-bin
	pkgdesc = $desc
	pkgver = $version
	pkgrel = 1
	url = https://base64hub.com/cli/
	arch = x86_64
	arch = aarch64
	license = MIT
	provides = b64
	conflicts = b64
	options = !strip
	options = !debug
	source_x86_64 = b64-$version-x86_64.tar.gz::$repo/releases/download/v$version/b64_linux_amd64.tar.gz
	sha256sums_x86_64 = $linux_amd64
	source_aarch64 = b64-$version-aarch64.tar.gz::$repo/releases/download/v$version/b64_linux_arm64.tar.gz
	sha256sums_aarch64 = $linux_arm64

pkgname = b64-bin
EOF

echo "Generated manifests for b64 $version:"
echo "  Formula/b64.rb"
echo "  bucket/b64.json"
echo "  $wdir/"
echo "  aur/b64-bin/PKGBUILD, aur/b64-bin/.SRCINFO"
