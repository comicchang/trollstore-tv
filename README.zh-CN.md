# TrollStore TV（tvOS 17.0 免越狱 non-Lite 移植版）

[English](README.md)

面向 **Apple TV 4K（`AppleTV14,1` / tvOS 17.0 `21J354`）** 的可编译、可实测运行的 **non-Lite（免越狱）TrollStore** 移植版本，基于 [`straight-tamago/TrollStore-tvOS`](https://github.com/straight-tamago/TrollStore-tvOS)（`f1ebe52`）与 [`opa334/TrollStore`](https://github.com/opa334/TrollStore) 深度适配现代 Xcode tvOS SDK。

借助 CoreTrust 签名链（`TeamIdentifier=T8ALTGMVXN`），通过本工具安装的应用**冷重启后可在未越狱态直接打开**，无需依赖越狱 `trustcache`。

## 真机实测状态（Apple TV 4K / tvOS 17.0 `21J354`）

| 能力项 | 状态 | 说明 |
| --- | --- | --- |
| 现代 Xcode tvOS SDK 完整编译（`TrollStore.app` + `trollstorehelper`） | **已实证** | `arm64`、`LC_BUILD_VERSION platform=tvOS`、零 `dynamic_lookup` 符号 |
| 设备端无 `ldid` 签名（内置 ChOma ad-hoc + CoreTrust） | **已实证** | 彻底消除 tvOS 下越狱 `ldid` 崩溃；完整保留嵌套 `.appex` entitlements |
| 非 root 应用（`uid=501`）→ `trollstorehelper`（`uid=0`）`persona` 提权 | **已实证** | [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h) 通过 `dlsym` 恢复调用 |
| **冷重启未越狱存活**（`TrollStore.app` 与已装应用未越狱直接启动） | **已实证（PASS）** | 原厂只读 SSV tvOS 17.0 冷重启实测通过 |
| 设备端多二进制实战安装（`trollstorehelper`） | **已实证** | 实测安装并运行 `RelaxinTest`（5 Mach-O）、`YouTubeTVL`（2 Mach-O）、`Kodi` v21.3（**108 Mach-O**：主程序 + `.appex` + 106 个插件/框架 dylib），零 `trustcache` 依赖 |
| `/Applications` 系统应用 Persistence Helper 注入 | **上游既有边界** | 默认不修改 `/Applications` 系统卷应用 |
| 电视端遥控器 UI / URL 交互安装 | **持续完善** | 原生 tvOS 设置页 `TSTVSettingsController` 与底层安装链已跑通，交互体验持续打磨 |

## 相对上游（`f1ebe52`）的核心改动

- **现代 tvOS SDK 兼容与零 `dynamic_lookup`**：
  - [`Shared/TSSpawnCompat.h`](Shared/TSSpawnCompat.h)：用 `dlsym` 封装 `posix_spawn` 及 `posix_spawnattr_set_persona_*_np`（tvOS SDK 头文件标为 unavailable，但运行时 `libSystem.B.dylib` 完整导出）。
  - [`RootHelper/TSPrivateRefs.h`](RootHelper/TSPrivateRefs.h) / [`RootHelper/TSPrivateRefs.m`](RootHelper/TSPrivateRefs.m) + `ts_loadTVPrivateFrameworks()`：启动时 `dlopen` 真机 dyld 共享缓存中的 6 个私有框架并通过 `NSClassFromString` / `dlsym` 调用，消除全部链接期未定义符号。
  - [`RootHelper/devmode.m`](RootHelper/devmode.m)：用 `dlsym` 兼容 tvOS `libxpc` 与 `_CFXPC*` 桥接。
- **内置 ChOma 签名（tvOS 不再依赖外部 `ldid`）**：
  - [`RootHelper/main.m`](RootHelper/main.m)：tvOS 平台统一改用内嵌 ChOma `codesign_sign_adhoc`；先对整包 Mach-O 规范化 ad-hoc 签名，再为主程序与所有嵌套 `.appex` 写入各自 entitlements。
  - [`TrollStore/TSSceneDelegate.m`](TrollStore/TSSceneDelegate.m)：tvOS 启动时跳过 `ldid` 自动下载。
- **tvOS 原生设置界面**：
  - [`TrollStore/TSTVSettingsController.h`](TrollStore/TSTVSettingsController.h) / [`TrollStore/TSTVSettingsController.m`](TrollStore/TSTVSettingsController.m)：用原生 `UITableViewController` 替代 iOS 私有 `Preferences/PSListController`，屏蔽 `UIPasteboard`、`UISearchController`、`UIDocumentPickerDelegate`、`CoreTelephony`、`MobileIcons` 等 iOS 专属 API。
- **宿主机工具与一键可复现构建**：
  - [`Exploits/fastPathSign/src/main.m`](Exploits/fastPathSign/src/main.m)：支持直接签名 thin arm64 Mach-O（无需 FAT 包装）。
  - [`scripts/build-libcrypto-tvos.sh`](scripts/build-libcrypto-tvos.sh)：可复现编译 tvOS arm64 静态 `libcrypto.a` 到 `ChOma/external/tvos/`（已 gitignore）。
  - [`scripts/build-tvos.sh`](scripts/build-tvos.sh)：一键编译 `fastPathSign`、`trollstorehelper`、`TrollStore.app`，自动校验零 `dynamic_lookup` 与 `T8ALTGMVXN` 签名并打包 `_build/TrollStore-tvOS.{tar,ipa}`。

详细移植经验与踩坑总结见 [`docs/TVOS-PORTING-NOTES.md`](docs/TVOS-PORTING-NOTES.md)。

## 从源码构建（macOS）

### 前置依赖

- macOS + 完整版 **Xcode**（含 AppleTVOS SDK）
- **[Theos](https://theos.dev/docs/installation)**（配置 `$THEOS`，默认 `~/theos`）
- **Homebrew**：`libarchive`、`openssl`（可选 `shellcheck` 用于本地校验）

### 一键编译与打包

```sh
# 1. 构建 tvOS arm64 静态 libcrypto.a（首次执行，产物位于 gitignored 的 ChOma/external/tvos/）
./scripts/build-libcrypto-tvos.sh

# 2. 编译 fastPathSign、trollstorehelper、TrollStore.app 并打包 _build/TrollStore-tvOS.{tar,ipa}
./scripts/build-tvos.sh
```

只预览构建步骤（不改文件）：

```sh
./scripts/build-tvos.sh --dry-run
```

运行本地语法、卫生与防回归校验：

```sh
./tests/run.sh
```

## 实战排障要点

- **标准沙箱 vs `platform-application`**：普通应用或需要 `IOSurfaceRootUserClient` 的工具类应用，应保留标准沙箱权限并交给 `trollstorehelper` 自动注入 `com.apple.private.security.container-required=<bundle-id>`；若强加 `platform-application` + `no-sandbox` 而未声明 `com.apple.security.exception.iokit-user-client-class`，在 tvOS 17 上会触发 `Failed to create surface`。
- **`no-container` 应用数据路径（如 Kodi）**：`trollstorehelper` 会保留原包自带的 `no-container=true`，应用在越狱态与未越狱态统一读写 `/private/var/mobile/Library/Caches/<App>`，迁移旧数据时需从越狱 `.jbroot` 目录同步至该真实路径即可重启不丢数据。
- **切勿预先 `fastPathSign` 再喂给 `trollstorehelper`**：已做过 CoreTrust bypass 的二进制会被设备 Security 框架拒绝重签（`-67048`）；请直接向 `trollstorehelper` 提供普通 ad-hoc 签名或未签名 IPA。

## 致谢与开源协议

- 原始 TrollStore：[Lars Fröder (`opa334`)](https://github.com/opa334/TrollStore) 及贡献者
- 早期 tvOS 移植：[`straight-tamago`](https://github.com/straight-tamago/TrollStore-tvOS)
- CoreTrust 研究：Google TAG、`@alfiecg_dev`、`@LinusHenze`、ChOma 贡献者
- `uicache`：CoolStar、Procursus Team、`opa334`

遵循 [`LICENSE`](LICENSE) 协议（MIT，其中 `RootHelper/uicache.m` 为 BSD-4-Clause）；详见 [`NOTICE`](NOTICE)、[`CONTRIBUTING.md`](CONTRIBUTING.md) 与 [`SECURITY.md`](SECURITY.md)。
