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

ls ios/Flutter/ephemeral/Packages 2>/dev/null
# 期望输出：(空，目录不存在)。注意要看 Packages/ 子目录，
# ephemeral/ 根目录下的 flutter_lldb_helper.py / flutter_lldbinit / flutter_native_integration.env
# 是 LLDB 调试辅助文件，无论开不开 SPM 都会生成，不影响。
```

> ⚠️ **如果上面 `ls` 仍然能看到 `FlutterGeneratedPluginSwiftPackage`**，说明本项目的 `ios/Runner.xcodeproj/project.pbxproj` 已经被 Flutter 在更早版本时**"SPM 迁移"**过了（pbxproj 里硬编码了 `XCLocalSwiftPackageReference` 指向 `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`）。这种情况下，**全局 `flutter config --no-enable-swift-package-manager` 会被忽略**，每次 `flutter pub get` 仍然会再生成那个 `Package.swift`，build 仍然会挂在 iOS 13.0 上。
>
> 本项目目前**就是这个状态**，所以请走下面的"方案 B（sed 补丁）"。

---

## 方案 B：已 SPM 迁移项目的补丁（本项目当前实际方案）

### 适用场景

`flutter config --no-enable-swift-package-manager` 已执行但无效——`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/` 每次 `flutter pub get` 都会重新生成，且 `Package.swift` 顶部 `platforms` 里始终是 `.iOS("13.0")`。

### 根因

`ios/Runner.xcodeproj/project.pbxproj` 在历史某次升级时被 Flutter 工具链改成了 SPM 模式（Runner target 含有 `XCLocalSwiftPackageReference` / `XCSwiftPackageProductDependency`，product 名为 `FlutterGeneratedPluginSwiftPackage`）。Flutter 看到 pbxproj 已经持有该本地包引用，就**绕过全局开关**继续生成它。

要彻底回退到纯 CocoaPods 需要改动 pbxproj（删 `XCLocalSwiftPackageReference` 与 `XCSwiftPackageProductDependency`），风险高、和上游 diff 大。所以采用**一次 sed 补丁**把 `13.0` 改成 `16.0`，与 `ios/Podfile` 的 `platform :ios, '16.0'` 对齐，让 `home_widget` 等 iOS 14+ 插件通过最低版本检查。

### 操作（每次 `flutter clean` / `flutter pub get` 之后跑一遍）

```bash
cd /path/to/open-webui-app

sed -i '' 's/\.iOS("13\.0")/.iOS("16.0")/' \
  ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift

# 验证一行就够，应该输出：  .iOS("16.0")
grep iOS ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
```

> macOS 自带的 BSD `sed` 需要 `-i ''`（空字符串作为备份后缀），Linux GNU sed 写法是 `sed -i 's/.../.../'`。本项目 iOS 只能在 Mac 上 build，所以用 BSD 写法。

### 然后在 Xcode 里

1. **File → Packages → Reset Package Caches**（让 Xcode 重读 `Package.swift`，重新解析最低版本）
2. **Product → Clean Build Folder**（`⇧⌘K`）
3. **Product → Run**（`⌘R`）

之前那条 `package product 'home-widget' requires minimum platform version 14.0` 报错应该消失。

### 什么时候要重跑这条 sed

- 每次 `flutter clean` 后第一次 build 前
- 每次 `flutter pub get` 后（包括 `flutter pub upgrade`、改了 `pubspec.yaml` 之后）
- 切分支导致 `ios/Flutter/ephemeral/` 被清空之后
- `flutter upgrade` 之后

**怎么省事**：把上面三行命令在 Mac 终端跑过一次后，按 `Ctrl+R` 输入 `sed` 即可从历史里复用，0.5 秒搞定。也可以考虑把它加进 `ios/Podfile` 的 `post_install` 里自动化（但要小心 `pub get` 是发生在 `pod install` 之前还是之后；目前不加是为了减少和上游 diff）。

### 上游同步注意

这条 sed 是**纯本地补丁**，不写进任何被 git 跟踪的文件：
- `ios/Flutter/ephemeral/` 整个目录已被 `.gitignore` 忽略
- `ios/Runner.xcodeproj/project.pbxproj` 不会改动
- `pubspec.yaml` / `Podfile` 不会改动

所以从上游 merge 后**只需重跑这条 sed**即可继续 build，不会产生冲突。

### 长期想彻底解决？

两条路，但都不推荐现在做（侵入性 vs 收益不成正比）：

1. **手动改 pbxproj 删掉 SPM 引用**：找到 `XCLocalSwiftPackageReference "FlutterGeneratedPluginSwiftPackage"` 整段、`XCSwiftPackageProductDependency` 中对应的 product、Runner target 的 `packageProductDependencies` 数组里的引用，三处一起删。删完之后 `flutter config --no-enable-swift-package-manager` 才会真正生效。但每次上游升级 Flutter 都可能把它写回去。
2. **等 Flutter 修复 SPM 模板**：Flutter 团队已知此问题，预期在 SPM 模板里读 `IPHONEOS_DEPLOYMENT_TARGET` 而不是写死 `13.0`。届时升级 Flutter 后此 sed 可移除。

在那之前，**sed 补丁是最低成本方案**。

---

## 副作用评估（方案 A / B 共通）

几乎没有。本项目当前所有 iOS 插件（`home_widget`、`vad`、`flutter_callkit_incoming`、`flutter_secure_storage`、`flutter_tex` 等）**全部都同时提供 CocoaPods podspec**，把最低版本拉到 16.0 不影响任何功能（pbxproj 里所有 target 本来就是 iOS 16.0）。

只有极少数"SPM-only"的插件会受影响，目前 `pubspec.yaml` 里**一个都没有**。如果后续引入新插件时报 "No podspec found" 或 "requires minimum platform version X.0"（X > 16），再考虑单独处理。

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
