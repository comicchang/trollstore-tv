# TrollStore TV

[![CI](https://github.com/comicchang/trollstore-tv/actions/workflows/ci.yml/badge.svg)](https://github.com/comicchang/trollstore-tv/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-tvOS%2017.0%20(21J354)-blue)
![License](https://img.shields.io/badge/license-MIT%20%2F%20BSD--4--Clause-green)

**English** | [简体中文](README.zh-CN.md)

A buildable, cold-reboot-verified **TrollStore** port for **Apple TV 4K (`AppleTV14,1`, tvOS 17.0 / `21J354`)**, based on [`straight-tamago/TrollStore-tvOS`](https://github.com/straight-tamago/TrollStore-tvOS) (`f1ebe52`) and [`opa334/TrollStore`](https://github.com/opa334/TrollStore).

TrollStore TV uses the CoreTrust code-signature bypass (`TeamIdentifier=T8ALTGMVXN`) to install permanently signed tvOS IPAs that **survive cold reboots and launch directly in the unjailbroken state** — without relying on jailbreak trustcaches or external `ldid`.

> Looking for companion host-side utilities (`.deb`-to-`.ipa` conversion for open-source apps like Kodi, YouTube/generic BYOIPA packaging & tvOS icon inversion, batch CoreTrust signing, clean-room probe sources, and post-reboot verification)? See **[`trollstore-tv-tools`](https://github.com/comicchang/trollstore-tv-tools)** ([App Packaging Guide](https://github.com/comicchang/trollstore-tv-tools/blob/main/docs/APP-PACKAGING-GUIDE.md)).

---

## Which Repo Should I Choose?

| Repository | Mechanism | Target tvOS | Cold-Reboot Unjailbroken Survival | License |
| --- | --- | --- | --- | --- |
| **`trollstore-tv`** *(this repo)* | CoreTrust bypass (`T8ALTGMVXN`) + built-in ChOma | **tvOS 17.0 (`21J354`)** | **Yes** (apps launch directly after cold reboot) | MIT + BSD-4-Clause (`uicache.m`) |
| [`trollstore-lite-tv`](https://github.com/comicchang/trollstore-lite-tv) | Ad-hoc `ldid` + kernel trustcache (`jbctl`) | **Any jailbroken tvOS 17.x+** | Requires re-jailbreak after reboot (includes TV UI, `:8787` web store & local userscript host) | Pure MIT (clean-room) |
| [`trollstore-tv-tools`](https://github.com/comicchang/trollstore-tv-tools) | Host-side packaging, BYOIPA, icon inversion, batch signing & verification scripts | macOS / Linux → tvOS 17.0 | Companion toolkit for `trollstore-tv` | Pure MIT |

---

## Verification Status (Apple TV 4K / tvOS 17.0 `21J354`)

| Capability | Status | Notes |
| --- | --- | --- |
| Modern Xcode tvOS SDK build (`TrollStore.app` + `trollstorehelper`) | **Verified** | `arm64`, `LC_BUILD_VERSION platform=tvOS`, `0` `dynamic_lookup` symbols |
| On-device CoreTrust signing without `ldid` (built-in ChOma) | **Verified** | Preserves nested `.appex` entitlements; avoids tvOS `ldid` crashes |
| Non-root app (`uid=501`) → `trollstorehelper` (`uid=0`) via `persona` | **Verified** | Runtime `dlsym` wrappers in [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h) |
| **Cold-reboot unjailbroken survival** | **Verified** | `TrollStore.app` & installed apps launch directly after cold reboot on sealed read-only SSV |
| Real-world multi-binary IPA installation | **Verified** | Verified on 5-Mach-O app (framework + dylibs), decrypted media client (2 Mach-Os), and Kodi 21.3 (**108 Mach-Os**: main + `.appex` + 106 dylibs) with `0` trustcache writes |
| Persistence Helper in `/Applications` system app | **Upstream limitation** | `/Applications` on SSV is never modified by default |
| Interactive on-TV URL/UI install UX | **In progress** | Native tvOS `TSTVSettingsController` and core install pipeline verified; Siri Remote UI polish ongoing |

---

## Key Changes from Upstream (`f1ebe52`)

- **Modern tvOS SDK & Zero `dynamic_lookup`**:
  - [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h): `dlsym` shims for `posix_spawn*` and `posix_spawnattr_set_persona_*_np`.
  - [`RootHelper/TSPrivateRefs.h`](RootHelper/TSPrivateRefs.h) / [`RootHelper/TSPrivateRefs.m`](RootHelper/TSPrivateRefs.m) + `ts_loadTVPrivateFrameworks()`: runtime `dlopen` + `NSClassFromString`/`dlsym` for tvOS dyld-cache private frameworks (`MobileContainerManager`, `FrontBoardServices`, `RunningBoardServices`, `BackBoardServices`, `SpringBoardServices`).
  - [`RootHelper/devmode.m`](RootHelper/devmode.m): `dlsym` shims for `libxpc` and `_CFXPC*`.
- **Built-in ChOma Signing (No `ldid` Required)**:
  - [`RootHelper/main.m`](RootHelper/main.m): uses ChOma `codesign_sign_adhoc` on tvOS, normalizing all regular Mach-O files before applying per-bundle entitlements (preserving nested `.appex` entitlements).
  - [`TrollStore/TSSceneDelegate.m`](TrollStore/TSSceneDelegate.m): skips automatic `ldid` download on tvOS.
- **Native tvOS UI**:
  - [`TrollStore/TSTVSettingsController.m`](TrollStore/TSTVSettingsController.m): replaces iOS-only `Preferences`/`PSListController` with native `UITableViewController`.
  - Guards unavailable iOS APIs (`UIPasteboard`, `UISearchController`, `UIDocumentPickerDelegate`, `CoreTelephony`, `MobileIcons`).
- **Host Signer & Reproducible Build Tooling**:
  - [`Exploits/fastPathSign/src/main.m`](Exploits/fastPathSign/src/main.m): supports thin arm64 Mach-O signing directly.
  - [`scripts/build-libcrypto-tvos.sh`](scripts/build-libcrypto-tvos.sh): cross-compiles static tvOS arm64 OpenSSL `libcrypto.a` (gitignored).
  - [`scripts/build-tvos.sh`](scripts/build-tvos.sh): single-command build, symbol/signature check, and packaging (`_build/TrollStore-tvOS.{tar,ipa}`).

Deep-dive technical notes: [`docs/TVOS-PORTING-NOTES.md`](docs/TVOS-PORTING-NOTES.md).

---

## Building from Source (macOS)

### Prerequisites

- macOS with full **Xcode** (AppleTVOS SDK installed)
- **[Theos](https://theos.dev/docs/installation)** (`$THEOS`, e.g. `~/theos`)
- **Homebrew**: `libarchive`, `openssl` (and optional `shellcheck` for tests)

### Build & Package

```sh
# 1. Cross-compile static tvOS arm64 libcrypto.a (one-time)
./scripts/build-libcrypto-tvos.sh

# 2. Build fastPathSign, trollstorehelper, TrollStore.app, and assemble archives
./scripts/build-tvos.sh
```

Preview commands without modifying files:

```sh
./scripts/build-tvos.sh --dry-run
```

Run local lint, regression, and hygiene checks:

```sh
./tests/run.sh
```

Outputs in `_build/`:
- `_build/TrollStore-tvOS.tar` — install archive for `trollstorehelper install-trollstore`
- `_build/TrollStore-tvOS.ipa` — standard `Payload/TrollStore.app` bundle

### Script Reference

| Script | Purpose & Options |
| --- | --- |
| [`scripts/build-libcrypto-tvos.sh`](scripts/build-libcrypto-tvos.sh) | Cross-compile static OpenSSL `libcrypto.a` for tvOS arm64 into gitignored `ChOma/external/tvos/`. Env: `OPENSSL_VERSION` (default `3.5.1`), `DEPLOY` (default `14.0`), `SDK_DIR`, `WORK`. Run `--help` for details. |
| [`scripts/build-tvos.sh`](scripts/build-tvos.sh) | Build `fastPathSign`, `trollstorehelper`, `TrollStore.app`, verify zero `dynamic_lookup` symbols & `T8ALTGMVXN` signature, and assemble `_build/TrollStore-tvOS.{tar,ipa}`. Flags: `--dry-run`, `--clean`. Env: `THEOS`, `DEVELOPER_DIR`. |
| [`tests/run.sh`](tests/run.sh) | Local & CI verification gate (`sh -n`, `shellcheck`, plist lint, `--dry-run` smoke, tvOS regression guards, privacy/artifact hygiene, Markdown links). |

---

## First-Time Installation (via Jailbroken tvOS 17.0 SSH)

On an Apple TV 4K running tvOS 17.0 with temporary root SSH access (e.g. [Relaxin](https://github.com/owngoal-dev/Relaxin)):

```sh
# 1. Copy trollstorehelper and TrollStore-tvOS.tar to the real rootfs /private/var/tmp
#    (Note: on RootHide jailbreaks, real /private/var/tmp is reachable via /rootfs/private/var/tmp)
scp _build/pkg/TrollStore.app/trollstorehelper _build/TrollStore-tvOS.tar mobile@192.0.2.10:/var/tmp/

# 2. On Apple TV (as root): copy into real rootfs and self-install TrollStore.app
sudo cp /var/tmp/trollstorehelper /var/tmp/TrollStore-tvOS.tar /rootfs/private/var/tmp/
sudo chmod 755 /rootfs/private/var/tmp/trollstorehelper
sudo /rootfs/private/var/tmp/trollstorehelper install-trollstore /private/var/tmp/TrollStore-tvOS.tar

# 3. Clean up temporary files
sudo rm -f /var/tmp/trollstorehelper /var/tmp/TrollStore-tvOS.tar \
           /rootfs/private/var/tmp/trollstorehelper /rootfs/private/var/tmp/TrollStore-tvOS.tar
```

Once installed, `TrollStore.app` and apps installed through it remain launchable after a full cold reboot in the unjailbroken state.

---

## Installing & Managing Apps (`trollstorehelper`)

Locate the installed `TrollStore.app` helper path once (on RootHide SSH, real `/private/var/containers/...` is mounted at `/rootfs/private/var/containers/...`):

```sh
TSH=$(ls /rootfs/private/var/containers/Bundle/Application/*/TrollStore.app/trollstorehelper)

# Install an unsigned / standard ad-hoc tvOS .ipa (copy to /rootfs/private/var/tmp first on RootHide)
sudo cp /var/tmp/MyApp.ipa /rootfs/private/var/tmp/MyApp.ipa
sudo "$TSH" install /private/var/tmp/MyApp.ipa
sudo rm -f /var/tmp/MyApp.ipa /rootfs/private/var/tmp/MyApp.ipa

# Uninstall an installed app by Bundle ID
sudo "$TSH" uninstall com.example.myapp

# Refresh LaunchServices / icon registrations for all TrollStore apps
sudo "$TSH" refresh-all

# Upgrade TrollStore.app itself from a newly built TrollStore-tvOS.tar
sudo "$TSH" install-trollstore /private/var/tmp/TrollStore-tvOS.tar
```

> **Preparing IPAs**: Need to convert an open-source `.deb` (e.g. Kodi) into an `.ipa`, repackage a local BYOIPA app with clean sandbox entitlements, or invert tvOS `Assets.car` icons? Use **[`trollstore-tv-tools`](https://github.com/comicchang/trollstore-tv-tools)** (`scripts/deb2ipa.sh`, `scripts/repack-ipa.sh`, `scripts/build-youtube-tvos.sh`).

---

## Entitlements & Data Container Notes

- **Standard apps**: keep standard sandboxed entitlements and let `trollstorehelper` inject `com.apple.private.security.container-required=<bundle-id>`. Adding `platform-application` + `no-sandbox` without explicit `com.apple.security.exception.iokit-user-client-class` entries tightens IOKit access on tvOS 17 (e.g. `Failed to create surface`).
- **`no-container` apps** (e.g. Kodi): `trollstorehelper` preserves `com.apple.private.security.no-container=true`, so the app uses `/private/var/mobile/Library/Caches/<App>` consistently across jailbroken and unjailbroken boots.
- **Input IPAs**: provide unsigned or standard ad-hoc IPAs; do not pre-apply `fastPathSign` before passing an IPA to `trollstorehelper`, as Apple's on-device Security framework rejects re-signing already CoreTrust-bypassed Mach-Os (`errSecCSInternalError / -67048`).

---

## Credits & License

This port stands on the work of the following upstream and open-source projects:

| Project | Author / Maintainer | License | Role |
| --- | --- | --- | --- |
| [`opa334/TrollStore`](https://github.com/opa334/TrollStore) | Lars Fröder (`opa334`) | MIT | Original TrollStore codebase & architecture |
| [`straight-tamago/TrollStore-tvOS`](https://github.com/straight-tamago/TrollStore-tvOS) | `straight-tamago` | MIT | Initial tvOS port (base commit `f1ebe52`) |
| [`opa334/ChOma`](https://github.com/opa334/ChOma) | Lars Fröder, `@alfiecg_dev`, `@LinusHenze`, Google TAG & contributors | MIT | Embedded Mach-O & CoreTrust signing library (`ChOma/`) |
| [`ProcursusTeam/uikittools-ng`](https://github.com/ProcursusTeam/uikittools-ng) | CoolStar, Procursus Team, `opa334` | BSD-4-Clause | `uicache` registration (`RootHelper/uicache.m`) |
| [`libarchive/libarchive`](https://github.com/libarchive/libarchive) | libarchive contributors | BSD-2-Clause | Archive extraction in `RootHelper/unarchive.m` |
| [`openssl/openssl`](https://github.com/openssl/openssl) | OpenSSL Project | Apache-2.0 | Static `libcrypto` for CMS/CoreTrust signing (built locally via `scripts/build-libcrypto-tvos.sh`, not committed) |
| [`theos/theos`](https://github.com/theos/theos) | Theos Team | GPL-3.0 | Build toolchain (host build-time only, not shipped) |
| [`owngoal-dev/Relaxin`](https://github.com/owngoal-dev/Relaxin) | owngoal-dev & contributors | MIT | External tvOS 17 RootHide jailbreak environment used for initial SSH bootstrap |

Related repositories:
- [`comicchang/trollstore-tv-tools`](https://github.com/comicchang/trollstore-tv-tools) (MIT) — companion host-side signing, BYOIPA packaging, icon inversion, clean-room probe, and reboot verification toolkit.
- [`comicchang/trollstore-lite-tv`](https://github.com/comicchang/trollstore-lite-tv) (MIT) — clean-room jailbreak trustcache installer for jailbroken tvOS 17.x (no CoreTrust exploit required; includes TV UI, `:8787` web store, and local offline userscript host).

Licensed under [`LICENSE`](LICENSE) (MIT + BSD-4-Clause for `RootHelper/uicache.m`). See [`NOTICE`](NOTICE), [`CHANGELOG.md`](CHANGELOG.md), [`CONTRIBUTING.md`](CONTRIBUTING.md), and [`SECURITY.md`](SECURITY.md).
