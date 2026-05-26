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

> ⚠️ **如果上面 `ls` 仍然能看到 `FlutterGeneratedPluginSwiftPackage`**，说明本项目的 `ios/Runner.xcodeproj/project.pbxproj` 已经被 Flutter 在更早版本时**"SPM 迁移"**过了（pbxproj 里硬编码了 `XCLocalSwiftPackageReference` 指向 `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`）。这种情况下 `Package.swift` 文件会一直被生成出来，但是否真的卡 build，取决于它的 `dependencies` 数组里有没有插件 —— 看下面"方案 B"的判定。

---

## 方案 B：已 SPM 迁移项目的补丁（保留作为回退方案）

> **当前状态（Flutter 3.44.0 + 本项目插件集）：不需要执行此方案。**
> 实测 `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` 生成出来是这样的：
>
> ```swift
> platforms: [ .iOS("13.0") ],
> dependencies: [
>     // 空
> ],
> ```
>
> `dependencies` 是空数组 —— 即没有任何插件走 SPM，全部插件（包括 `home_widget`）都走 CocoaPods（`ios/Podfile`，`platform :ios, '16.0'`）。在这种状态下，umbrella 包顶部的 `.iOS("13.0")` 不会触发任何 14.0 最低版本检查，build 直接通过，**无需 sed**。
>
> **何时本方案重新生效**：如果将来升级 Flutter / 某个插件后，`cat Package.swift` 看到 `dependencies` 里出现 `.package(...home_widget...)` 之类的条目，并且 Xcode 报回老错误 `requires minimum platform version 14.0`，再回来按下面步骤跑 sed。

### 适用场景（仅当 dependencies 数组非空且出现 14.0 报错时）

`flutter config --no-enable-swift-package-manager` 已执行但无效——`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/` 每次 `flutter pub get` 都会重新生成，`Package.swift` 顶部 `platforms` 里写着 `.iOS("13.0")`，**且 `dependencies` 里已经塞了至少一个 iOS 14+ 的插件**。

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

## Mac 首次 build / `flutter clean` 后必须重跑 build_runner

### 现象

Xcode build 失败，错误数量动辄成百上千，但**全部收敛到几类样板报错**：

```
lib/core/models/chat_message.dart:7:6: Error: Error when reading 'lib/core/models/chat_message.freezed.dart': No such file or directory
lib/core/models/chat_message.dart:8:6: Error: Error when reading 'lib/core/models/chat_message.g.dart': No such file or directory
lib/core/models/chat_message.dart:11:31: Error: Type '_$ChatMessage' not found.
lib/core/models/chat_message.dart:50:8: Error: Couldn't find constructor '_ChatMessage'.
lib/features/chat/providers/chat_providers.dart:1538:20: Error: The getter 'error' isn't defined for the type 'ChatMessage'.
lib/features/chat/providers/chat_providers.dart:3547:30: Error: The method 'copyWith' isn't defined for the type 'ChatMessage'.
lib/core/providers/app_providers.dart:343:40: Error: Undefined name 'authStateManagerProvider'.
```

第一组 `Error when reading 'XXX.freezed.dart' / 'XXX.g.dart': No such file or directory` 是**真正的根因**，其余几百条都是它的下游症状（freezed 没生成 → 类型 `_$ChatMessage` 不存在 → 构造器 `_ChatMessage` 找不到 → `copyWith` / `error` / `versions` 等成员缺失）。

### 根因

项目用了 `freezed` + `riverpod_generator` + `json_serializable` 三个代码生成器（见 `pubspec.yaml` 的 `dev_dependencies`），它们在编译前要由 `build_runner` 把每个数据类 / Provider 编译成 `*.freezed.dart` / `*.g.dart` 同名 part 文件。

`.gitignore` 把 `*.g.dart` 和 `*.freezed.dart` **全部忽略**了 —— 它们是中间产物，不进 git。后果：

- **每台开发机要各自跑一次 build_runner**（Windows 上跑过 ≠ Mac 上有）
- 任何**清空了 `.dart_tool/` 或生成文件**的动作之后都要重跑

Mac 上第一次 clone 或 `flutter clean` 之后直接进 Xcode build，编译器就会因为 part 文件全部缺失而炸出几百条错误。

### 修复（在 **Mac** 上跑）

```bash
cd /path/to/open-webui-app

flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`--delete-conflicting-outputs` 是必须的：升级 `freezed` / `riverpod_generator` 版本后，旧的生成文件签名会和新模板冲突，加上这个参数让 build_runner 直接覆盖。

跑完后 `lib/core/models/` 下会出现一堆新的 `*.freezed.dart` / `*.g.dart`，**不要 commit**（`.gitignore` 已经管了）。

### Mac 上完整 build iOS 的标准 checklist

```bash
cd /path/to/open-webui-app

# 1. 清掉旧产物
flutter clean
rm -rf ios/Flutter/ephemeral

# 2. 拉依赖
flutter pub get

