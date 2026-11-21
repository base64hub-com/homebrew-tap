# Release checklist

Steps to publish a release of `b64` everywhere. `X.Y.Z` is the new version (the first one is `1.0.0`).
The CLI repo is `base64hub-com/base64hub-cli` (local `b64-cli`), this repo is `base64hub-com/homebrew-tap` (local
`b64-bin`).

## One-time setup

- [ ] GitHub organization `base64hub-com` with the public repos `base64hub-com/base64hub-cli` and
      `base64hub-com/homebrew-tap`. Release tags live on `base64hub-com/base64hub-cli`.
- [ ] Every repo has the local identity: `git config user.name base64hub` and
      `git config user.email g@base64hub.com`.
- [ ] AUR account for base64hub (email g@base64hub.com) with an SSH key that is used for nothing else.
- [ ] A GitHub account under the base64hub organization that can fork `microsoft/winget-pkgs` and open PRs.

## Before every push

In each repo, run the identity grep from the site repo's `docs/SOFTWARE.md` ("Identity"); it must find
nothing. The commit identities must show only base64hub:

```sh
git log --format='%an <%ae>%n%cn <%ce>' | sort -u
```

## 1. Build and release the CLI (`b64-cli`)

- [ ] Update the version mentions if any changed (README examples), commit.
- [ ] `go vet ./... && go test ./...`
- [ ] Tag: `git tag -a vX.Y.Z -m "b64 X.Y.Z"`, then `git push origin main vX.Y.Z`.
- [ ] Build from the tag: `./build.sh X.Y.Z`. `dist/` now holds the six archives, the two `.deb`
      files and `SHA256SUMS`. Builds are reproducible for a given commit.
- [ ] Create the GitHub release with all nine files:
      `gh release create vX.Y.Z dist/* --repo base64hub-com/base64hub-cli --title "b64 X.Y.Z" --notes "..."`
- [ ] Check the links resolve:
      `curl -fsSLO https://github.com/base64hub-com/base64hub-cli/releases/latest/download/SHA256SUMS`
      and compare with `dist/SHA256SUMS`.
- [ ] `go install github.com/base64hub-com/base64hub-cli/cmd/b64@vX.Y.Z` in a clean environment prints `b64 X.Y.Z` with
      `b64 --version` (the Go proxy picks up the tag by itself).

## 2. Update the tap (`b64-bin`)

- [ ] `./gen.sh X.Y.Z ../b64-cli/dist/SHA256SUMS`
- [ ] Review `git diff`: new version, URLs and hashes in all four places. `gen.sh` replaces the
      previous winget version directory.
- [ ] Commit (`b64 X.Y.Z`) and push. Homebrew and Scoop users get the update from here.
- [ ] Smoke test on a Mac: `brew update && brew install base64hub-com/tap/b64 && brew test b64`
      (`brew upgrade b64` for later versions). Optionally `brew audit --strict base64hub-com/tap/b64`.
- [ ] Smoke test on Windows: `scoop bucket add base64hub https://github.com/base64hub-com/homebrew-tap`,
      `scoop install b64`, `b64 --version` (`scoop update b64` for later versions).

## 3. winget

- [ ] Fork `microsoft/winget-pkgs` and create a branch `base64hub.b64-X.Y.Z`.
- [ ] Copy `winget/manifests/b/base64hub/b64/X.Y.Z/` (three files) to the same path in the fork.
- [ ] On Windows: `winget validate --manifest manifests\b\base64hub\b64\X.Y.Z`, then test with
      `winget settings --enable LocalManifestFiles` and
      `winget install --manifest manifests\b\base64hub\b64\X.Y.Z`, then `b64 --version`.
- [ ] Commit `New package: base64hub.b64 version X.Y.Z` (later: `New version: ...`), open the PR,
      fill the PR checklist. The validation bot runs the installer; answer reviewer comments.
- [ ] After the merge, `winget install base64hub.b64` works within a few hours.

## 4. AUR

- [ ] First time: `git clone ssh://aur@aur.archlinux.org/b64-bin.git aur-b64-bin` (an empty clone
      creates the package on the first push). Later: `git pull` in that clone.
- [ ] Copy `aur/b64-bin/PKGBUILD` and `aur/b64-bin/.SRCINFO` into the clone. Set the local identity
      there too (`base64hub`, `g@base64hub.com`).
- [ ] On Arch (or an `archlinux` container): `makepkg --printsrcinfo | diff - .SRCINFO` shows nothing,
      and `makepkg -si` builds and installs; `b64 --version`.
- [ ] Commit (`Update to X.Y.Z`) and `git push`. The AUR only accepts the `master` branch.

## 5. Install script and site

- [ ] Copy `install.sh` to the site repo as `static/install.sh` when it changed. Build and deploy the
      site.
- [ ] `curl -fsSL https://base64hub.com/install.sh | sh` on Linux and macOS installs the new version.
- [ ] Fill the download and store links in the site's `data/apps.yaml` that are now live (GitHub
      release, Homebrew, Scoop, winget, AUR).
- [ ] Debian/Ubuntu `.deb` from the release: `sudo apt install ./b64_linux_amd64.deb`, `b64 --version`.
