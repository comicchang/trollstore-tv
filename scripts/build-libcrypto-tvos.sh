#!/bin/sh
# 构建 tvOS arm64 静态 libcrypto，供 trollstorehelper 链接。
# 输出: ChOma/external/tvos/libcrypto.a 与 ChOma/external/tvos-include/openssl/*
# 说明: OpenSSL 无 tvOS 目标，使用 ios64-cross 并把 SDK/目标平台覆盖为 AppleTVOS。
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${OPENSSL_VERSION:-3.5.1}
WORK=${WORK:-${TMPDIR:-/tmp}/openssl-tvos-build}
SDK_DIR=${SDK_DIR:-/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer}
SDK_NAME=${SDK_NAME:-$(basename "$SDK_DIR"/SDKs/AppleTVOS*.sdk 2>/dev/null | head -1)}
DEPLOY=${DEPLOY:-14.0}

usage() {
	cat <<'USAGE'
Usage: build-libcrypto-tvos.sh [-h|--help]

Cross-compile static OpenSSL libcrypto.a for tvOS arm64 into gitignored
ChOma/external/tvos/libcrypto.a and ChOma/external/tvos-include/openssl/.

Environment:
  OPENSSL_VERSION  OpenSSL version to download & build (default: 3.5.1)
  SDK_DIR          AppleTVOS platform Developer dir
  DEPLOY           Minimum tvOS deployment target (default: 14.0)
  WORK             Temporary build directory
USAGE
}

case "${1:-}" in
	-h|--help) usage; exit 0 ;;
	"") ;;
	*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

[ -d "$SDK_DIR/SDKs/$SDK_NAME" ] || { echo "tvOS SDK not found under $SDK_DIR/SDKs" >&2; exit 2; }

mkdir -p "$WORK"
[ -f "$WORK/openssl-$VERSION.tar.gz" ] || curl -sSL -o "$WORK/openssl-$VERSION.tar.gz" \
	"https://github.com/openssl/openssl/releases/download/openssl-$VERSION/openssl-$VERSION.tar.gz"

rm -rf "$WORK/openssl-$VERSION"
tar -C "$WORK" -xzf "$WORK/openssl-$VERSION.tar.gz"
cd "$WORK/openssl-$VERSION"

CROSS_TOP="$SDK_DIR" CROSS_SDK="$SDK_NAME" CC="clang -target arm64-apple-tvos$DEPLOY" \
	./Configure ios64-cross no-shared no-tests no-apps no-docs no-legacy \
	--prefix="$WORK/out"

CROSS_TOP="$SDK_DIR" CROSS_SDK="$SDK_NAME" CC="clang -target arm64-apple-tvos$DEPLOY" \
	make -j"$(sysctl -n hw.ncpu)" build_libs

mkdir -p "$ROOT/ChOma/external/tvos" "$ROOT/ChOma/external/tvos-include"
cp libcrypto.a "$ROOT/ChOma/external/tvos/libcrypto.a"
rm -rf "$ROOT/ChOma/external/tvos-include/openssl"
cp -R include/openssl "$ROOT/ChOma/external/tvos-include/"
echo "built: $ROOT/ChOma/external/tvos/libcrypto.a ($SDK_NAME, tvos$DEPLOY)"