# 3. 跑代码生成器（freezed / riverpod_generator / json_serializable）
dart run build_runner build --delete-conflicting-outputs

# 4. CocoaPods
cd ios && pod install --repo-update && cd ..

# 5. 打开 workspace
open ios/Runner.xcworkspace
```

然后在 Xcode：

1. Scheme → Edit Scheme → Run → Build Configuration 设为 **Release**（脱离 Xcode 启动必须 Release，见下方"已修复的崩溃记录"第二条根因 A）
2. `⇧⌘K` Clean Build Folder
3. `⌘R` Run

> **可选第 4 步（仅当 Xcode 报 `requires minimum platform version 14.0` 时）**：先 `cat ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` 看 `dependencies` 数组是否非空。如果非空且报 14.0 错误，按方案 B 跑 sed 把 `.iOS("13.0")` 改成 `.iOS("16.0")`。当前 Flutter 3.44.0 + 本项目插件集下，`dependencies` 是空的，不会触发。

### 什么时候要重跑 build_runner

- 第一次 clone 项目（或换一台新机器）
- `flutter clean` 之后
- `flutter upgrade` 之后
- `flutter pub get` 后如果改了带 `part 'xxx.g.dart';` 或 `part 'xxx.freezed.dart';` 声明的文件
- 升级了 `freezed` / `json_serializable` / `riverpod_generator` 任意一个之后
- 改了任何 `@freezed` 类或 `@riverpod` provider 之后

> **省力做法**：开发期可以挂一个长跑的 `dart run build_runner watch --delete-conflicting-outputs`，改完文件立刻自动重生，不用手动触发。

### 副作用 / 风险

无。这条命令只生成本地中间产物，不改任何被 git 跟踪的源文件，不影响其它平台 build，也不会污染上游 diff。

---

## 副作用评估（方案 A / B 共通）

几乎没有。本项目当前所有 iOS 插件（`home_widget`、`vad`、`flutter_callkit_incoming`、`flutter_secure_storage`、`flutter_tex` 等）**全部都同时提供 CocoaPods podspec**，把最低版本拉到 16.0 不影响任何功能（pbxproj 里所有 target 本来就是 iOS 16.0）。

只有极少数"SPM-only"的插件会受影响，目前 `pubspec.yaml` 里**一个都没有**。如果后续引入新插件时报 "No podspec found" 或 "requires minimum platform version X.0"（X > 16），再考虑单独处理。

---

## 安装到 iPhone：本地测试与分发

`flutter build ios --release` 只产出 `build/ios/iphoneos/Runner.app`（未签名的 .app bundle），iOS 不接受直接拖装。下面是把 App 装上 iPhone 的三个方案。

### 方案 1（最简单，推荐用于自测）：`flutter run --release`

iPhone 用 USB 连 Mac，已在 Trust 列表里：

```bash
flutter devices                          # 确认能看到你的 iPhone
flutter run --release -d <device-id>     # 编译 + 签名 + 安装 + 启动，一气呵成
```

内部会调 Xcode 工具链做签名、用 `devicectl` 装到设备。优点是不用手动开 Xcode；缺点是必须 USB 连着启动（启动后可拔，App 留在设备上能脱机跑）。

签名身份用 `ios/Runner.xcworkspace` 里已经配过的（个人免费 Apple ID 或付费开发者账号都行）。免费 Apple ID 签出来的 App **证书 7 天有效**，过期要重装；付费账号 1 年。

### 方案 2：在 Xcode 里 `⌘R`

1. `open ios/Runner.xcworkspace`
2. Scheme → Edit Scheme → Run → Build Configuration = **Release**
3. 顶部目标选你的 iPhone（不是模拟器）
4. `⌘R`

跟方案 1 等价，只是 UI 走 Xcode。出问题时错误信息更直观。

### 方案 3：打 `.ipa` 分发（给别人装 / 上 TestFlight）

```bash
flutter build ipa --release
```

产出在 `build/ios/ipa/conduit.ipa`。但是：

- **必须有付费 Apple Developer 账号**（$99/年），免费 Apple ID 跑这条命令会直接报错
- 装 ipa 到 iPhone 的方式：
  - **Apple Configurator 2**（Mac App Store 免费）：拖 .ipa 到设备图标
  - **Xcode → Window → Devices and Simulators**：点设备 → "+" → 选 ipa
  - **TestFlight**：上传到 App Store Connect，邀请测试者安装（正式的远程 beta 测试方式）

### 给别人测试是否必须付费账号？

**是的，付费 $99/年是硬性要求。** 免费 Apple ID 有几个限制堵死了"给别人测试"这个场景：

- 签出来的 App 只能装在**已登录该 Apple ID 的设备**，且必须通过你的 Mac + Xcode 直连安装
- 每个 Apple ID 最多 3 台设备
- **证书 7 天后过期**，App 自动失效要重装
- 打不了 `.ipa`，没有 TestFlight 权限

付费 $99/年（Apple Developer Program）后有两条分发路：

| 方式 | 测试人数 | 是否需要 UDID | 用户体验 |
|---|---|---|---|
| **TestFlight** | 最多 10000 人 | 不需要 | 装 TestFlight App，点邀请链接，一键安装。每个版本 90 天可用 |
| **Ad-Hoc** | 最多 100 台 iPhone/年 | **需要**先收集每个测试者的 UDID 注册 | 你打针对这些设备的 ipa，用 Apple Configurator / Diawi 等装 |

**强烈推荐 TestFlight**：不用收集 UDID、安装体验接近正式 App、自带崩溃日志与反馈、后续上架 App Store 时这条流程是必经之路。

#### 实际建议

- **短期内部自测（3~5 人、几天）**：让人带 iPhone 来你 Mac 这边用方案 1 直接装，免费够用，但 7 天失效
- **正式 beta、远程测试、用户量 >5 人或周期 >1 周**：交 $99 注册 Apple Developer，走 TestFlight
- **灰色方案（不推荐）**：第三方签名工具（爱思助手、AltStore、Sideloadly）用别人证书重签，证书随时可能被吊销导致 App 全部失效，公司项目不要走

---

## 配置变更记录

### 2026-05-26：服务器地址切换到生产环境

**改动文件：** `lib/core/config/app_config.dart`

| 常量 | 旧值（测试） | 新值（生产） |
|---|---|---|
| `serverUrl` | `https://1.94.62.87` | `https://chat.focusmedia.cn` |
| `allowSelfSignedCertificates` | `true` | `false` |

