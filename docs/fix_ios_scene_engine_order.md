# iPhone 17 Pro / iOS 26.4 启动闪退：SceneDelegate 中 engine.run() 与 FlutterViewController 顺序错误

## 现象

设备：iPhone 17 Pro，iOS 26.4
Flutter：3.44.0
配置：自定义 `AppDelegate` 持有 `let flutterEngine = FlutterEngine(name: "conduit")`，由 `SceneDelegate` 在 `scene(_:willConnectTo:options:)` 里取出该 engine 并展示。

修复完 `Main.storyboard` 的 `customClass` 之后（见 [fix_ios_launch_crash_uiscene.md](./fix_ios_launch_crash_uiscene.md)），从主屏点图标启动仍然秒退，但崩溃位置变了：

- 第二次崩溃 `docs/Runner-2026-05-26-115452.ips`：`SIGABRT`，栈顶为
  `abort → fml::KillProcess() → fml::LogMessage::~LogMessage() + 556 → -[FlutterViewController initWithEngine:nibName:bundle:] + 136 → SceneDelegate.scene + 668`
  → `FML_CHECK(engine)` 触发，engine 在 ObjC ABI 那一侧是 nil。
- 第三次崩溃 `docs/Runner-2026-05-26-134730.ips`（切到 Release 配置后）：`SIGSEGV / KERN_INVALID_ADDRESS at 0x80`，栈顶为
  `pthread_mutex_lock + 12 → Flutter+641964 → Flutter+518132 → Flutter+137820 → Flutter+390468 → SceneDelegate.scene + 264`
  寄存器 `x0 = 0x80`、`x17 = OBJC_CLASS_$_FlutterViewController` → FlutterView/setViewController 路径上对一个 nil 对象偏移 0x80 处的 mutex 加锁。

## 根因（两个）

### 根因 1：Debug 模式下 `FlutterEngine(name:)` 在脱离调试器启动时会返回 nil

Flutter 3.44 的 `FlutterEngine.mm`：

```objc
if (!EnableTracingIfNecessary(_dartProject.settings)) {
  NSLog(@"Cannot create a FlutterEngine instance in debug mode without "
        @"Flutter tooling or Xcode.");
  return nil;
}
```

iOS 14+ 的 Debug 构建必须挂载调试器（ptrace），否则 `EnableTracingIfNecessary` 返回 false → `initWithName:` 直接返回 nil。但 Swift 侧 `FlutterEngine(name:)` 的桥接类型是非 optional，nil 会被透传给下一个 ObjC API，最后撞上 `FML_CHECK(engine)` 触发 abort。

→ **解决**：在真机上从主屏启动只能用 Release 配置（或 Profile / Archive 出 ipa 安装）。Debug 构建必须始终挂 Xcode。

### 根因 2：`FlutterViewController(engine:)` 要求 engine 已经 `run`

`FlutterViewController.initWithEngine:nibName:bundle:` 的实现假设 engine 已经有 shell 在跑：

```objc
- (instancetype)initWithEngine:(FlutterEngine*)engine ... {
  ...
  _engineNeedsLaunch = NO;  // ← 显式标记"不要再 run engine 了"
  [_engine setViewController:self];
  ...
}
```

它接下来构造 FlutterView、调用 `[_engine setViewController:self]`，而后者会拿 engine 的 shell 指针去做事。如果 engine 还没 run，shell 是 nil，访问 nil 上偏移 0x80 的 mutex 字段 → `pthread_mutex_lock(0x80)`。

Flutter 官方在 `FlutterLaunchEngine.m` 里给出了显式 engine 的正确顺序（这是它内部启动 launch engine 用的）：

```objc
_engine = [[FlutterEngine alloc] initWithName:@"io.flutter" ...];
[_engine run];      // ← 必须先 run
// 之后才把 _engine 交给 FlutterViewController
```

我之前误把 `sharedSetupWithProject`（**隐式** engine 路径，VC 内部建 shell）的顺序套到了**显式** engine 路径上，导致 `engine.run()` 被放到了 `FlutterViewController(engine:)` 之后。这正是第三次崩溃的根因。

## 修复

`ios/Runner/AppDelegate.swift` 里 `SceneDelegate.scene(_:willConnectTo:options:)` 调整为下列顺序，**与 `FlutterLaunchEngine.m` 完全一致**：

```swift
let engine = appDelegate.flutterEngine

// 1. 先启动 shell + Dart isolate
engine.run()

// 2. 创建 VC（init 内部会 setViewController:）
let viewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)

// 3. 注册插件（此时 engine 有 shell，且 viewController 已绑定）
GeneratedPluginRegistrant.register(with: engine)
appDelegate.configureMethodChannels(on: engine)
self.registerSceneLifeCycle(with: engine)

// 4. 上屏
window = UIWindow(windowScene: windowScene)
window?.rootViewController = viewController
window?.makeKeyAndVisible()

super.scene(scene, willConnectTo: session, options: connectionOptions)
```

四步顺序背后的不变量：

| 步骤 | 不变量 |
|---|---|
| 1 `engine.run()` | engine 的 shell 必须先建好，否则下一步访问 nil shell |
| 2 `FlutterViewController(engine:)` | VC init 内置 `setViewController:`，让 `engine.viewController` 非 nil |
| 3 `GeneratedPluginRegistrant.register` | 像 `adaptive_platform_ui` 的 `iOS26NativeTabBarManager` 这类插件 register 时会读 engine 的 viewController；engine 没 run 或 VC 没绑都会炸 |
| 4 `makeKeyAndVisible` | 这一步触发 UIKit 调 `loadView` / `viewDidLoad`，此时整条链路必须已经就位 |

## 验证

- Xcode Scheme → Edit Scheme → Run → Build Configuration 设为 **Release**
- `⇧⌘K` Clean → `⌘R` Run 装到 iPhone
- 拔 USB / 杀掉 Xcode → 从主屏点图标 → 正常进入应用

## 如果还崩

按 systematic-debugging 流程，3 次以上反复修同一处仍崩，说明架构本身有问题。下一步应讨论的方向：

1. **改用 Flutter 自带的 launch engine**：删掉 `AppDelegate.flutterEngine` 这个自建 engine，改成在 SceneDelegate 里调 `appDelegate.takeLaunchEngine()` 拿 Flutter 默认创建并已 run 的 engine。这是 Flutter 3.41+ UIScene 默认路径，与上游 diff 最小。
2. **改用隐式 engine 路径**：`FlutterViewController(project: nil, nibName: nil, bundle: nil)` 让 VC 自己建 shell；但 `configureMethodChannels` 需要重写为取 `viewController.engine?.binaryMessenger`，且整个 AppDelegate 上的 `flutterEngine` 字段会失去意义。
