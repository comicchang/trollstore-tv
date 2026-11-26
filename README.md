# TrollStore TV

[![CI](https://github.com/comicchang/trollstore-tv/actions/workflows/ci.yml/badge.svg)](https://github.com/comicchang/trollstore-tv/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-tvOS%2017.0%20(21J354)-blue)
![License](https://img.shields.io/badge/license-MIT%20%2F%20BSD--4--Clause-green)

**English** | [简体中文](README.zh-CN.md)

A buildable, cold-reboot-verified **TrollStore** port for **Apple TV 4K (`AppleTV14,1`, tvOS 17.0 / `21J354`)**, based on [`straight-tamago/TrollStore-tvOS`](https://github.com/straight-tamago/TrollStore-tvOS) (`f1ebe52`) and [`opa334/TrollStore`](https://github.com/opa334/TrollStore).

TrollStore TV uses the CoreTrust code-signature bypass (`TeamIdentifier=T8ALTGMVXN`) to install permanently signed tvOS IPAs that **survive cold reboots and launch directly in the unjailbroken state** — without relying on jailbreak trustcaches or external `ldid`.

> Looking for companion host-side utilities (`.deb`-to-`.ipa` conversion for open-source apps like Kodi, generic BYOIPA repackaging & tvOS icon inversion, batch CoreTrust signing, clean-room probe sources, and post-reboot verification)? See the companion repository **[`trollstore-tv-tools`](https://github.com/comicchang/trollstore-tv-tools)** (and its [App Packaging Guide](https://github.com/comicchang/trollstore-tv-tools/blob/main/docs/APP-PACKAGING-GUIDE.md)).

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

---

## First-Time Installation (via Jailbroken tvOS 17.0 SSH)

On an Apple TV 4K running tvOS 17.0 with temporary root SSH access:

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

## Entitlements & Data Container Notes

- **Standard apps**: keep standard sandboxed entitlements and let `trollstorehelper` inject `com.apple.private.security.container-required=<bundle-id>`. Adding `platform-application` + `no-sandbox` without explicit `com.apple.security.exception.iokit-user-client-class` entries tightens IOKit access on tvOS 17 (e.g. `Failed to create surface`).
- **`no-container` apps** (e.g. Kodi): `trollstorehelper` preserves `com.apple.private.security.no-container=true`, so the app uses `/private/var/mobile/Library/Caches/<App>` consistently across jailbroken and unjailbroken boots.
- **Input IPAs**: provide unsigned or standard ad-hoc IPAs; do not pre-apply `fastPathSign` before passing an IPA to `trollstorehelper`, as Apple's on-device Security framework rejects re-signing already CoreTrust-bypassed Mach-Os (`errSecCSInternalError / -67048`).

---

## Credits & License

- [Lars Fröder (`opa334`)](https://github.com/opa334/TrollStore) — original TrollStore
- [`straight-tamago`](https://github.com/straight-tamago/TrollStore-tvOS) — initial tvOS port
- Google TAG, `@alfiecg_dev`, `@LinusHenze`, and ChOma contributors — CoreTrust research & tooling
- CoolStar, Procursus Team, and `opa334` — `uicache`

Licensed under [`LICENSE`](LICENSE) (MIT + BSD-4-Clause for `RootHelper/uicache.m`). See [`NOTICE`](NOTICE), [`CHANGELOG.md`](CHANGELOG.md), [`CONTRIBUTING.md`](CONTRIBUTING.md), and [`SECURITY.md`](SECURITY.md).