**为什么 SSL 开关也要跟着改**：

- 测试环境用 IP 直连 + 自签证书 → 必须 `true`，否则 SSL 握手失败
- 生产域名 `chat.focusmedia.cn` 用公网 CA 签的证书（已用 `curl --ssl-revoke-best-effort` 验证握手正常） → 必须 `false`，否则等于关掉中间人攻击的最后一道防线

**切回测试环境的方法**：把上面两行同时改回测试值，重新 build。详见 [dev-0.0.1_升级改动记录.md §3](./dev-0.0.1_升级改动记录.md)。

**关于已装 App 是否需要重装**：不需要。`activeServer` provider 启动时会自动比对持久化的 `id='default'` 配置和当前 `AppConfig`，发现漂移就 in-place 更新存储。所以：

- 切环境（test↔prod）只需改 `app_config.dart` 两个常量 → 提交 → 用户升级 App → 启动时自动迁移到新地址
- 用户会被踢回登录页（旧 token 在新服务器无效，这是预期行为）
- 用户通过 UI 手动添加的其它服务器配置不会被这套同步逻辑动到（只动 `id == 'default'`）

详见 [dev-0.0.1_升级改动记录.md §4](./dev-0.0.1_升级改动记录.md)。

**如何自行验证 chat.focusmedia.cn 仍是 CA 签**（未来证书变化时复查）：

```bash
curl -v https://chat.focusmedia.cn/ 2>&1 | grep -E "issuer|subject"
# issuer 是 Let's Encrypt / DigiCert 等 CA 公司 → CA 签，allowSelfSignedCertificates 保持 false
# issuer 与 subject 相同 / 出现 self-signed 字样 → 改回自签，需要把开关切 true
```

---

## 已修复的崩溃记录

### iPhone 17 Pro / iOS 26.4 启动闪退（已修复）

修复分两步，按顺序排查到位才能完整复现：

1. **第一步：`Main.storyboard` 残留 `customClass="FlutterViewController"`**
   - **根因**：Flutter 3.41 UIScene 架构下，VC 由 SceneDelegate 代码创建；storyboard 里若再指定 `customClass`，UIScene 启动会走 storyboard 路径多实例化一个孤儿 VC，与 SceneDelegate 创建的 VC 冲突
   - **详情**：[fix_ios_launch_crash_uiscene.md](./fix_ios_launch_crash_uiscene.md)
   - **崩溃日志**：[crash/Runner-2026-05-25-15144[6-9].ips](./crash/)

2. **第二步：SceneDelegate 中 `engine.run()` 顺序错误 + Debug 构建脱离 Xcode**
   - **根因 A**：Debug 构建在 iOS 14+ 脱离调试器启动时，`FlutterEngine(name:)` 会返回 nil（ptrace 失败），透传给 `FlutterViewController(engine:)` 触发 `FML_CHECK(engine)` abort
   - **根因 B**：`FlutterViewController(engine:)` 假设 engine 已 `run`（init 内部置 `_engineNeedsLaunch = NO` 并 `setViewController:`）；若顺序反了，VC init 会访问 nil shell 的 mutex 字段 → `pthread_mutex_lock(0x80)` 崩溃
   - **详情**：[fix_ios_scene_engine_order.md](./fix_ios_scene_engine_order.md)
   - **崩溃日志**：`Runner-2026-05-26-115452.ips`、`Runner-2026-05-26-134730.ips`

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
