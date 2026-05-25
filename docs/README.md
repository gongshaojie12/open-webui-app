# 项目文档索引

本目录存放项目相关的修复记录、操作指南与排查文档。

---

## 一劳永逸修复：iOS build 报 `home_widget requires iOS 14.0, this target supports 13`

### 现象

Mac 上 Xcode build 失败，错误信息类似：

```
The package product 'home-widget' requires minimum platform version 14.0
for the iOS platform, but this target supports 13
```

### 根因

Flutter 3.41+ 引入了 Swift Package Manager（SPM）集成，会在 `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` 自动生成一个聚合包。**Flutter 3.41~3.44 的 SPM 模板把 iOS 最低版本写死成 `13.0`**（不读取 `AppFrameworkInfo.plist` 的 `MinimumOSVersion`，也不读 pbxproj 的 `IPHONEOS_DEPLOYMENT_TARGET`）。

但 `home_widget`（以及其他若干新插件）要求 iOS ≥ 14.0，所以一旦走 SPM 路径，build 必挂。

### 修复（一条命令，永久生效）

**关掉 Flutter 的 SPM 集成，全走 CocoaPods**（项目的 `ios/Podfile` 已经是 `platform :ios, '16.0'`，自然满足所有插件的最低要求）：

```bash
flutter config --no-enable-swift-package-manager
```

这是 **Flutter 全局配置**（写在 `~/.flutter_settings`），**设一次永久有效**，每台开发机（Windows / Mac）都需要各自跑一次。

### 设置后清理重建

```bash
cd /path/to/open-webui-app

flutter clean
rm -rf ios/Flutter/ephemeral      # 把已生成的 SPM 残留也删掉
flutter pub get
cd ios && pod install --repo-update && cd ..
open ios/Runner.xcworkspace       # macOS
```

之后 Xcode 里 `⇧⌘K` Clean → `⌘R` Run，错误消失。

### 验证

```bash
flutter config | grep -i swift
# 期望输出：  enable-swift-package-manager: false

ls ios/Flutter/ephemeral 2>/dev/null
# 期望输出：(空，目录不存在)
```

### 副作用评估

几乎没有。本项目当前所有 iOS 插件（`home_widget`、`vad`、`flutter_callkit_incoming`、`flutter_secure_storage`、`flutter_tex` 等）**全部都同时提供 CocoaPods podspec**，关掉 SPM 不影响任何功能。

只有极少数"SPM-only"的插件会受影响，目前 `pubspec.yaml` 里**一个都没有**。如果后续引入新插件时报 "No podspec found"，再考虑单独处理。

### 为什么不用脚本/Build Phase patch 那个文件？

也可以写 `sed` 脚本在每次 `flutter pub get` 后把 `13.0` 改成 `16.0`，但：

- 每次 `flutter clean` / 切分支 / CI 重新初始化都得跑
- 团队新人 clone 之后跑 build 必踩坑
- 在 Xcode Build Phase 里加 Run Script 会污染 pbxproj

而 `flutter config --no-enable-swift-package-manager` 是 **Flutter 官方支持的回退路径**，零维护、零侵入。

---

## 已修复的崩溃记录

### iPhone 17 Pro / iOS 26.4 启动闪退（已修复）

- **根因**：Flutter 3.41 UIScene 架构与旧 `Main.storyboard` 中 `customClass="FlutterViewController"` 冲突
- **详情**：[fix_ios_launch_crash_uiscene.md](./fix_ios_launch_crash_uiscene.md)
- **崩溃日志**：[crash/Runner-2026-05-25-15144[6-9].ips](./crash/)

### 历史安装错误修复

- [fix_install_error.md](./fix_install_error.md)

---

## 上游同步与版本管理

- **从上游合并代码的操作步骤**：[上游同步操作指南.md](./上游同步操作指南.md)
- **dev-0.0.1 分支相对于 main 的全部改动清单**：[dev-0.0.1_升级改动记录.md](./dev-0.0.1_升级改动记录.md)

---

## 截图与素材

- `screenshots/` — 应用截图
- `store-badges/` — 应用商店徽标
- 其余 `.png` / `.jpg` 文件为问题排查时的现场截图，与上述各 fix 文档关联
