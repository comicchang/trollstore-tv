# Roadmap

## Done

- [x] Modern Xcode tvOS SDK build (`TrollStore.app` + `trollstorehelper`, `arm64`, zero `dynamic_lookup`)
- [x] Runtime `dlsym` persona spawn shims (`Shared/TSSpawnCompat.h`) and 6 tvOS private framework loaders (`RootHelper/TSPrivateRefs.{h,m}`)
- [x] Built-in ChOma on-device signing without external `ldid` (per-bundle entitlements + nested `.appex` preservation + symlink guard)
- [x] Cold-reboot unjailbroken survival verified on Apple TV 4K (`AppleTV14,1`, tvOS 17.0 `21J354`) across `TrollStore.app`, 5-Mach-O app, decrypted media client, and Kodi 21.3 (108 Mach-Os)
- [x] Native tvOS `TSTVSettingsController`, reproducible build script (`scripts/build-tvos.sh`), and automated offline CI gate (`tests/run.sh`)

## In Progress

- [ ] Siri Remote interactive URL / LAN IPA install UX inside `TrollStore.app`
- [ ] On-TV app list refresh, uninstall confirmation dialogs, and error toast polish

## Planned

- [ ] Prebuilt tagged GitHub Releases (`TrollStore-tvOS.tar` / `TrollStore-tvOS.ipa` built cleanly in CI / reproducible release pipeline)
- [ ] Optional upstream PR synchronization with `straight-tamago/TrollStore-tvOS`
