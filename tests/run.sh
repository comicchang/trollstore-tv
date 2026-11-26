#!/bin/sh
# Local & CI hygiene, lint, regression, privacy, and link verification suite.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

PASS=0
FAIL=0

ok() {
	PASS=$((PASS + 1))
	printf 'PASS: %s\n' "$1"
}

ng() {
	FAIL=$((FAIL + 1))
	printf 'FAIL: %s\n' "$1" >&2
}

echo "== 1. Shell syntax (sh -n) =="
for s in scripts/*.sh tests/*.sh; do
	if sh -n "$s"; then
		ok "sh -n $s"
	else
		ng "sh -n $s"
	fi
done

echo "== 2. shellcheck -S warning =="
if command -v shellcheck >/dev/null 2>&1; then
	if shellcheck -S warning scripts/*.sh tests/*.sh; then
		ok "shellcheck -S warning"
	else
		ng "shellcheck -S warning"
	fi
else
	echo "SKIP: shellcheck not installed"
fi

echo "== 3. plist & entitlements lint =="
for p in \
	TrollStore/Resources/Info.plist \
	TrollStore/entitlements.plist \
	RootHelper/entitlements.plist; do
	if command -v plutil >/dev/null 2>&1; then
		if plutil -lint "$p" >/dev/null 2>&1; then
			ok "plutil -lint $p"
		else
			ng "plutil -lint $p"
		fi
	elif command -v python3 >/dev/null 2>&1; then
		if python3 -c "import plistlib, sys; plistlib.load(open(sys.argv[1], 'rb'))" "$p" >/dev/null 2>&1; then
			ok "plistlib lint $p"
		else
			ng "plistlib lint $p"
		fi
	else
		echo "SKIP: neither plutil nor python3 available for $p"
	fi
done

echo "== 4. CLI --help and --dry-run smoke =="
if ./scripts/build-tvos.sh --help >/dev/null &&
   ./scripts/build-tvos.sh --dry-run >/dev/null; then
	ok "scripts/build-tvos.sh --help & --dry-run"
else
	ng "scripts/build-tvos.sh --help / --dry-run"
fi

echo "== 5. tvOS regression guards =="
if grep -nE 'undefined,dynamic_lookup' TrollStore/Makefile RootHelper/Makefile >/dev/null 2>&1; then
	grep -nE 'undefined,dynamic_lookup' TrollStore/Makefile RootHelper/Makefile >&2
	ng "no -undefined,dynamic_lookup in tvOS Makefiles"
else
	ok "no -undefined,dynamic_lookup in tvOS Makefiles"
fi

if grep -q 'ts_loadTVPrivateFrameworks();' RootHelper/main.m &&
   grep -q 'ts_loadTVPrivateFrameworks();' TrollStore/TSAppDelegate.m &&
   grep -q 'posix_spawnattr_set_persona_np' Shared/TSSpawnCompat.h; then
	ok "tvOS runtime private framework & persona hooks present"
else
	ng "tvOS runtime private framework / persona hooks missing"
fi

if grep -q 'Install / Update ldid' TrollStore/TSTVSettingsController.m; then
	ng "deprecated ldid action still present in TSTVSettingsController.m"
else
	ok "no deprecated ldid install action in TSTVSettingsController.m"
fi

echo "== 6. Privacy & tracked-artifact hygiene =="
LEAK_RE='192\.168\.|10\.8\.|10\.222\.|/Users/[A-Za-z0-9._-]+|ooxx|WV4ADEUMV4|\.jbroot-[0-9A-Fa-f]{16}|tsltv@local'
if git grep -InE "$LEAK_RE" -- ':!tests/run.sh' >/dev/null 2>&1; then
	git grep -InE "$LEAK_RE" -- ':!tests/run.sh' >&2
	ng "privacy/local-path leak scan"
else
	ok "privacy/local-path leak scan (0 hits)"
fi

if git ls-files | grep -qE '^(_build/|ChOma/external/tvos|Exploits/fastPathSign/fastPathSign|tools/)'; then
	git ls-files | grep -E '^(_build/|ChOma/external/tvos|Exploits/fastPathSign/fastPathSign|tools/)' >&2
	ng "no tracked build outputs, tvos libcrypto.a, or duplicate tools/"
else
	ok "no tracked build outputs, tvos libcrypto.a, or duplicate tools/"
fi

echo "== 7. Markdown relative link integrity =="
if python3 - <<'PY'
import pathlib, re, sys
root = pathlib.Path(".")
broken = []
for md in list(root.glob("*.md")) + list((root / "docs").rglob("*.md")):
    txt = md.read_text(encoding="utf-8")
    for m in re.finditer(r'\[[^\]]+\]\(([^)#]+)\)', txt):
        target = m.group(1).strip()
        if not target or target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        resolved = (md.parent / target).resolve()
        if not resolved.exists():
            broken.append(f"{md}: broken link -> {target}")
if broken:
    for b in broken:
        print(b, file=sys.stderr)
    sys.exit(1)
PY
then
	ok "markdown relative links (0 broken)"
else
	ng "markdown relative links"
fi

echo "----------------------------------------"
printf 'PASS %d / FAIL %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
