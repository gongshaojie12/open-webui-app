# iOS 启动闪退修复：UIScene 迁移与 Main.storyboard 冲突

> **修复日期：** 2026-05-25
> **影响版本：** 3.1.0 (build 116)
> **影响范围：** iPhone 17 Pro / iOS 26.4（ProMotion + iOS 26 系列设备 100% 必现）
> **关联 Flutter 版本：** Flutter 3.41.4（commit `e6e11ff` 升级后引入）
> **关联崩溃日志：** `docs/crash/Runner-2026-05-25-15144[6-9].ips`（4 份完全相同）

---

## 一、现象

通过 Xcode 数据线把 Release/Debug 包安装到 iPhone 17 Pro（iOS 26.4）后，点击图标启动应用，**约 400ms 后立即闪退**，连 Flutter 引擎初始化都没走到。模拟器、旧机型（非 ProMotion）不一定复现。

## 二、崩溃指纹

| 项目 | 值 |
|---|---|
| 异常 | `EXC_BAD_ACCESS (SIGSEGV)` |
| 子类型 | `KERN_INVALID_ADDRESS at 0x0` |
| ESR | `(Data Abort) byte read Translation fault` |
| 触发线程 | `com.apple.main-thread` |
| 启动到崩溃 | ~436 ms |

**调用栈（Thread 0 顶部）：**

```
0  Flutter   -[VSyncClient initWithTaskRunner:callback:] + 300       ← 解引用 NULL
1  Flutter   -[FlutterViewController createTouchRateCorrectionVSyncClientIfNeeded] + 216
2  Flutter   -[FlutterViewController viewDidLoad] + 396
3  UIKitCore -[UIViewController _sendViewDidLoadWith...]
4  UIKitCore -[UIViewController loadViewIfRequired]
5  UIKitCore -[UIViewController view]
6  UIKitCore -[UIWindow addRootViewControllerViewIfPossible]
…
10 UIKitCore -[UIWindowScene _performDeferredInitialWindowUpdateForConnection]
11 UIKitCore +[UIScene _sceneForFBSScene:create:withSession:connectionOptions:]
12 UIKitCore -[UIApplication _connectUISceneFromFBSScene:transitionContext:]
```

## 三、根本原因

**Flutter 3.41 UIScene 迁移与旧 `Main.storyboard` 中的 `FlutterViewController` 共存导致"裸 VC 拿不到引擎"。**

1. `ios/Runner/Info.plist` 已经声明 UIScene 架构：
   - `UISceneDelegateClassName = FlutterSceneDelegate`
   - `UISceneStoryboardFile = Main`
2. iOS 走 UIScene 路径，按 `UISceneStoryboardFile = Main` 加载 `Main.storyboard`。
3. storyboard 里的 root VC 写死了 `customClass="FlutterViewController"`，系统用 `-initWithCoder:` 实例化，**没有任何 FlutterEngine 被附加**（`taskRunner == nil`）。
4. `viewDidLoad` → `createTouchRateCorrectionVSyncClientIfNeeded` → `VSyncClient init` 在 offset 300 尝试通过 nil 的 `taskRunner` 发任务 → 空指针解引用 → 立即段错误。

**为什么 Flutter 3.41 之前不崩：** 旧的 `FlutterAppDelegate` 路径下，storyboard 里的 `FlutterViewController` 会被全局 engine 自动绑定。3.41 换成 **`FlutterImplicitEngineDelegate` + `FlutterSceneDelegate` + 隐式引擎**之后，引擎是按 scene 生命周期延迟创建并绑定到 SceneDelegate 自己创建的 `FlutterViewController` 上的——storyboard 路径与隐式引擎路径互不通气。

**为什么 iPhone 17 Pro / iOS 26 必现：** iOS 26 的 `_performDeferredInitialWindowUpdateForConnection` 执行时机更早；ProMotion 设备会立即触发 `createTouchRateCorrectionVSyncClientIfNeeded`（非 ProMotion 不一定走这条分支），所以 ProMotion + iOS 26 组合 100% 复现。

## 四、修复方式（方案 A）

**文件：** `ios/Runner/Base.lproj/Main.storyboard`

把 storyboard 的 root VC **去掉 `customClass="FlutterViewController"`**，让它退回成普通 `UIViewController` 占位 VC。这样 `FlutterSceneDelegate` 在 scene 激活时，会用隐式引擎自己 new 一个 `FlutterViewController` 并替换 root VC。

### 改动 diff

