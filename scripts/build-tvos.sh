#!/bin/sh
# build-tvos.sh — Reproducibly build and package non-Lite TrollStore.app + trollstorehelper for tvOS.
#
# Usage:
#   ./scripts/build-tvos.sh [--dry-run] [--clean]
#
# Outputs:
#   _build/pkg/TrollStore.app
#   _build/TrollStore-tvOS.tar
#   _build/TrollStore-tvOS.ipa
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
THEOS=${THEOS:-$HOME/theos}
DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
DRY_RUN=0
DO_CLEAN=0

usage() {
	cat <<'USAGE'
Usage: build-tvos.sh [--dry-run] [--clean]

  --dry-run   Print planned build and packaging commands without executing them
  --clean     Run make clean on fastPathSign, RootHelper, and TrollStore first

Environment:
  THEOS           Path to Theos installation (default: ~/theos)
  DEVELOPER_DIR   Xcode developer directory (default: /Applications/Xcode.app/Contents/Developer)
USAGE
}

while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1; shift ;;
		--clean) DO_CLEAN=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
done

run() {
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '+ %s\n' "$*"
	else
		"$@"
	fi
}

cd "$ROOT"

if [ "$DRY_RUN" -eq 0 ]; then
	[ -d "$THEOS" ] || { echo "THEOS not found at $THEOS" >&2; exit 2; }
	[ -d "$DEVELOPER_DIR" ] || { echo "Xcode DEVELOPER_DIR not found at $DEVELOPER_DIR" >&2; exit 2; }
	if [ ! -f "$ROOT/ChOma/external/tvos/libcrypto.a" ]; then
		echo "Missing ChOma/external/tvos/libcrypto.a; run ./scripts/build-libcrypto-tvos.sh first." >&2
		exit 2
	fi
fi

export THEOS DEVELOPER_DIR COPYFILE_DISABLE=1

if [ "$DO_CLEAN" -eq 1 ]; then
	run make -C "$ROOT/Exploits/fastPathSign" clean
	run make -C "$ROOT/RootHelper" clean
	run make -C "$ROOT/TrollStore" clean
fi

echo "== 1. Build host fastPathSign =="
run make -C "$ROOT/Exploits/fastPathSign"

echo "== 2. Build tvOS RootHelper (trollstorehelper) =="
run make -C "$ROOT/RootHelper" DEBUG=0

echo "== 3. Build tvOS TrollStore.app =="
run make -C "$ROOT/TrollStore" FINALPACKAGE=1

echo "== 4. Stage bundle & verify symbols/signatures =="
STAGE_APP="$ROOT/_build/pkg/TrollStore.app"
run rm -rf "$ROOT/_build"
run mkdir -p "$ROOT/_build/pkg"
run cp -R "$ROOT/TrollStore/.theos/obj/appletv/TrollStore.app" "$STAGE_APP"
run cp "$ROOT/RootHelper/.theos/obj/appletv/trollstorehelper" "$STAGE_APP/trollstorehelper"

if [ "$DRY_RUN" -eq 0 ]; then
	for bin in "$STAGE_APP/TrollStore" "$STAGE_APP/trollstorehelper"; do
		if nm -mu "$bin" | grep -qE 'dynamically looked up|flat_namespace'; then
			echo "ERROR: dynamic_lookup undefined symbols found in $bin" >&2
			nm -mu "$bin" | grep -E 'dynamically looked up|flat_namespace' >&2
			exit 1
		fi
		if ! codesign -dvvv "$bin" 2>&1 | grep -q 'TeamIdentifier=T8ALTGMVXN'; then
			echo "ERROR: missing CoreTrust TeamIdentifier=T8ALTGMVXN on $bin" >&2
			exit 1
		fi
		echo "Verified: $bin (0 dynamic_lookup, T8ALTGMVXN)"
	done
fi

echo "== 5. Package _build/TrollStore-tvOS.tar & .ipa =="
run tar -czf "$ROOT/_build/TrollStore-tvOS.tar" -C "$ROOT/_build/pkg" TrollStore.app
run mkdir -p "$ROOT/_build/ipa-stage/Payload"
run cp -R "$STAGE_APP" "$ROOT/_build/ipa-stage/Payload/TrollStore.app"
if [ "$DRY_RUN" -eq 1 ]; then
	printf '+ (cd %s/_build/ipa-stage && zip -rq %s/_build/TrollStore-tvOS.ipa Payload)\n' "$ROOT" "$ROOT"
else
	(cd "$ROOT/_build/ipa-stage" && zip -rq "$ROOT/_build/TrollStore-tvOS.ipa" Payload)
fi
run rm -rf "$ROOT/_build/ipa-stage"

if [ "$DRY_RUN" -eq 0 ]; then
	ls -lh "$ROOT/_build/TrollStore-tvOS.tar" "$ROOT/_build/TrollStore-tvOS.ipa"
fi
