# Changelog

All notable changes to **TrollStore TV** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Native tvOS settings screen (`TSTVSettingsController`) replacing iOS-only `Preferences`/`PSListController`.
- Runtime `posix_spawn` and `posix_spawnattr_set_persona_*_np` `dlsym` wrappers (`Shared/TSSpawnCompat.h`) enabling non-root `TrollStore.app` (`uid=501`) → `trollstorehelper` (`uid=0`) elevation on tvOS 17.
- Runtime private-framework loader (`ts_loadTVPrivateFrameworks`) and `TSPrivateRefs` eliminating all `-undefined,dynamic_lookup` symbols.
- Reproducible tvOS static OpenSSL builder (`scripts/build-libcrypto-tvos.sh`) and single-command build/package script (`scripts/build-tvos.sh`).
- Local & GitHub Actions verification suite (`tests/run.sh`, `.github/workflows/ci.yml`), bilingual README (EN / zh-CN), porting guide (`docs/TVOS-PORTING-NOTES.md`), `NOTICE`, `CONTRIBUTING.md`, and `SECURITY.md`.

### Changed
- Switched tvOS on-device ad-hoc signing in `RootHelper/main.m` from external `ldid` to built-in ChOma `codesign_sign_adhoc`, normalizing all regular Mach-O files before applying main and nested `.appex` entitlements.
- Skipped automatic `ldid` download/migration on tvOS (`TSSceneDelegate.m`, `RootHelper/main.m`).
- Updated host `Exploits/fastPathSign` to handle thin arm64 Mach-O binaries directly.
- Updated bundle display name in `TrollStore/Resources/Info.plist` to `TrollStore`.

### Verified
- Cold-reboot unjailbroken survival on Apple TV 4K (`AppleTV14,1`, tvOS 17.0 `21J354`) with sealed read-only SSV.
- Multi-binary on-device installs via `trollstorehelper` including embedded frameworks, `.appex` plugins, and 100+ dylibs with zero jailbreak trustcache writes.
