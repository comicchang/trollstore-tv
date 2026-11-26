# TrollStore TV (tvOS 17.0 Non-Lite Port)

[简体中文](README.zh-CN.md)

A maintained, buildable **non-Lite TrollStore** port for **Apple TV 4K (`AppleTV14,1`) running tvOS 17.0 (`21J354`)**, built on top of [`straight-tamago/TrollStore-tvOS`](https://github.com/straight-tamago/TrollStore-tvOS) (`f1ebe52`) and [`opa334/TrollStore`](https://github.com/opa334/TrollStore).

TrollStore uses the CoreTrust code-signature bypass (`TeamIdentifier=T8ALTGMVXN`) to install permanently signed apps that **survive cold reboots and launch directly in the unjailbroken state** without relying on jailbreak trustcaches.

## Verification Status (Apple TV 4K / tvOS 17.0 `21J354`)

| Capability | Status | Notes |
| --- | --- | --- |
| Modern Xcode tvOS SDK build (`TrollStore.app` + `trollstorehelper`) | **Verified** | `arm64`, `LC_BUILD_VERSION platform=tvOS`, zero `dynamic_lookup` symbols |
| On-device CoreTrust signing without `ldid` (built-in ChOma ad-hoc + CoreTrust) | **Verified** | Eliminates tvOS jailbreak `ldid` crashes; preserves nested `.appex` entitlements |
| Non-root app (`uid=501`) → `trollstorehelper` (`uid=0`) elevation via `persona` | **Verified** | `dlsym` shims in [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h) |
| **Cold-reboot unjailbroken survival** (`TrollStore.app` & installed apps launch directly) | **Verified (PASS)** | Tested after full cold reboot on sealed read-only SSV tvOS 17.0 |
| Multi-binary & real-world app installation via `trollstorehelper` | **Verified** | Verified on `RelaxinTest` (5 Mach-Os), `YouTubeTVL` (2 Mach-Os), and `Kodi` v21.3 (**108 Mach-Os**: main + `.appex` + 106 addon/framework dylibs) with 0 trustcache entries |
| Persistence Helper in `/Applications` system app | **Upstream limitation** | Not installed by default; `/Applications` remains unmodified |
| Interactive remote-control URL/UI install flow | **Partially verified** | Native tvOS `TSTVSettingsController` and core install chain verified; full UI polish ongoing |

## Key Changes from Upstream (`f1ebe52`)

- **Modern tvOS SDK & Zero `dynamic_lookup`**:
  - [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h): `dlsym` wrappers for `posix_spawn` and `posix_spawnattr_set_persona_*_np` (marked unavailable in tvOS SDK headers, exported by tvOS `libSystem.B.dylib`).
  - [`RootHelper/TSPrivateRefs.h`](RootHelper/TSPrivateRefs.h) / [`RootHelper/TSPrivateRefs.m`](RootHelper/TSPrivateRefs.m) + `ts_loadTVPrivateFrameworks()`: runtime `dlopen` + `NSClassFromString` / `dlsym` for `MobileContainerManager`, `FrontBoardServices`, `RunningBoardServices`, `BackBoardServices`, and `SpringBoardServices` — **zero undefined `dynamic_lookup` symbols**.
  - [`RootHelper/devmode.m`](RootHelper/devmode.m): `dlsym` shims for `libxpc` and `_CFXPC*` bridges on tvOS.
- **Built-in ChOma Signing (No `ldid` Required on tvOS)**:
  - [`RootHelper/main.m`](RootHelper/main.m): uses ChOma `codesign_sign_adhoc` on tvOS instead of external `ldid` (which depends on jailbreak root-hiding dylibs and crashes inside app containers), normalizing all Mach-Os before applying main & nested `.appex` entitlements.
  - [`TrollStore/TSSceneDelegate.m`](TrollStore/TSSceneDelegate.m): skips automatic `ldid` download on tvOS.
- **Native tvOS Settings UI**:
  - [`TrollStore/TSTVSettingsController.h`](TrollStore/TSTVSettingsController.h) / [`TrollStore/TSTVSettingsController.m`](TrollStore/TSTVSettingsController.m): replaces iOS-only `Preferences`/`PSListController` with a native `UITableViewController` settings screen (`Rebuild Icon Cache`, `Refresh App Registrations`, `Respring`, `Uninstall TrollStore`, and read-only signing backend status).
  - Guards iOS-only APIs (`UIPasteboard`, `UISearchController`, `UIDocumentPickerDelegate`, `CoreTelephony`, `MobileIcons`).
- **Host Signer & Reproducible tvOS OpenSSL Build**:
  - [`Exploits/fastPathSign/src/main.m`](Exploits/fastPathSign/src/main.m): supports thin arm64 Mach-O signing without requiring a FAT wrapper.
  - [`scripts/build-libcrypto-tvos.sh`](scripts/build-libcrypto-tvos.sh): builds static tvOS arm64 OpenSSL `libcrypto.a` into `ChOma/external/tvos/` (gitignored).
  - [`scripts/build-tvos.sh`](scripts/build-tvos.sh): single-command build, verification, and packaging script producing `_build/TrollStore-tvOS.tar` and `_build/TrollStore-tvOS.ipa`.

See [`docs/TVOS-PORTING-NOTES.md`](docs/TVOS-PORTING-NOTES.md) for the full technical write-up.

## Building from Source (macOS)

### Prerequisites

- macOS with full **Xcode** (AppleTVOS SDK installed)
- **[Theos](https://theos.dev/docs/installation)** (`$THEOS` configured, e.g. `~/theos`)
- **Homebrew** packages: `libarchive` (and `openssl` for host `fastPathSign`), plus optional `shellcheck` for CI checks

### Build & Package

```sh
# 1. Build static tvOS arm64 libcrypto.a (one-time; gitignored under ChOma/external/tvos/)
./scripts/build-libcrypto-tvos.sh

# 2. Build fastPathSign, RootHelper (trollstorehelper), TrollStore.app, and assemble .tar/.ipa
./scripts/build-tvos.sh
```

Preview build commands without modifying files:

```sh
./scripts/build-tvos.sh --dry-run
```

Outputs are written to `_build/`:
- `_build/TrollStore-tvOS.tar` (for `trollstorehelper install-trollstore`)
- `_build/TrollStore-tvOS.ipa` (standard `Payload/TrollStore.app` archive)

### Run Local Hygiene & Regression Checks

```sh
./tests/run.sh
```

## Notes on Entitlements & Data Containers

- **Standard apps** (e.g., decrypted apps or jailbreak launchers needing `IOSurfaceRootUserClient`): keep standard sandboxed entitlements and let `trollstorehelper` inject `com.apple.private.security.container-required=<bundle-id>`. Adding `platform-application` + `no-sandbox` without explicit `com.apple.security.exception.iokit-user-client-class` entries tightens IOKit access on tvOS 17 and can trigger `Failed to create surface`.
- **Unsandboxed (`no-container`) apps** (such as Kodi): `trollstorehelper` preserves `com.apple.private.security.no-container=true`, so the app reads/writes `/private/var/mobile/Library/Caches/<App>` consistently across both jailbroken and unjailbroken boots.
- **Pre-bypassed binaries**: Do not pre-apply `fastPathSign` to IPAs before feeding them to `trollstorehelper`; Apple's on-device Security framework rejects re-signing already CoreTrust-bypassed Mach-Os (`errSecCSInternalError / -67048`). Provide plain ad-hoc or unsigned IPAs and let `trollstorehelper` sign them directly.

## Credits & License

- Original TrollStore by [Lars Fröder (`opa334`)](https://github.com/opa334/TrollStore) and contributors
- Initial tvOS port by [`straight-tamago`](https://github.com/straight-tamago/TrollStore-tvOS)
- CoreTrust bypass research by Google TAG, `@alfiecg_dev`, `@LinusHenze`, and ChOma contributors
- `uicache` by CoolStar, Procursus Team, and `opa334`

Licensed under the terms in [`LICENSE`](LICENSE) (MIT + BSD-4-Clause for `RootHelper/uicache.m`). See [`NOTICE`](NOTICE), [`CONTRIBUTING.md`](CONTRIBUTING.md), and [`SECURITY.md`](SECURITY.md) for attribution, contribution standards, and security reporting.
