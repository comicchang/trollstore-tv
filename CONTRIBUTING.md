# Contributing to TrollStore TV

Contributions, tvOS UI improvements, and bug reports are welcome.

## Local Validation

Before opening a pull request, run:

```sh
./tests/run.sh
```

This checks:
- POSIX `sh -n` and `shellcheck -S warning` on all shell scripts under `scripts/` and `tests/`
- XML/plist validity on `Info.plist` and `entitlements.plist` files
- `scripts/build-tvos.sh --dry-run` smoke behavior
- Makefile regression guard (ensuring `-undefined,dynamic_lookup` is not reintroduced in `TrollStore/Makefile` or `RootHelper/Makefile`)
- Privacy & hygiene scan (no private LAN IPs, personal home-directory paths, personal Team IDs, or `.jbroot-*` hashes)
- Binary guard (no compiled build outputs `_build/`, `fastPathSign`, or `ChOma/external/tvos/libcrypto.a` tracked in git)
- Relative Markdown link integrity

## Porting Guidelines

1. **Zero `dynamic_lookup` in tvOS targets**: Keep `TrollStore` and `trollstorehelper` free of flat/dynamic-lookup undefined symbols so missing private APIs cannot fail at `dyld` launch time.
2. **Preserve `persona` root elevation**: Always keep `posix_spawnattr_set_persona_*_np` active via `Shared/TSSpawnCompat.h` on tvOS.
3. **Keep third-party build artifacts out of git**: Build `libcrypto.a` via `scripts/build-libcrypto-tvos.sh` and `fastPathSign` via `scripts/build-tvos.sh`.
4. **Preserve upstream license headers**: Retain all MIT and BSD-4-Clause notices per `LICENSE` and `NOTICE`.
