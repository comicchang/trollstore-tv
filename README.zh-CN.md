# TrollStore TV

[![CI](https://github.com/comicchang/trollstore-tv/actions/workflows/ci.yml/badge.svg)](https://github.com/comicchang/trollstore-tv/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-tvOS%2017.0%20(21J354)-blue)
![License](https://img.shields.io/badge/license-MIT%20%2F%20BSD--4--Clause-green)

[English](README.md) | **简体中文**

面向 **Apple TV 4K（`AppleTV14,1` / tvOS 17.0 `21J354`）** 的可编译、已通过冷重启存活实测的 **TrollStore 免越狱移植版**，基于 [`straight-tamago/TrollStore-tvOS`](https://github.com/straight-tamago/TrollStore-tvOS)（`f1ebe52`）与 [`opa334/TrollStore`](https://github.com/opa334/TrollStore) 深度适配现代 Xcode tvOS SDK。

借助 CoreTrust 签名链（`TeamIdentifier=T8ALTGMVXN`），通过本工具安装的应用**冷重启后可在未越狱态直接打开**，无需依赖越狱 `trustcache` 或外部 `ldid`。

> 如需宿主机 CoreTrust 批量签名脚本、干净室 tvOS 探针源码与重启验收工具，请见配套仓库 **[`trollstore-tv-tools`](https://github.com/comicchang/trollstore-tv-tools)**。

---

## 真机实测状态（Apple TV 4K / tvOS 17.0 `21J354`）

| 能力项 | 状态 | 说明 |
| --- | --- | --- |
| 现代 Xcode tvOS SDK 完整编译（`TrollStore.app` + `trollstorehelper`） | **已实证** | `arm64`、`LC_BUILD_VERSION platform=tvOS`、`0` 个 `dynamic_lookup` 符号 |
| 设备端无 `ldid` 签名（内置 ChOma） | **已实证** | 彻底消除 tvOS 越狱 `ldid` 崩溃；完整保留嵌套 `.appex` entitlements |
| 非 root 应用（`uid=501`）→ `trollstorehelper`（`uid=0`）`persona` 提权 | **已实证** | [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h) 运行时 `dlsym` 恢复 |
| **冷重启未越狱存活** | **已实证** | 原厂只读 SSV tvOS 17.0 冷重启后 `TrollStore.app` 与已装应用均可直接打开 |
| 真实多二进制 IPA 安装 | **已实证** | 实测通过 5-Mach-O 应用（含内嵌框架与 dylib）、解密媒体客户端（2 Mach-O）与 Kodi 21.3（**108 Mach-O**：主程序 + `.appex` + 106 个 dylib），零 `trustcache` 写入 |
| `/Applications` 系统应用 Persistence Helper 注入 | **上游既有边界** | 默认不修改只读 SSV `/Applications` |
| 电视端遥控器 UI / URL 交互安装 | **持续完善** | 原生 tvOS 设置页 `TSTVSettingsController` 与底层安装链已跑通，遥控器交互持续优化 |

---

## 相对上游（`f1ebe52`）的核心改动

- **现代 tvOS SDK 兼容与零 `dynamic_lookup`**：
  - [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h)：通过 `dlsym` 封装 `posix_spawn*` 与 `posix_spawnattr_set_persona_*_np`。
  - [`RootHelper/TSPrivateRefs.h`](RootHelper/TSPrivateRefs.h) / [`RootHelper/TSPrivateRefs.m`](RootHelper/TSPrivateRefs.m) + `ts_loadTVPrivateFrameworks()`：启动时 `dlopen` tvOS dyld 共享缓存中的 6 个私有框架并通过 `NSClassFromString` / `dlsym` 调用，彻底消除加载期未定义符号。
  - [`RootHelper/devmode.m`](RootHelper/devmode.m)：用 `dlsym` 兼容 tvOS `libxpc` 与 `_CFXPC*`。
- **内置 ChOma 签名（不再依赖外部 `ldid`）**：
  - [`RootHelper/main.m`](RootHelper/main.m)：tvOS 下改用内嵌 ChOma `codesign_sign_adhoc`，先对全部常规 Mach-O 规范化签名，再逐一写入主程序与嵌套 `.appex` 的 entitlements。
  - [`TrollStore/TSSceneDelegate.m`](TrollStore/TSSceneDelegate.m)：tvOS 启动时跳过 `ldid` 自动下载。
- **tvOS 原生界面**：
  - [`TrollStore/TSTVSettingsController.m`](TrollStore/TSTVSettingsController.m)：用原生 `UITableViewController` 替代 iOS 私有 `Preferences/PSListController`，屏蔽 `UIPasteboard`、`UISearchController`、`UIDocumentPickerDelegate`、`CoreTelephony`、`MobileIcons` 等 iOS 专属 API。
- **宿主机工具与一键可复现构建**：
  - [`Exploits/fastPathSign/src/main.m`](Exploits/fastPathSign/src/main.m)：支持直接签名 thin arm64 Mach-O。
  - [`scripts/build-libcrypto-tvos.sh`](scripts/build-libcrypto-tvos.sh)：交叉编译 tvOS arm64 静态 OpenSSL `libcrypto.a`（已 gitignore）。
  - [`scripts/build-tvos.sh`](scripts/build-tvos.sh)：一键编译、校验零 `dynamic_lookup` 与 `T8ALTGMVXN` 签名并打包 `_build/TrollStore-tvOS.{tar,ipa}`。

完整移植与踩坑笔记见 [`docs/TVOS-PORTING-NOTES.md`](docs/TVOS-PORTING-NOTES.md)。

---

## 从源码构建（macOS）

### 前置依赖

- macOS + 完整版 **Xcode**（含 AppleTVOS SDK）
- **[Theos](https://theos.dev/docs/installation)**（配置 `$THEOS`，如 `~/theos`）
- **Homebrew**：`libarchive`、`openssl`（可选 `shellcheck`）

### 一键编译与打包

```sh
# 1. 交叉编译 tvOS arm64 静态 libcrypto.a（首次执行）
./scripts/build-libcrypto-tvos.sh

# 2. 编译 fastPathSign、trollstorehelper、TrollStore.app 并打包
./scripts/build-tvos.sh
```

只预览构建命令（不改文件）：

```sh
./scripts/build-tvos.sh --dry-run
```

运行本地语法、防回归与隐私卫生校验：

```sh
./tests/run.sh
```

产物位于 `_build/`：
- `_build/TrollStore-tvOS.tar`（供 `trollstorehelper install-trollstore` 安装）
- `_build/TrollStore-tvOS.ipa`（标准 `Payload/TrollStore.app` 压缩包）

---

## 首次部署到 Apple TV（tvOS 17.0 临时越狱 SSH）

```sh
# 1. 上传 trollstorehelper 与 TrollStore-tvOS.tar
#    （注：RootHide 越狱下真实 rootfs 的 /private/var/tmp 对应 /rootfs/private/var/tmp）
scp _build/pkg/TrollStore.app/trollstorehelper _build/TrollStore-tvOS.tar mobile@192.0.2.10:/var/tmp/

# 2. 在 Apple TV 端（root 权限）拷入真实 rootfs 并自安装
sudo cp /var/tmp/trollstorehelper /var/tmp/TrollStore-tvOS.tar /rootfs/private/var/tmp/
sudo chmod 755 /rootfs/private/var/tmp/trollstorehelper
sudo /rootfs/private/var/tmp/trollstorehelper install-trollstore /private/var/tmp/TrollStore-tvOS.tar

# 3. 清理临时文件
sudo rm -f /var/tmp/trollstorehelper /var/tmp/TrollStore-tvOS.tar \
           /rootfs/private/var/tmp/trollstorehelper /rootfs/private/var/tmp/TrollStore-tvOS.tar
```

安装完成后，冷重启回到未越狱态即可直接打开 `TrollStore` 与通过其安装的各类 tvOS 应用。

---

## Entitlements 与数据容器说明

- **标准沙箱应用**：保持标准沙箱权限，交给 `trollstorehelper` 自动注入 `com.apple.private.security.container-required=<bundle-id>`；若强加 `platform-application` + `no-sandbox` 而未显式声明 `com.apple.security.exception.iokit-user-client-class`，在 tvOS 17 上可能触发 `Failed to create surface`。
- **`no-container` 应用（如 Kodi）**：`trollstorehelper` 保留 `com.apple.private.security.no-container=true`，应用在越狱与未越狱态统一读写 `/private/var/mobile/Library/Caches/<App>`。
- **输入 IPA 要求**：请向 `trollstorehelper` 提供未签名或普通 ad-hoc 签名 IPA，切勿预先做 `fastPathSign`（设备 Security 框架会拒绝重签已 bypass 的 Mach-O，报 `-67048`）。

---

## 致谢与开源协议

- [Lars Fröder (`opa334`)](https://github.com/opa334/TrollStore) — 原始 TrollStore
- [`straight-tamago`](https://github.com/straight-tamago/TrollStore-tvOS) — 早期 tvOS 移植
- Google TAG、`@alfiecg_dev`、`@LinusHenze` 及 ChOma 贡献者 — CoreTrust 研究与工具库
- CoolStar、Procursus Team、`opa334` — `uicache`

遵循 [`LICENSE`](LICENSE)（MIT，其中 `RootHelper/uicache.m` 为 BSD-4-Clause）；详见 [`NOTICE`](NOTICE)、[`CHANGELOG.md`](CHANGELOG.md)、[`CONTRIBUTING.md`](CONTRIBUTING.md) 与 [`SECURITY.md`](SECURITY.md)。
