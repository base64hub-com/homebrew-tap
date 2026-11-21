# base64hub tap

Package manifests for [`b64`](https://github.com/base64hub-com/base64hub-cli), a command-line tool to encode,
decode and validate Base64. This repository is the Homebrew tap and the Scoop bucket, and holds the
winget and AUR manifests and the install script.

Website: [base64hub.com/cli](https://base64hub.com/cli/) · Documentation:
[base64hub.com/docs/cli](https://base64hub.com/docs/cli/)

## Install

Homebrew (macOS, Linux):

```sh
brew install base64hub-com/tap/b64
```

Scoop (Windows):

```powershell
scoop bucket add base64hub https://github.com/base64hub-com/homebrew-tap
scoop install b64
```

winget (Windows):

```powershell
winget install base64hub.b64
```

AUR (Arch Linux):

```sh
yay -S b64-bin
```

Install script (macOS, Linux):

```sh
curl -fsSL https://base64hub.com/install.sh | sh
```

The script downloads the archive for your system from the latest GitHub release, checks it against
the release's `SHA256SUMS` and installs `b64` to `/usr/local/bin` (directly or with `sudo`), or to
`~/.local/bin` when neither works. Environment variables: `B64_VERSION=1.0.0` pins a version,
`B64_INSTALL_DIR` picks the directory, `B64_BASE_URL` downloads from another location.

Other ways to install (`.deb`, `go install`, npm, PyPI) are listed in the
[b64 README](https://github.com/base64hub-com/base64hub-cli#install).

## Contents

| Path | What |
|---|---|
| `Formula/b64.rb` | Homebrew formula |
| `bucket/b64.json` | Scoop manifest |
| `winget/manifests/b/base64hub/b64/<version>/` | winget manifests, submitted to microsoft/winget-pkgs |
| `aur/b64-bin/` | `PKGBUILD` and `.SRCINFO` of the AUR package `b64-bin` |
| `install.sh` | Install script served at base64hub.com/install.sh |
| `gen.sh` | Regenerates every manifest from a release's `SHA256SUMS` |

All manifests are generated: run `./gen.sh <version> <path to SHA256SUMS>` instead of editing them.
The release steps are in [PUBLISH.md](PUBLISH.md).

## License

MIT, see [LICENSE](LICENSE).
