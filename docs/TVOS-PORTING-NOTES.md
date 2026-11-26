# tvOS 17.0 Porting & Verification Notes

This document records the engineering solutions required to build and run non-Lite `TrollStore.app` + `trollstorehelper` on Apple TV 4K (`AppleTV14,1`, tvOS 17.0 / `21J354`) with modern Xcode tvOS SDKs.

## 1. `posix_spawn` & `persona` Root Elevation (`Shared/TSSpawnCompat.h`)

- **Problem**: Modern AppleTVOS SDK headers mark `posix_spawn*` unavailable, and skipping `posix_spawnattr_set_persona_np(99, 1)` / `set_persona_uid_np(0)` / `set_persona_gid_np(0)` causes `trollstorehelper` to run as `mobile (uid=501)` because app containers reside on `nosuid` volumes.
- **Solution**: [`Shared/TSSpawnCompat.h`](../Shared/TSSpawnCompat.h) resolves all `posix_spawn*` and `posix_spawnattr_set_persona_*_np` symbols at runtime via `dlsym` from `/usr/lib/libSystem.B.dylib`.
- **Verification**: Verified on-device that a CoreTrust-signed non-root (`uid=501`) process with `com.apple.private.persona-mgmt` successfully spawns `trollstorehelper` as `uid=0` (`exit=0`, no `"has to be run as root"` error).

## 2. Eliminating `dynamic_lookup` Crashes (`RootHelper/TSPrivateRefs.{h,m}`)

- **Problem**: AppleTVOS SDK ships no `.tbd` stubs for `MobileContainerManager`, `FrontBoardServices`, `RunningBoardServices`, `BackBoardServices`, or `SpringBoardServices`. Linking with `-Wl,-undefined,dynamic_lookup` leaves non-lazy `_OBJC_CLASS_$_*` fixups that abort in `dyld` before `main()`.
- **Solution**:
  - Confirmed all six frameworks exist in the tvOS 17.0 dyld shared cache (`dlopen = ok`).
  - Added `ts_loadTVPrivateFrameworks()` (called at startup in both `TrollStore/TSAppDelegate.m` and `RootHelper/main.m`, plus guarded inside `TSClass()`).
  - Replaced direct private class references with `TSClass(@"...")` and `BKSTerminateApplicationForReasonAndReportWithDescription` with `TSBksTerminate()` (`dlsym`).
  - Removed `-Wl,-undefined,dynamic_lookup` from both `TrollStore/Makefile` and `RootHelper/Makefile`; `nm -mu` confirms **0** dynamic-lookup undefined symbols in both binaries.

## 3. Built-in ChOma Ad-Hoc Signing Instead of External `ldid`

- **Problem**: Jailbreak `ldid` binaries on RootHide tvOS depend on root-hiding dylib chains and crash (`ldid-*.ips`) when executed from a non-Lite app container.
- **Solution**:
  - Under `#if TARGET_OS_TV`, `RootHelper/main.m` uses ChOma's `codesign_sign_adhoc` directly.
  - Regular files only (`NSURLIsRegularFileKey` & `!NSURLIsSymbolicLinkKey`) are normalized with plain ad-hoc signing **before** applying per-bundle entitlements, preserving independent entitlements on both main executables and nested `.appex` plugins.
  - `TSSceneDelegate.m` and `installTrollStore` skip `ldid` download/migration on tvOS; `TSTVSettingsController.m` reports built-in ChOma signing as read-only.

## 4. Native tvOS Settings Controller & SDK Guards

- Replaced iOS-only `Preferences/PSListController` with native `UITableViewController` ([`TrollStore/TSTVSettingsController.m`](../TrollStore/TSTVSettingsController.m)).
- Guarded unavailable tvOS APIs: `UIPasteboard` (saves debug log to `Documents/trollstore-install.log`), `UISearchController`, `UIDocumentPickerDelegate`, `CoreTelephony`, `MobileIcons`, and `devmode.m` `libxpc`/`_CFXPC*` bridges (`dlsym`).

## 5. Static tvOS `libcrypto.a` & Thin Mach-O `fastPathSign`

- [`scripts/build-libcrypto-tvos.sh`](../scripts/build-libcrypto-tvos.sh) cross-compiles OpenSSL for `arm64-apple-tvos14.0` using `ios64-cross` overridden with AppleTVOS SDK, placing `libcrypto.a` and headers under gitignored `ChOma/external/tvos*`.
- [`Exploits/fastPathSign/src/main.m`](../Exploits/fastPathSign/src/main.m) copies thin Mach-O inputs directly when no FAT container is present.

## 6. Device End-to-End Verification Summary (tvOS 17.0 `21J354`)

- **Cold-reboot survival (unjailbroken state)**: Both `TrollStore.app` (`com.opa334.TrollStore`) and CoreTrust-signed user apps open directly after a full cold reboot without jailbreak trustcache entries.
- **Multi-binary installs via `trollstorehelper`**:
  - `RelaxinTest.app` (5 Mach-Os, standard sandbox + `container-required`) — installed & running, `0` crashes.
  - `YouTubeTVL.app` (2 Mach-Os, standard sandbox + `container-required`) — installed & running (`RSS ~119 MB`), `0` crashes.
  - `Kodi.app` v21.3 (**108 Mach-Os**: main + `kodi-topshelf.appex` + 106 dylibs, native `no-container` preserved) — installed & running with Python 3.11.7, FFmpeg H.264/HEVC, and migrated `/private/var/mobile/Library/Caches/Kodi` data (`88 MB`, `2,748` files), `0` crashes.