```diff
-        <!--Flutter View Controller-->
+        <!--Placeholder root VC; FlutterSceneDelegate replaces this with a FlutterViewController bound to the implicit engine on scene connection (Flutter 3.41+ UIScene flow).-->
         <scene sceneID="tne-QT-ifu">
             <objects>
-                <viewController id="BYZ-38-t0r" customClass="FlutterViewController" sceneMemberID="viewController">
+                <viewController id="BYZ-38-t0r" sceneMemberID="viewController">
```

只动 storyboard 一处，不动 `Info.plist`、不动 `AppDelegate.swift`、不动 `pbxproj`。`LaunchScreen.storyboard` 不要动。

## 五、验证清单

- [ ] iPhone 17 Pro / iOS 26.x：Xcode Run 直接安装，App 能正常进入登录页
- [ ] iPhone 模拟器（iOS 18.x、17.x）：能正常启动
- [ ] iPad 模拟器：能正常启动
- [ ] 后台/前台切换、锁屏唤醒：场景生命周期回调正常
- [ ] 通过分享扩展、Widget URL Scheme（`ShareMedia-app.cogwheel.conduit`、`$(APP_URL_SCHEME)`）唤起 App：能进入对应路由
- [ ] 通过 AppIntents（"Ask 众小智AI" 等）唤起：能进入对应路由

## 六、上游同步注意事项 ⚠️

**Flutter 上游的 `ios/Runner/Base.lproj/Main.storyboard` 默认携带 `customClass="FlutterViewController"`。** 任何一次从上游 merge / rebase / 重新生成 iOS scaffolding（包括但不限于：`flutter create .`、Xcode "Migrate to UIScene Lifecycle"、删除重建 `ios/` 目录）都会把这一行**写回去**，再次复活本崩溃。

### 同步上游时必须复查的红线

1. **每次 merge 上游 main 后**，立刻 `git diff` 检查 `ios/Runner/Base.lproj/Main.storyboard`：
   - 若 root `<viewController>` 中又出现 `customClass="FlutterViewController"`，**必须删除该属性**。
2. **每次 `flutter upgrade` 或 Flutter SDK 升级后**，在 iPhone Pro 系列真机（最新 iOS）上跑一次 Release/Profile 安装，确认不再闪退。
3. **每次 Xcode 弹出 "Modernize Scene Support" / "Migrate to UIScene Lifecycle" 自动迁移提示时**，先别同意；同意后必须手动复查 storyboard 是否被重新塞回 `FlutterViewController`。
4. 若上游在 `Info.plist` 中删除了 `UIApplicationSceneManifest`（即回退到非 UIScene 架构），那本修复也需要回退——`Main.storyboard` 可以恢复 `customClass="FlutterViewController"`，否则反而启动不起来。两者**必须配套**。

### 关联文件

| 文件 | 角色 | 同步时要看什么 |
|---|---|---|
| `ios/Runner/Base.lproj/Main.storyboard` | 本修复主战场 | root VC 不能带 `customClass="FlutterViewController"` |
| `ios/Runner/Info.plist` | UIScene 开关 | `UIApplicationSceneManifest.UISceneDelegateClassName` 是否仍为 `FlutterSceneDelegate` |
| `ios/Runner/AppDelegate.swift` | 实现了 `FlutterImplicitEngineDelegate` | 注意 `didInitializeImplicitFlutterEngine` 回调是否还在 |
| `ios/Flutter/Generated.xcconfig` | Flutter 版本来源 | `FLUTTER_ROOT` 指向的 Flutter SDK 版本（< 3.41 不需要本修复） |

## 七、备选方案（未采用，留作参考）

- **方案 B：彻底删除 `Main.storyboard`**——同时移除 `Info.plist` 的 `UISceneStoryboardFile` 键、`Copy Bundle Resources` 中的引用，由 `FlutterSceneDelegate` 全程程序化建窗。改动面更大，但更"干净"。
- **方案 C：自定义 `FlutterViewController` 子类**——覆写 `-initWithCoder:` 内部启动 engine 后再 `[super initWithEngine:nibName:bundle:]`。与"隐式引擎"语义冲突，不推荐。

## 八、参考

- 崩溃日志：`docs/crash/Runner-2026-05-25-15144[6-9].ips`
- 升级提交：`e6e11ff fix(ios): use CupertinoPageTransition directly to fix Flutter upgrade build error`
- Flutter 3.41 UIScene 迁移官方说明（搜 `enable-uiscene-migration` / `FlutterSceneDelegate` / `FlutterImplicitEngineDelegate`）
