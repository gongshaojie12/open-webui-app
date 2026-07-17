# dev-0.0.1 分支改动记录（相对于 main 分支）

> **用途：** 下次从上游合并新版本时，按此文档逐项重新应用定制化改动。
>
> **分支：** `dev-0.0.1` vs `main`
>
> **涉及文件：** 96 个文件，667 行新增，714 行删除

---

## 目录

1. [品牌重命名（Conduit → 众小智AI）](#1-品牌重命名conduit--众小智ai)
2. [应用图标替换](#2-应用图标替换)
3. [新增 AppConfig 集中配置](#3-新增-appconfig-集中配置)
4. [服务器自动配置（免手动输入）](#4-服务器自动配置免手动输入)
5. [认证页面重构（竹云登录）](#5-认证页面重构竹云登录)
6. [SSO WebView 增强（SSL + 竹云 OAuth）](#6-sso-webview-增强ssl--竹云-oauth)
7. [路由改动（跳过服务器连接页）](#7-路由改动跳过服务器连接页)
8. [FocusMedia OAuth Provider 支持](#8-focusmedia-oauth-provider-支持)
9. [Android 构建配置优化](#9-android-构建配置优化)
10. [iOS 配置改动](#10-ios-配置改动)
11. [国际化文本改动](#11-国际化文本改动)
12. [新增文件清单](#12-新增文件清单)
13. [删除文件清单](#13-删除文件清单)
14. [移除个人赞助入口（Profile 页面）](#14-移除个人赞助入口profile-页面)
15. [合并上游 + 移除 CarPlay 语音 entitlement](#15-合并上游--移除-carplay-语音-entitlement)
16. [PPT embed 在 iOS 上的进度条、滑动、下载、留白与顺序修复](#16-ppt-embed-在-ios-上的进度条滑动下载留白与顺序修复)
17. [Bundle ID 与 App Group 前缀改为 focusmedia](#17-bundle-id-与-app-group-前缀改为-focusmedia)
18. [STT 默认按平台区分（Android 用服务端）](#18-stt-默认按平台区分android-用服务端)
19. [升级操作检查清单](#19-升级操作检查清单)

---

## 1. 品牌重命名（Conduit → 众小智AI）

将所有用户可见的 "Conduit" 文本替换为 "众小智AI"。

### 涉及文件及改动位置

| 文件 | 改动内容 |
|------|---------|
| `android/app/src/main/AndroidManifest.xml` | `android:label="Conduit"` → `"众小智AI"`；`android:label="Ask Conduit"` → `"Ask 众小智AI"` |
| `android/app/src/main/res/values/strings.xml` | `app_name`、`widget_name`、`widget_description`、`widget_ask_conduit` 中的 Conduit → 众小智AI |
| `android/app/src/main/res/layout/assistant_overlay.xml` | `android:text="Ask Conduit"` → `"Ask 众小智AI"` |
| `android/app/src/main/kotlin/.../BackgroundStreamingHandler.kt` | 4 处通知标题/描述中 `Conduit` → `众小智AI` |
| `android/app/src/main/kotlin/.../ConduitApplication.kt` | 通知频道描述 `Conduit` → `众小智AI` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName`、`CFBundleName` → `众小智AI`；相机/麦克风/相册/语音识别权限描述中 `Conduit` → `众小智AI` |
| `ios/Runner/*/InfoPlist.strings`（10 个语言文件） | `CFBundleDisplayName = "Conduit"` → `"众小智AI"` |
| `ios/ShareExtension/Info.plist` | `CFBundleDisplayName` → `"Ask 众小智AI"` |
| `lib/core/auth/auth_state_manager.dart` | 错误提示中 `Conduit` → `众小智AI`（第 922 行） |
| `lib/core/services/app_intents_service.dart` | 7 处 Siri/Shortcuts 返回文本中 `Conduit` → `众小智AI` |
| `lib/core/services/callkit_service.dart` | `appName: 'Conduit'` → `'众小智AI'`（第 176 行） |
| `lib/shared/services/brand_service.dart` | `brandName` getter：`'Conduit'` → `'众小智AI'`（第 259 行） |
| `lib/features/chat/services/reviewer_mode_service.dart` | Demo 模式所有预置回复中 `Conduit` → `众小智AI`（约 20 处） |
| `lib/features/chat/voice_call/application/voice_call_controller.dart` | 语音通话 handle：`'Conduit AI'` → `'众小智AI'`（第 172 行） |
| `lib/core/providers/app_providers.dart` | Demo 对话标题和内容中 `Conduit` → `众小智AI`（第 1239、1247 行） |

### 搜索关键词

升级时在整个项目中搜索 `Conduit`（区分大小写），将用户可见的文本替换为 `众小智AI`。注意保留代码中的类名、包名等不应修改的标识符（如 `ConduitApplication`、`ConduitButton`）。

---

## 2. 应用图标替换

用自定义图标 `assets/icons/app_icon.png` 替换原始图标。

### 改动详情

| 操作 | 文件/目录 |
|------|----------|
| **新增** | `assets/icons/app_icon.png`（217KB，新的应用图标源文件） |
| **删除** | `assets/icons/icon.png`（原始图标） |
| **新增** | `android/app/src/main/res/drawable-{hdpi,mdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png`（5 个分辨率的前景图） |
| **替换** | `android/app/src/main/res/mipmap-{hdpi,mdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`（5 个分辨率替换） |
| **修改** | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — 改用 `@color/ic_launcher_background` + `@drawable/ic_launcher_foreground` 并添加 16% inset |
| **修改** | `android/app/src/main/res/values/colors.xml` — 新增 `ic_launcher_background` 颜色值 `#FFFFFF` |
| **新增** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`（全套 iOS 图标，16 个文件） |
| **修改** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` — 引用新图标文件名 |
| **新增** | `web/favicon.png`、`web/icons/Icon-{192,512,maskable-192,maskable-512}.png` |
| **修改** | `ios/Runner.xcodeproj/project.pbxproj` — `ASSETCATALOG_COMPILER_APPICON_NAME` 改为 `AppIcon`；`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` 改为 `AppIcon` |

### pubspec.yaml 图标生成配置

```yaml
# 新增 dev 依赖
flutter_launcher_icons: ^0.14.4

# 新增图标生成配置
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon.png"
  windows:
    generate: true
    image_path: "assets/icons/app_icon.png"
  macos:
    generate: true
    image_path: "assets/icons/app_icon.png"
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
```

### 认证页面图标引用

`lib/features/auth/views/authentication_page.dart` 中 `_buildHeader()` 方法将原来的 `BrandService.createBrandIcon()` 渐变图标替换为直接使用 `Image.asset('assets/icons/app_icon.png')`：

```dart
// 原代码（main）：使用 BrandService 生成渐变品牌图标
Container(
  decoration: BoxDecoration(gradient: ..., border: ...),
  child: BrandService.createBrandIcon(...),
)

// 新代码（dev-0.0.1）：直接使用 app_icon.png
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Image.asset('assets/icons/app_icon.png', width: 72, height: 72),
)
```

---

## 3. 新增 AppConfig 集中配置

**新增文件：** `lib/core/config/app_config.dart`

**当前值（2026-05-26 起，指向生产环境）：**

```dart
class AppConfig {
  AppConfig._();
  static const String serverUrl = 'https://chat.focusmedia.cn';
  static const bool allowSelfSignedCertificates = false;
}
```

**作用：** 将服务器地址和 SSL 配置集中管理，供 `activeServerProvider` 自动配置时使用。升级合并上游时需要保留这两个常量，并按环境调整。

### 历史值与环境切换

| 环境 | `serverUrl` | `allowSelfSignedCertificates` | 启用时间 |
|---|---|---|---|
| 测试 | `https://1.94.62.87` | `true`（IP 直连 + 自签证书） | 初始引入 ~ 2026-05-26 |
| 生产 | `https://chat.focusmedia.cn` | `false`（公网 CA 签证书） | 2026-05-26 起 |

**切回测试环境的方法**：把上述两个常量同时改回测试值即可。`allowSelfSignedCertificates` 必须跟着改 —— 生产环境用 CA 签时**必须保持 `false`**，否则失去对中间人攻击的拦截；测试环境用 IP + 自签时**必须改 `true`**，否则 SSL 握手就直接失败。

---

## 4. 服务器自动配置（免手动输入）+ AppConfig 自动同步

**文件：** `lib/core/providers/app_providers.dart` 中的 `activeServer` provider

包含两块改动：**(A) 首次启动自动创建 default 配置**，**(B) 每次启动自动把 default 配置同步到当前 AppConfig**。

### A. 首次启动自动创建 default 配置

**原代码（main）：** 没有服务器配置时返回 `null`，用户必须手动在服务器连接页输入 URL。

**新代码（dev-0.0.1）：** 存储为空时自动用 `AppConfig.serverUrl` 创建一个 `id='default'` 的配置：

```dart
final defaultConfig = ServerConfig(
  id: 'default',
  name: 'Default Server',
  url: AppConfig.serverUrl,
  isActive: true,
  allowSelfSignedCertificates: AppConfig.allowSelfSignedCertificates,
);
await storage.saveServerConfigs([defaultConfig]);
await storage.setActiveServerId(defaultConfig.id);
ref.invalidate(serverConfigsProvider);
return defaultConfig;
```

### B. 每次启动自动同步 default 配置到 AppConfig

**为什么需要：** A 块只在"首装、存储为空"时生效。一旦 default 配置写入存储，后续修改 `AppConfig.serverUrl` 完全不被读取（`activeServer` 直接返回持久化的旧值）。结果：升级 App 切换环境时，老用户还是连旧服务器。

**做法：** `activeServer` 开头加一段自动同步逻辑，检测持久化的 default 配置和当前 `AppConfig` 是否漂移，漂移就 in-place 更新：

```dart
final defaultIdx = configs.indexWhere((c) => c.id == 'default');
if (defaultIdx != -1) {
  final existing = configs[defaultIdx];
  if (existing.url != AppConfig.serverUrl ||
      existing.allowSelfSignedCertificates !=
          AppConfig.allowSelfSignedCertificates) {
    final updated = existing.copyWith(
      url: AppConfig.serverUrl,
      allowSelfSignedCertificates: AppConfig.allowSelfSignedCertificates,
    );
    configs = [...configs]..[defaultIdx] = updated;
    await storage.saveServerConfigs(configs);
    ref.invalidate(serverConfigsProvider);
  }
}
```

**关键不变量：** 只动 `id == 'default'` 那条（自动生成的）。用户通过 UI 手动加的其它 ServerConfig 一概不动。

**副作用：** 服务器地址变了，旧服务器签的 auth token 在新服务器上无效，用户被踢回登录页（这是预期行为，跨环境不可能共享 session）。

---

## 5. 认证页面重构（竹云登录）

**文件：** `lib/features/auth/views/authentication_page.dart`

这是改动最大的文件（405 行增删）。核心变化：

### 5.1 新增 FocusMedia 认证模式

```dart
enum AuthMode {
  credentials,
  token,
  sso,
  ldap,
  focusmedia, // 新增：FocusMedia IAM（竹云）
}
```

### 5.2 简化认证模式选择器

原代码根据后端配置动态显示 SSO/Credentials/LDAP/Token 四种模式。新代码固定为三种：

```dart
List<AuthMode> get _availableAuthModes {
  final modes = <AuthMode>[];
  if (_hasLoginFormEnabled) modes.add(AuthMode.credentials);
  modes.add(AuthMode.ldap);
  modes.add(AuthMode.focusmedia);
  return modes;
}
```

- **移除**：Token（API Key）模式及其输入表单 `_buildApiKeyForm()`
- **移除**：SSO 按钮区域 `_buildSsoButtons()` 和 SSO 提示 `_buildSsoPrompt()`
- **移除**：`_navigateToSso()` 方法
- **移除**：`_validateJwtToken()` 方法
- **移除**：`_apiKeyController`
- **移除**：`_buildDividerWithText()` 分隔线组件
- **移除**：`_buildServerDomain()` 服务器域名显示
- **移除**：`_buildBackButton()` 返回按钮（不再需要返回服务器连接页）
- **移除**：`BrandService` 和 `webview_cookie_helper` 的 import

### 5.3 新增竹云登录表单和方法

```dart
void _launchFocusMediaLogin() {
  context.push(
    Routes.ssoAuth,
    extra: <String, dynamic>{
      'oauthLoginPath': '/oauth/focusmedia/login',
      'title': '竹云',
    },
  );
}

Widget _buildFocusMediaForm() {
  return Column(
    key: const ValueKey('focusmedia_form'),
    children: [
      const SizedBox(height: Spacing.md),
      ConduitButton(
        text: '竹云登录',
        icon: Icons.language,
        onPressed: _launchFocusMediaLogin,
        isFullWidth: true,
      ),
    ],
  );
}
```

### 5.4 底部按钮隐藏

当选择竹云模式时隐藏底部登录按钮（因为竹云有自己的按钮）：

```dart
if (_authMode != AuthMode.focusmedia)
  Padding(..., child: _buildSignInButton()),
```

### 5.5 Credentials 标签改名

`credentials` 标签从 "Credentials" / "凭据" 改为 "Email" / "邮箱"。

### 5.6 默认认证模式简化

```dart
void _setDefaultAuthMode() {
  if (_hasLoginFormEnabled) {
    _authMode = AuthMode.credentials;
  } else {
    _authMode = AuthMode.ldap;
  }
}
```

移除了原来的 SSO 优先级判断和 Token 回退逻辑。

---

## 6. SSO WebView 增强（SSL + 竹云 OAuth）

**文件：** `lib/features/auth/views/sso_auth_page.dart`

### 6.1 新增构造函数参数

```dart
class SsoAuthPage extends ConsumerStatefulWidget {
  final ServerConfig? serverConfig;
  final String? oauthLoginPath;  // 新增：OAuth 登录路径
  final String? title;           // 新增：自定义标题
  ...
}
```

### 6.2 使用 oauthLoginPath 加载 URL

```dart
// 原代码：固定加载 /auth
await controller.loadRequest(Uri.parse('$_serverUrl/auth'));

// 新代码：支持自定义路径
final loginPath = widget.oauthLoginPath ?? '/auth';
await controller.loadRequest(Uri.parse('$_serverUrl$loginPath'));
```

此改动在 `_initializeWebView()` 和 `_refresh()` 两处都进行了修改。

### 6.3 AppBar 标题支持自定义

```dart
// 原代码
title: FloatingAppBarTitle(text: l10n?.sso ?? 'SSO'),

// 新代码
title: FloatingAppBarTitle(text: widget.title ?? l10n?.sso ?? 'SSO'),
```

### 6.4 新增 SSL 证书错误处理

在 `NavigationDelegate` 中添加 `onSslAuthError` 回调：

```dart
NavigationDelegate(
  ...
  onSslAuthError: _onSslAuthError,  // 新增
)
```

处理方法：

```dart
void _onSslAuthError(SslAuthError error) {
  DebugLogger.auth(
    'SSO WebView SSL certificate error, proceeding to allow OAuth flow',
  );
  error.proceed();
}
```

**作用：** 企业 OAuth/IAM 服务器（如 `iam.fmtest.cn:8443`）通常使用自签名证书，系统 WebView 默认不信任。此回调允许 WebView 接受 SSL 错误，使 OAuth 重定向链正常完成。

---

## 7. 路由改动（跳过服务器连接页）

**文件：** `lib/core/router/app_router.dart`

### 7.1 未配置服务器时的重定向

```dart
// 原代码：无服务器时跳转到服务器连接页
return Routes.serverConnection;

// 新代码：无服务器时直接跳转到认证页（因为服务器会自动配置）
return Routes.authentication;
```

### 7.2 服务器连接页不再使用

```dart
// 原代码：允许停留在服务器连接页
if (location == Routes.serverConnection) {
  return authState == AuthNavigationState.authenticated ? Routes.chat : null;
}

// 新代码：服务器连接页不再使用，重定向到其他页面
if (location == Routes.serverConnection) {
  return authState == AuthNavigationState.authenticated
      ? Routes.chat : Routes.authentication;
}
```

### 7.3 SSO 路由支持 Map extra

```dart
// 原代码：extra 只支持 ServerConfig
final config = state.extra;
return SsoAuthPage(serverConfig: config is ServerConfig ? config : null);

// 新代码：支持 Map<String, dynamic> 传递 oauthLoginPath 和 title
final extra = state.extra;
if (extra is Map<String, dynamic>) {
  return SsoAuthPage(
    serverConfig: extra['serverConfig'] as ServerConfig?,
    oauthLoginPath: extra['oauthLoginPath'] as String?,
    title: extra['title'] as String?,
  );
}
return SsoAuthPage(serverConfig: extra is ServerConfig ? extra : null);
```

### 7.4 导航服务改动

**文件：** `lib/core/services/navigation_service.dart`

三个导航方法的默认目标从 `Routes.serverConnection` 改为 `Routes.authentication`：

```dart
static Future<void> navigateToLogin() => navigateTo(Routes.authentication);
static Future<void> navigateToServerConnection() => navigateTo(Routes.authentication);
static void clearNavigationStack() { router.go(Routes.authentication); }
```

---

## 8. FocusMedia OAuth Provider 支持

**文件：** `lib/core/models/backend_config.dart`

在 `OAuthProviders` 类中新增 `focusmedia` 字段：

```dart
class OAuthProviders {
  final String? focusmedia;  // 新增

  bool get hasAnyProvider => ... || focusmedia != null;  // 新增判断

  List<String> get enabledProviders => [
    ...
    if (focusmedia != null) 'focusmedia',  // 新增
  ];

  String getProviderDisplayName(String key) {
    return switch (key) {
      ...
      'focusmedia' => focusmedia ?? '竹云登录',  // 新增
    };
  }

  factory OAuthProviders.fromJson(Map<String, dynamic>? json) {
    return OAuthProviders(
      ...
      focusmedia: json['focusmedia'] as String?,  // 新增
    );
  }

  Map<String, dynamic> toJson() => {
    ...
    if (focusmedia != null) 'focusmedia': focusmedia,  // 新增
  };
}
```

---

## 9. Android 构建配置优化

### 9.1 签名配置增强

**文件：** `android/app/build.gradle.kts`

```kotlin
// 新增签名版本支持
signingConfigs {
  getByName("release") {
    ...
    enableV1Signing = true   // 新增
    enableV2Signing = true   // 新增
    enableV3Signing = true   // 新增
    enableV4Signing = true   // 新增
  }
}

// release 构建类型：无 keystore 时回退到 debug 签名（而非不签名）
buildTypes {
  getByName("release") {
    signingConfig = if (keystorePropertiesFile.exists()) {
      signingConfigs.getByName("release")
    } else {
      signingConfigs.getByName("debug")  // 新增回退
    }
  }
  getByName("debug") {
    signingConfig = signingConfigs.getByName("debug")  // 取消注释
  }
}
```

### 9.2 Gradle JVM 内存调整

**文件：** `android/gradle.properties`

```properties
# 原代码
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m

# 新代码（降低内存占用，适合开发机器）
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m
```

---

## 10. iOS 配置改动

### 10.1 Info.plist

- `CFBundleDisplayName`: `Conduit` → `众小智AI`
- `CFBundleName`: `conduit` → `众小智AI`
- 4 个权限描述（相机/麦克风/相册/语音）中 `Conduit` → `众小智AI`

### 10.2 InfoPlist.strings（10 个语言）

所有语言的 `CFBundleDisplayName` 从 `Conduit` 改为 `众小智AI`。

涉及语言：de, en, es, fr, it, ko, nl, ru, zh-Hans, zh-Hant

### 10.3 ShareExtension

`CFBundleDisplayName`: `Ask Conduit` → `Ask 众小智AI`

### 10.4 Xcode 项目配置

**文件：** `ios/Runner.xcodeproj/project.pbxproj`

- `ASSETCATALOG_COMPILER_APPICON_NAME`: `"AppIcon-Debug"` → `AppIcon`
- `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`: `YES` → `AppIcon`
- `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`: `AccentColor` → `AppIcon`
- `ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME`: `WidgetBackground` → `AppIcon`

---

## 11. 国际化文本改动

所有 10 个语言文件（`lib/l10n/app_*.arb`）的改动一致，主要为品牌重命名：

| 键名 | 原值 | 新值 |
|------|------|------|
| `appTitle` | `Conduit` | `众小智AI` |
| `supportConduit` | `Support Conduit` | `Support 众小智AI` |
| `supportConduitSubtitle` | `Keep Conduit independent...` | `Keep 众小智AI independent...` |
| `credentials` | `Credentials` / `凭据` | `Email` / `邮箱` |
| `messageHintText` | `Ask Conduit` | `Ask 众小智AI` |
| `aboutAppSubtitle` | `Conduit information...` | `众小智AI information...` |
| `themePaletteConduitLabel` | `Conduit` | `众小智AI` |
| `themePaletteConduitDescription` | `...designed for Conduit` | `...designed for 众小智AI` |
| `aboutConduit` | `About Conduit` | `About 众小智AI` |
| `androidAssistantNewChatOption` | `Open Conduit with a new chat` | `Open 众小智AI with a new chat` |

---

## 12. 新增文件清单

| 文件路径 | 说明 |
|---------|------|
| `lib/core/config/app_config.dart` | 应用配置（服务器 URL、SSL 开关） |
| `assets/icons/app_icon.png` | 新应用图标源文件 |
| `android/app/src/main/res/drawable-*/ic_launcher_foreground.png` | Android 自适应图标前景（5 个分辨率） |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` | iOS 应用图标（16 个尺寸） |
| `web/favicon.png` | Web favicon |
| `web/icons/Icon-{192,512,maskable-192,maskable-512}.png` | Web PWA 图标 |
| `web/index.html` | Web 入口页面 |
| `web/manifest.json` | Web PWA 清单 |
| `test/widget_test.dart` | 基础 Widget 测试 |
| `docs/fix_install_error.md` | 安装错误修复文档 |
| `docs/*.jpg` | 文档配图（4 个） |
| `.claude/settings.local.json` | Claude Code 本地配置 |

---

## 13. 删除文件清单

| 文件路径 | 说明 |
|---------|------|
| `assets/icons/icon.png` | 原始应用图标（已被 `app_icon.png` 替换） |

---

## 14. 移除个人赞助入口（Profile 页面）

### 背景

设置（Profile / You）页面底部存在「支持 众小智 AI」赞助区块，包含 **Buy Me a Coffee** 和 **GitHub 赞助** 两个外链入口（指向上游作者 `cogwheel0` 的个人收款页面）。本次改动将该区块整体移除。

### 改动文件

| 文件路径 | 说明 |
|---------|------|
| `lib/features/profile/views/profile_page.dart` | 移除赞助区块及相关代码 |

### 具体改动

- 页面 body 中移除 `_buildSupportSection(context)` 调用及其上方的间距 `SizedBox`。
- 删除已不再使用的私有方法：`_buildSupportSection`、`_buildSupportOption`、`_openExternalLink`。
- 删除已不再使用的常量：`_githubSponsorsUrl`、`_buyMeACoffeeUrl`。
- 删除已不再使用的 `package:url_launcher/url_launcher_string.dart` 导入。

> 说明：`_buildIconBadge` 仍被其他区块使用，保留未动。相关本地化字符串（`supportConduit`、`buyMeACoffeeTitle`、`githubSponsorsTitle` 等）保留在各 `lib/l10n/app_*.arb` 中，未删除（无害，最小化改动）。

### 验证

- `flutter analyze lib/features/profile/views/profile_page.dart` → **No issues found**。

### 补充：合并上游后赞助入口在原生 sheet 中“复活”，二次移除

合并上游（见第 15 章）后，上游把设置页改为**原生 sheet** 渲染，赞助区块换到了
`lib/features/navigation/widgets/sidebar_user_pill.dart`，导致「支持 众小智 AI」
区块再次出现。已删除其中对应的整个 `NativeSheetSectionConfig`（标题
`supportConduit` + `buy-me-a-coffee` + `github-sponsors` 两项，共 20 行）。

> ⚠️ 升级注意：这是上游设置页的原生 sheet 结构，合并上游时**容易被带回**。
> 若赞助区块再次出现，检查 `sidebar_user_pill.dart` 的 `sections` 中是否又
> 出现 `title: l10n.supportConduit` 的 section，删除即可。

---

## 15. 合并上游 + 移除 CarPlay 语音 entitlement

### 背景

2026-06-10 从上游 `cogwheel0/conduit:main` 合并了 77 个提交（保留全部定制 + 合入上游全部更新）。上游本次引入了 **CarPlay 语音对话** 新功能，附带受限 entitlement，导致使用个人免费苹果账号（Personal Team）编译时签名失败。

### CarPlay 语音功能（来自上游）

让用户在车载 CarPlay 屏幕上用纯语音与 AI 对话，复用 app 既有的语音模块（`chatVoiceModeControllerProvider`）。仅 iOS、需 iOS 26.4+。相关文件：

| 文件 | 作用 |
|------|------|
| `lib/core/services/carplay_service.dart` | Dart 侧 `CarPlayCoordinator`，处理 start/pause/resume/end 及状态同步 |
| `ios/Runner/ConduitCarPlaySceneDelegate.swift` | CarPlay 屏幕界面（`CPVoiceControlTemplate`） |
| `ios/Runner/ConduitCarPlayBridge.swift` | 原生 ↔ Dart 桥接（MethodChannel `conduit/carplay`） |

### 签名错误与修复

**错误信息**：

> Cannot create a iOS App Development provisioning profile for 'com.gongshaojie.zhongxiaozhiAI.debug'. Personal development teams, including 'focusmedia jiang', do not support the CarPlay Voice Based Conversation capability.

**根因**：`ios/Runner/Runner.entitlements` 中的 `com.apple.developer.carplay-voice-based-conversation` 属 Apple 受限能力，免费个人账号无权使用，Xcode 无法生成 provisioning profile。

**修复**（最小改动）：移除该 entitlement 的两行键值。

```diff
  <key>com.apple.security.application-groups</key>
  <array>
      <string>group.com.gongshaojie.zhongxiaozhiAI</string>
  </array>
- <key>com.apple.developer.carplay-voice-based-conversation</key>
- <true/>
```

### 说明

- CarPlay 的代码、`Info.plist` 中的 CarPlay scene 声明、`CarPlay.framework` 引用**均保留**：无 entitlement 时 CarPlay 场景运行时不会被系统激活，对正常 App 无影响。
- 将来若换**付费开发者账号**并向 Apple 申请到 CarPlay 权限，把上述 entitlement 加回 `Runner.entitlements` 即可恢复功能。
- 合并后 `flutter analyze lib` 通过（No issues found）；iOS 原生改动需在 Mac 上 `pod install` + 编译验证。

> 遗留：CarPlay 界面文案仍为英文（"Ask Conduit"、"Conduit is listening" 等，见 `ConduitCarPlaySceneDelegate.swift`），未跟随品牌改为"众小智AI"。因 CarPlay 当前不启用，暂未处理。

---

## 16. PPT embed 在 iOS 上的进度条、滑动、下载、留白与顺序修复

### 背景

open-webui 的 PPT 生成 pipe（`ppt_pipe.py`）通过 `event_emitter` 的 `embeds` 事件向客户端推送一段**自更新的 HTML**（进度条 / 最终的 PPT 查看器），iframe 内部用 JS 计时刷新进度、用 `postMessage({type:"iframe:height"})` 上报高度，查看器底部的「下载 PDF/PPTX」按钮通过 `window.open(url)` 打开 OBS 公网直链。Web 端一切正常；但 iOS App 端出现三个问题：

1. **没有进度条**：消息里只显示「Embedded Preview / 打开预览」卡片，不自动渲染进度条。
2. **点「打开预览」后整页无法上下滑动**：手指在 embed 区域滑动时被 WebView 吃掉。
3. **无法下载 PPT/PDF**：点击查看器的下载按钮无反应。

> 注意：pipe 对 Web 和 iOS 推送的是**同一套 embed**，问题完全在 App 端，与 `ppt_pipe.py` 无关。

### 根因

| 问题 | 根因 |
|------|------|
| 无进度条 | `WebContentEmbed` 默认 `deferUntilExpanded = true` / `initiallyExpanded = false`（省流量策略），App 在 `assistant_message_widget.dart` 创建 embed 时未覆盖，导致本地 HTML embed 也被折叠成「打开预览」卡片。Web 原版会直接渲染 iframe，所以有进度条。 |
| 无法滑动 | `web_content_embed.dart` 给内嵌 `InAppWebView` 用了 `EagerGestureRecognizer`，贪婪抢占**所有**触摸手势（含垂直滑动），外层聊天列表无法滚动。 |
| 无法下载 | 查看器下载按钮执行 `window.open(url, '_blank')`，但 embed 的 `InAppWebView` 未配置多窗口、也未实现 `onCreateWindow`，iOS WKWebView 默认禁止 JS 开新窗口，导致点击无反应。下载链接本身是 OBS 公网直链（无需登录态），交给系统浏览器即可下载。 |

### 改动（仅 App 端，未改 open-webui）

**1. `lib/features/chat/widgets/assistant_message_widget.dart`** — 本地 HTML embed 自动展开

`_buildEmbedsFromArray` 中创建 `WebContentEmbed` 时传 `initiallyExpanded`，并新增辅助方法 `_isRemoteEmbedSource`：

```dart
child: WebContentEmbed(
  source: source,
  // 本地 HTML embed（如 PPT 进度条/查看器）自动展开，
  // 远程 URL 仍保留“打开预览”手动加载以节省流量。
  initiallyExpanded: !_isRemoteEmbedSource(source),
),
```

```dart
bool _isRemoteEmbedSource(String source) {
  final s = source.trimLeft();
  return s.startsWith('http://') ||
      s.startsWith('https://') ||
      s.startsWith('//');
}
```

**2. `lib/shared/widgets/web_content_embed.dart`** — 手势识别器只抢水平方向

```dart
// EagerGestureRecognizer → HorizontalDragGestureRecognizer
final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(),
      ),
    };
```

**3. `lib/shared/widgets/web_content_embed.dart`** — 支持 embed 内下载（改用 shouldOverrideUrlLoading）

新增 `import 'package:url_launcher/url_launcher.dart';`。**最初用 `onCreateWindow` 拦截 `window.open` 并 `return false`，但会导致下载跳转返回 App 后 embed WebView 被销毁变白**（见下方“二次修复”）。最终方案改用 `shouldOverrideUrlLoading` 拦截**用户手势触发的**外部 http/https 跳转，交给系统浏览器，`onCreateWindow` 仅作兜底：

```dart
initialSettings: InAppWebViewSettings(
  javaScriptEnabled: true,
  transparentBackground: true,
  supportMultipleWindows: true,
  javaScriptCanOpenWindowsAutomatically: true,
  useShouldOverrideUrlLoading: true,
),
shouldOverrideUrlLoading: (controller, navigationAction) async {
  final uri = navigationAction.request.url;
  if (uri == null) return NavigationActionPolicy.ALLOW;
  final isUserGesture = navigationAction.hasGesture ?? false;
  final scheme = uri.scheme.toLowerCase();
  final isExternal = scheme == 'http' || scheme == 'https';
  if (isUserGesture && isExternal) {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
    return NavigationActionPolicy.CANCEL; // 不在 embed 内导航，WebView 不被销毁
  }
  return NavigationActionPolicy.ALLOW; // 首次 loadData/loadUrl 放行
},
```

> 关键：用 `hasGesture` 区分“首次加载自身”与“用户点击下载”——只拦后者，避免误杀 embed 自身加载。

### 二次修复（动态测高方案，已被三次修复替代）

> ⚠️ 此方案实测**适得其反**：监听图片 load + MutationObserver 测 `scrollHeight`
> 把外层越撑越高（"空白高度还变大了"），图片仍不显示。已被下方"三次修复"取代。
> 保留此段仅作演进记录。

二次修复曾尝试：`_injectHeightReporter` 监听 `iframe:height` postMessage + `<img>`
load 动态调高、`_embedMaxHeight` 900→2000、`onCreateWindow` 改 `shouldOverrideUrlLoading`、
调整 embed 渲染顺序到正文之后。其中**渲染顺序**与**下载拦截方向**保留，**动态测高被废弃**。

### 三次修复（最终方案：固定视口 + 内部滚动 + 重写 window.open）

针对 docs 10/11/8 仍存在的"空白更大、图片不显示、下载返回白屏"，改用固定高度方案：

| 现象 | 根因 | 修复 |
|------|------|------|
| 进度条/查看器**大片空白且越来越大** | PPT 的 embed HTML 是**整页文档**（flex + `min-height` 满屏布局）。动态测 `scrollHeight` 会随图片加载、flex 累加被撑到很大 → 外层 SizedBox 越撑越高。 | `web_content_embed.dart` 新增 `useFixedViewport` 参数：固定视口模式高度 = 屏高 60%（夹在 320~640px），**不再测高**（跳过测高脚本/handler/定时测高），内容在 WebView 内部滚动。 |
| 生成完成后**图片不显示**（裂图） | 同上：高度被 Flutter 写死时 flex 容器塌缩，`.viewer img{max-height:100%}` 算不出有效高度。 | 固定视口给了确定高度，flex 布局正常 → 图片按 `object-fit:contain` 显示。`_injectFixedViewportScroll` 注入 CSS 让文档可垂直滚动（PPT 多页内部上下滑）。 |
| 下载跳转**返回 App 白屏** | 下载按钮走 `window.open`/`window.parent.open`（新窗口机制）；`supportMultipleWindows: true` + `onCreateWindow` 返回 false 在 iOS 会让当前 WebView 变白。 | 关闭多窗口（`supportMultipleWindows: false`）、移除 `onCreateWindow`；新增 `_injectExternalOpenBridge` 注入 JS 把 `window.open`/`window.parent.open` 重写为调用 Flutter `conduitOpenExternal` handler，由系统浏览器打开，**完全不触发 WebView 新窗口/导航**。`shouldOverrideUrlLoading` 仅兜底拦 `<a>` 直链。 |
| 进度条位置：iOS 在顶部、Web 在底部 | embed 渲染在正文之前。 | （二次修复保留）调整渲染顺序：正文(大纲)在上、embed 移到正文之后。 |

**手势**：固定视口模式用 `EagerGestureRecognizer`（垂直手势给 WebView 做内部滚动）；
普通模式仍用 `HorizontalDragGestureRecognizer`。

### 效果与权衡

- ✅ PPT 进度条/查看器固定高度（屏高 60%），无大片空白，空白不再变大。
- ✅ 查看器图片正常显示（固定高度让 flex 布局生效）。
- ✅ PPT 多页时在**组件内部上下滚动**查看；整体高度可控。
- ✅ 进度条/查看器位于大纲正文**下方**，与 Web 端一致。
- ✅ 点击「下载 PDF/PPTX」→ 系统浏览器打开 OBS 直链下载，返回 App **不白屏**。
- ✅ 远程网页 embed 不受影响（仍走普通模式 + 「打开预览」省流量）。
- ⚠️ 固定视口模式下，在 embed 区域上下滑 = 滚动 PPT 内部；要滚动外层聊天列表需在 embed **外**的区域滑动。

### ⚠️ 升级注意

合并上游时，以下均为本项目定制，**容易被上游覆盖回默认值，需检查**：

- `assistant_message_widget.dart`：
  - `WebContentEmbed(... initiallyExpanded: !isRemote, useFixedViewport: !isRemote)` —— 上游默认 `WebContentEmbed(source: source)`，会退回「打开预览」+ 动态测高留白。
  - embed 渲染顺序在正文**之后** —— 上游默认在正文之前，会让进度条回到顶部。
- `web_content_embed.dart`：
  - `useFixedViewport` 参数及其全部分支（固定高度、`_injectFixedViewportScroll`、跳过测高、`EagerGestureRecognizer`）—— 上游无，缺失会回到"动态测高撑出大片空白"。
  - `supportMultipleWindows: false` + `_injectExternalOpenBridge`（重写 window.open）—— 上游默认开多窗口 + `onCreateWindow`，会导致下载返回白屏。
  - 普通模式 `_gestureRecognizers` 用 `HorizontalDragGestureRecognizer` —— 上游默认 `EagerGestureRecognizer()`。

---

## 17. Bundle ID 与 App Group 前缀改为 focusmedia

### 背景

iOS Bundle ID 与 App Group 前缀原为 `com.gongshaojie.zhongxiaozhiAI`，统一改为
`com.focusmedia.zhongxiaozhiAI`。此前曾在 Xcode 里手动改过，但未写入仓库，每次
`git pull` 后 `project.pbxproj` 被覆盖又退回 `gongshaojie`。本次正式写入仓库。

### 改动文件

| 文件 | 改动 |
|------|------|
| `ios/Runner.xcodeproj/project.pbxproj` | 全部 target 的 `PRODUCT_BUNDLE_IDENTIFIER` 与 `APP_GROUP_ID` 前缀 |
| `ios/Runner/Runner.entitlements` | App Group |
| `ios/ShareExtension/ShareExtension.entitlements` | App Group |
| `ios/ConduitWidgetExtension.entitlements` | App Group |

仅字面替换 `gongshaojie` → `focusmedia`（共 24 处），未改 App Group 结构。

- 新 Bundle ID：`com.focusmedia.zhongxiaozhiAI`（及 `.debug`/`.ShareExtension`/`.ConduitWidget` 等变体）
- 新 App Group：`group.com.focusmedia.zhongxiaozhiAI`

> 遗留（未处理）：`ConduitWidget.entitlements` 用 `$(APP_GROUP_ID)` 变量，部分
> 配置解析为带 `.x2662v5dt2.debug` 后缀，与其他 target 的不带后缀值不一致。这是
> 历史遗留，本次保持原样未动。

> ⚠️ 免费个人账号（Personal Team）**不支持 App Group**，真机签名仍会报
> “Application Group ... is not available”。如需免费账号真机调试，需移除 App Group
> 或改用付费账号 / 模拟器。

---

## 18. STT 默认按平台区分（Android 用服务端）

### 背景

Android 语音转文字报错 `SpeechRecognitionError msg: error_client, permanent: true`
（见 docs/16.jpg），语音通话中断。iOS 同功能正常。

### 根因

- 默认 `sttPreference = SttPreference.deviceOnly`（仅用设备本地识别）。
- Android 本地识别引擎（系统 `SpeechRecognizer`）在很多设备上缺失/不稳定，会抛
  `error_client`；且 `voice_input_service.dart` 的 `_handleSttError` 未将其归入可
  恢复错误，直接判为致命 → 抛异常中断。
- `deviceOnly` 模式**不会回退服务端**，本地一失败即报错。
- iOS 的 Speech 框架可靠，所以 iOS 走本地识别一切正常。

### 改动文件

| 文件 | 改动 |
|------|------|
| `lib/core/services/settings_service.dart` | STT 默认偏好改为按平台决定 |

### 具体改动

- 新增平台感知 getter：

```dart
// Android→serverOnly（后端转写不依赖设备引擎，稳定）；
// iOS（及其他）→deviceOnly（本地识别可靠，行为不变）。
static SttPreference get _defaultSttPreference =>
    Platform.isAndroid ? SttPreference.serverOnly : SttPreference.deviceOnly;
```

- `_parseSttPreference` 首次启动（无存储值）兜底返回 `_defaultSttPreference`。
- `resetToDefaults()` 重置时也按平台设 STT 偏好（避免 Android 重置后退回本地）。

### 效果与影响

- ✅ **Android**：默认走服务端 STT，避开 `error_client`，语音转文字稳定可用（前提：后端已配置 STT）。
- ✅ **iOS**：默认仍 `deviceOnly`，**行为完全不变**，不受影响。
- 仅影响**未手动设置过 STT 偏好**的用户；已设置的保持自己的选择。
- ⚠️ 取舍：Android 依赖后端 STT，后端 STT 异常/网络差时语音会失败（`serverOnly`
  无本地回退）。如需"本地↔服务端"双向回退的混合策略，需扩展 `SttPreference`
  枚举（目前仅 `deviceOnly`/`serverOnly` 两档），属更大改动，暂未做。

### ⚠️ 升级注意

- `settings_service.dart` 中 `_defaultSttPreference` 平台感知默认 + `_parseSttPreference`
  / `resetToDefaults` 的调用 —— 上游默认写死 `deviceOnly`，合并时若被覆盖，Android
  会再次回到 `error_client` 报错。

---

## 19. 未登记的既有定制（补录）

以下两处定制此前一直在 dev-0.0.1 上，但漏登记，本次补录（合并 3.4.2 时确认存活）：

### 19.1 API 流式请求超时修复

**文件：** `lib/core/services/api_service.dart`

流式聊天请求设 `receiveTimeout: Duration.zero`（不限接收超时），修复 iOS 上长回复
被 30s 默认超时提前中断的问题。

### 19.2 语音通话 CallKit 显示名品牌

**文件：** `lib/features/chat/voice_mode/chat_voice_mode_controller.dart`

CallKit 来电显示 `handle: '众小智AI'`（原上游 `'Conduit AI'`）。属品牌改名，
归到第 1 章品牌清单管理。

> ⚠️ 升级注意：这两处上游都可能改动其所在文件，合并后 grep 确认：
> `grep -n "receiveTimeout: Duration.zero" lib/core/services/api_service.dart`
> `grep -n "handle: '众小智AI'" lib/features/chat/voice_mode/chat_voice_mode_controller.dart`

---

## 20. 2026-07-07 合并上游 3.4.2（118 个提交）

### 背景

从上游 `cogwheel0/conduit:main` 合并了 **118 个提交**（v3.3.1 → v3.4.2）。上游本次
包含重大重构：**持久化层 Hive→Drift 迁移**、**原生语音管线**（native voice pipeline）、
**应用内通知层**、**Notes 富文本编辑（Fleather）**、**Open WebUI 0.10 兼容 + 版本门禁**、
新增 **捷克语(cs) / 日语(ja) / 斯洛伐克语(sk)** 已在更早版本引入。

### 合并方式

先审查后执行：预演合并（`git merge-tree`）→ 逐文件审查两侧差异 → 确认保留策略 →
执行合并。合并前打 tag `pre-merge-3.4.2` 作为回退点。

### 冲突文件（13 个）及处理

| 文件 | 冲突性质 | 处理 |
|------|---------|------|
| `pubspec.yaml` | dev_dependencies 相邻行 | 版本号/依赖取上游，保留 dev 的 `flutter_launcher_icons` |
| `ios/Runner/Info.plist` | dev 键顺序调整 + 上游新增键 | 保留 dev 品牌+顺序，合入上游 `NSPersonalVoiceUsageDescription`（品牌改众小智AI）|
| `lib/core/auth/auth_state_manager.dart` | 上游重构整块 + dev 一处品牌词 | 全取上游重构，重贴品牌词 `please clear 众小智AI credentials` |
| 9 个 `lib/l10n/app_*.arb` | 假冲突（品牌行 vs 新增 key 相邻） | 保留 dev 品牌，合入上游新增 key（serverIncompatible*/chatQueued*）|
| `lib/shared/widgets/web_content_embed.dart` | **架构冲突**（见下方 20.1）| 方案 B 分流 |

### 20.1 web_content_embed.dart 的架构级融合（重点）

**冲突本质：** 上游把本地 HTML embed 内容搬进了 **sandbox iframe**
（`sandbox="allow-scripts allow-forms"`，无 `allow-same-origin`），而 dev 的三个注入
脚本（`_injectExternalOpenBridge` 重写 window.open、`_injectFixedViewportScroll`、
以及原 `_injectHeightReporter`）都作用在**外层顶层文档**——在上游 iframe 结构下
**全部失效**，会导致 PPT 的下载白屏 / 图片留白 / 多页滚动三个 bug 复现。

**采用方案 B（按 `useFixedViewport` 分流）**，而非把 dev 逻辑改造进 srcdoc：

- `_wrapHtmlDocument` 新增 `useSandbox` 参数。
- **PPT/固定视口 embed**（`useFixedViewport == true` → `useSandbox == false`）：
  走 **dev 原来的顶层文档直插**结构，dev 的注入脚本直接作用到 PPT 内容本身 →
  三个修复完整保留、行为不变。
- **其他本地 embed**（`useSandbox == true`）：走**上游 sandbox iframe**，保留安全
  隔离 + 上游 `conduit-embed-height` postMessage 测高。
- `onLoadStop` 融合：`_injectArguments` 在「远程 or 固定视口」时顶层注入（本地
  sandbox 的 args 由上游 srcdoc bootstrap 注入）；`_injectExternalOpenBridge`
  仍全模式注入；固定视口走 `_injectFixedViewportScroll`，否则走上游 `_scheduleHeightUpdates`。
- **删除** `_injectHeightReporter`（其外层测高职责在两条路径下都已被取代：固定视口
  不测高、sandbox 用上游 srcdoc ResizeObserver）。
- 保留 dev 的 `shouldOverrideUrlLoading`（顶层外链兜底拦截）、`supportMultipleWindows: false`、
  手势识别器 getter、`effectiveHeight` 固定视口高度、`_embedMaxHeight = 2000`。

> ⚠️ 升级注意：下次上游若再改 `_wrapHtmlDocument` / sandbox 结构，需重新确认
> `useSandbox` 分流是否成立。核心不变量：**PPT 走非 sandbox 顶层直插**，否则 dev
> 注入脚本失效。合并后必须真机回归 PPT：进度条、图片显示、多页内部滚动、下载不白屏。

### 20.2 品牌漏网补改（上游新增的旧品牌文本）

上游新增的用户可见文本仍含 "Conduit"，非冲突（静默采纳），已手动补改为众小智AI：

- 全部语言的 `chatQueuedPendingMessage`
- `appInformation`（原仅 en 需改）

### 20.3 cs / ja / sk 三语言品牌补齐

这三个语言此前从未做过品牌改名（第 1、11 章只覆盖 10 个语言）。本次一并把用户可见
的 Conduit（含词形 Conduitu/Conduite）改为众小智AI，与其他语言保持一致。
**注意：** 只改 value，`supportConduit`/`aboutConduit`/`themePaletteConduit*` 等
**key 名保持英文不动**（改 key 名会破坏本地化查找）。

### 20.4 上游代码生成（Drift/freezed 升级）

上游升级 freezed / json_serializable / 引入 drift，旧的 `.g.dart` / `.freezed.dart`
过时，合并后必须重新生成：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

未跑 build_runner 前 `flutter analyze` 会报大量 `.g.dart` 错误（非手写代码问题）。

---

## 22. 2026-07-13 合并上游 3.4.3（12 个提交）

### 背景

从上游 `cogwheel0/conduit:main` 合并了 **12 个提交**（v3.4.2 → v3.4.3）。上游本次
两大新功能：**Hermes Agent 后端 + Hermes-only 模式**（`#521`）、**原生 Workspace +
统一设置导航**（`#566`）；另有多附件崩溃修复、STT 回归修复、phase-aware 流式渲染
优化，以及把「新版 Open WebUI 服务器**阻塞**」改为**非阻塞告警**（`#564`）。
共 255 个文件变更（含大量 Hermes/Workspace 测试）。

### 合并方式

先 `git merge-tree` 预演定位冲突 → 打回退 tag `pre-merge-3.4.3` → 执行合并 →
逐个解决冲突 → `build_runner` 重新生成 → `flutter analyze lib` 验证。

### 冲突文件（4 个）及处理

| 文件 | 冲突性质 | 处理 |
|------|---------|------|
| `lib/core/router/app_router.dart` | dev 跳过 onboarding + 上游用非阻塞告警替换旧版本门禁 | 保留 dev `return Routes.authentication`；**移除**旧 `serverIncompatible` 阻塞门禁块（跟随上游，改用 `ServerVersionWarningShell`），连带删掉唯一调用点的 `_isConnectFlowToDifferentServer`（上游已删其定义）|
| `lib/core/providers/app_providers.dart` | import 相邻行（上游新增 `attachment_upload_queue` 与 dev 的 `app_config` 重叠）| 去掉重复 import，保留 `app_config.dart`；自动配置逻辑（第4章 A+B）完整存活 |
| `lib/features/profile/views/profile_page.dart` | **架构冲突**：上游重构为分类设置布局（`#566`）| 采纳上游 `_buildSettingsCategory` 新结构，保留 dev 移除赞助入口（不调用 `_buildDonationSection`，删除其三个方法）|
| `lib/features/navigation/widgets/sidebar_user_pill.dart` | **架构冲突**：上游重构 native sheet 菜单 | 采纳上游新菜单（voice/notifications/aiMemory/hermes/workspace 项）；赞助入口经上游新 `supportItems` 参数**复活**，按第14章删除 `supportTitle`/`supportSubtitle`/`supportItems` 三个参数 |

> ⚠️ **重点重复项**：第14章「赞助入口易被带回」再次应验——这次上游把赞助搬到了
> `NativeSheetConfig` 的 `supportItems` 参数（不再是 `NativeSheetSectionConfig`）。
> 下次合并若赞助又出现，检查 `sidebar_user_pill.dart` 是否又传了 `supportItems:`。

### 22.1 旧版本门禁 `serverIncompatible` 跟随上游移除（非 dev 定制）

`serverIncompatibleProvider` / `Routes.serverIncompatible` 是 **3.4.2 从上游继承**
的代码（非 dev 定制）。上游 `#564` "Warn instead of blocking newer Open WebUI
servers" 把**阻塞式门禁**（跳转独立 `serverIncompatible` 页）重构为**非阻塞告警**
（`ServerVersionWarningShell` 包裹式横幅）。合并时：

- app_router.dart 中的**阻塞跳转逻辑**跟随上游移除；
- `serverIncompatibleProvider` 本身**保留**（上游新 `server_version_warning_shell.dart`
  仍在用它判断"服务器比 App 新"）。

### 22.2 品牌漏网补改

上游新增 onboarding 欢迎语 `backendChooserWelcome: "Welcome to Conduit"`（13 语言），
已改为 `"Welcome to 众小智AI"`。dev 虽跳过 backendChooser 页，仍统一品牌。

### 22.3 定制存活核验（全部通过）

`flutter pub get` + `dart run build_runner build --delete-conflicting-outputs`
（1141 outputs）+ `flutter analyze lib` → **No issues found!**

grep 逐项确认：第3章 AppConfig、第4章自动配置、第5章竹云认证、第6章 SSO SSL
（现为 `_onReceivedServerTrustAuthRequest`）、第7章路由、第8章 FocusMedia OAuth、
第16/20章 PPT embed（`useFixedViewport`/`useSandbox`/注入脚本）、第18章 STT
平台默认、第19章 API 超时 + CallKit 品牌 —— **全部存活**。

> 回退点：`git reset --hard pre-merge-3.4.3` 可回到合并前的 dev-0.0.1。

---

## 23. 侧边栏“孤儿转圈”下拉刷新兜底修复

### 背景（现象）

进入 App 点开左侧抽屉后，某个**早已置顶、根本没在生成**的对话（如“如何申请
苹果开发者”）旁边出现**一直转圈、永不停止**的加载指示。冷启动时不转，**下拉刷新
后开始转且再不消失**；同一对话在**网页端完全正常、不转圈**。杀进程重启只能临时
缓解，下拉后复现。

> 排查中另一现象“置顶数量与网页不一致”经确认为**冷启动增量同步的正常过程**
> （本地边拉边显示，几秒内自动追平），**非 bug**，未做改动。

### 根因（已用 git 逐字节比对确认：非合并引入）

侧边栏转圈来自 `ConversationTileContent` 的 `isGenerating`
（`conversation_tile.dart:131`），其数据源是 `activeChatIdsProvider` 这个集合
（`chats_drawer.dart:1546`）。该集合有**两个数据源**：

| 数据源 | 特性 |
|---|---|
| A. 权威批量查询 `checkActiveChats`（POST `/api/v1/tasks/active/chats`）| 与网页端一致、准确。冷启动 / socket 重连时调用 `_refresh()` → `setAll()` 覆盖 |
| B. socket 事件 `chat:active{true/false}`（全局 handler）| `{true}` 点亮、配对的 `{false}` 熄灭 |

**缺陷**：上游机制假设 `{true}` 之后必定收到配对的 `{false}`。在本部署环境下
（反代 / Redis 任务状态 / 网络链路等因素）配对的 `{false}` 事件会**丢失**，于是
`activeChatIds` 里留下一个**孤儿状态** → 圈永久转。而上游**只**在冷启动和 socket
重连时用权威接口 A 纠正，**手动下拉刷新这条路径没有纠正**，用户除了杀进程无解。

> **关键结论**：涉事文件（`chats_drawer.dart` / `conversation_tile.dart` /
> `chat_transport_dispatch.dart` / `pull_sync.dart` / `chats_dao.dart`）与
> `upstream/main` **逐字节一致**，**不是本项目合并引入的 bug**，而是上游机制在
> 本部署环境（socket 事件会丢失）下暴露的健壮性缺口。本修复是**在上游机制之上加
> 一层兜底**，不改上游任何现有逻辑。

### 改动文件（2 处，约 20 行）

| 文件 | 改动 |
|------|------|
| `lib/core/providers/app_providers.dart` | `ActiveChatsSync` 新增公开方法 `reconcileNow()` |
| `lib/features/navigation/widgets/chats_drawer.dart` | 下拉刷新 `_refreshChats()` 末尾调用 `reconcileNow()` |

**A. `ActiveChatsSync.reconcileNow()`**（复用已有的权威查询 `_refresh` + `setAll` 覆盖）：

```dart
/// Manual pull-to-refresh reconciliation: re-derive [activeChatIdsProvider]
/// from the authoritative `checkActiveChats` endpoint ... so a stranded
/// "generating" spinner ... is cleared on the next user refresh.
Future<void> reconcileNow() async {
  final convos = ref.read(conversationsProvider).asData?.value;
  if (convos == null || convos.isEmpty) return;
  await _refresh(convos.map((c) => c.id).toList());
}
```

**B. `_refreshChats()` 末尾**（folders 稳定后）：

```dart
// Reconcile active-chat spinners against the authoritative server state ...
try {
  await ref.read(activeChatsSyncProvider.notifier).reconcileNow();
} catch (_) {}
```

### 为什么安全（不影响其他功能）

- 纯**新增**方法 + 一处调用，不改任何现有分支。
- 复用的 `checkActiveChats` 正是冷启动用的**同一个权威接口**（已确认与网页一致、准确）。
- `setAll` 本就是“权威覆盖”语义（现有冷启动 / 重连都在用）。
- 真正在生成的对话：权威接口会如实返回，依然转圈；socket 事件照常工作。
- 副作用仅限：下拉刷新多一次轻量查询，把误报的孤儿转圈清掉。
- `flutter analyze` 两个文件 → No issues found。

### ⚠️ 升级注意

- 这是**本地增强**，`app_providers.dart` 与 `chats_drawer.dart` 都是上游会改动的
  文件，下次合并可能覆盖。合并后 grep 确认兜底仍在：
  - `grep -n "reconcileNow" lib/core/providers/app_providers.dart lib/features/navigation/widgets/chats_drawer.dart`
- 若上游将来自己补了“下拉刷新纠正 activeChatIds”的逻辑，本兜底可与之合并或移除
  （避免重复查询）。

---

## 24. 思考（reasoning）折叠块被 HTML 双重转义导致不折叠的修复

### 背景（现象）

模型思考完成后，思考内容**没有折叠**，反而把原始标签当纯文本显示出来（见
docs/2.jpg、docs/3.jpg）：

```
<details type="reasoning" done="true" duration="20">
<summary>Thought for 20 seconds</summary>
> ...
```

网页端同一条消息正常折叠成“思考用时 N 秒 ▽”小条（docs/15.png）。

### 根因（已字节级复现确认；非合并引入，上游同款）

App 端折叠解析器 `DetailsBlockSyntax` 只识别**明文** `<details>` 标签。加临时调试框
打印真实 content（docs/3.jpg），确认到达渲染层的内容是**被 HTML 转义**的：

```
&lt;details type=&quot;reasoning&quot; done=&quot;true&quot; ...&gt;
&lt;summary&gt;Thought for 20 seconds&lt;/summary&gt;
&amp;gt; Developing ...
```

- `<details` → `&lt;details`、`"` → `&quot;`、`>` → `&gt;`；body 的 `>` 甚至变成
  `&amp;gt;`（**转义了两次**）。
- 解析器遇到 `&lt;details` 完全不识别 → 整段按纯文本渲染 → 标签裸露、不折叠。

**转义链条**：reasoning 先被正常渲染成明文 `<details>` 存入 content；之后某条路径把
**整条已渲染 content（含明文 `<details>`）** 又整体走了一遍 `_escapeText`
（`semantic_message_builder.dart`，本用于防止模型伪造 `<details>` 冒充思考块），于是
`<details>` 被二次转义成 `&lt;details`。且会**自我累积**：一旦变 `&lt;details`，
`_stripRenderedSemanticDetails` 的明文正则就认不出它、跳过剥离，下次重载再叠加一层
（body 出现 `&amp;gt;` 即铁证）。

> 涉事文件（`semantic_message_builder` / `structured_output_renderer` /
> `conversation_parsing` / `streaming_helper` / `reasoning_parser` /
> `details_block_syntax`）与 `upstream/main` **逐字节一致** —— 是上游机制在本部署
> 环境 / 模型输出格式下暴露的缺陷，**不是本项目合并引入**。

### 修复（渲染时兜底解转义，最小 & 安全）

在所有 markdown 渲染的统一入口 `prepareMarkdownContent` 前，新增一个针对性修复：
把**被转义的语义 details 块**的标签脚手架还原成明文，让折叠解析器能重新接住。

| 文件 | 改动 |
|------|------|
| `lib/shared/widgets/markdown/markdown_preprocessor.dart` | 新增 `repairEscapedSemanticDetails()` |
| `lib/shared/widgets/markdown/markdown_compile_service.dart` | `prepareMarkdownContent` 开头调用它 |
| `test/shared/widgets/markdown/escaped_semantic_details_repair_test.dart` | 新增回归测试（4 例） |

`repairEscapedSemanticDetails` 只处理**带 `type="reasoning|tool_calls|code_interpreter
|openai_builtin_tool"` 的转义 details 标签**：还原 `&lt;details ...&gt;` 开标签、
`&lt;summary&gt;…&lt;/summary&gt;`、`&lt;/details&gt;` 闭标签三处脚手架；**body 文本
不动**（其转义由 details 渲染器自己在解析时处理）。

### 为什么安全（不影响其他功能）

- 纯**新增**一个预处理步骤，不改折叠解析器、不改持久化、不改 `_escapeText` 本身。
- 有严格前置条件：必须是**带语义 type 的转义 details 标签**才处理。普通文本里用户
  粘贴的转义 `&lt;details&gt;`（无 type）**原样不动**（有回归测试覆盖）。
- 对**已经正确的明文** `<details>` 是 **no-op**（有回归测试覆盖）。
- 回归测试 4 例全过 + `flutter analyze` 两个文件 No issues found。

### ⚠️ 升级注意

- `markdown_preprocessor.dart` / `markdown_compile_service.dart` 是上游会改动的文件，
  下次合并后 grep 确认修复仍在：
  - `grep -n "repairEscapedSemanticDetails" lib/shared/widgets/markdown/*.dart`
- 治标不治本：这是**渲染层兜底**。根本的“整条 content 被二次 `_escapeText`”的源头仍在
  上游代码里（本项目未改，避免动持久化管线）。若上游修了源头，本兜底可保留（no-op 无害）
  或移除。历史上已被双重转义并**持久化**的老消息，靠本兜底在**显示时**修正。

---

## 25. 应用界面语言默认简体中文

### 背景（现象）

中文用户一进 App，界面/首屏是英文或跟随系统，「外观 → 应用语言」显示**系统**
（见 docs/4.jpg），要手动切一遍简体中文，体验差。用户在 **OpenWebUI 网页版**设过
简体中文，但登录 App 后并没有同步过来。

### 根因（含一次走错方向的更正）

**先说结论**：App 界面语言默认跟随系统（`AppLocale.build()` 无本地值时返回 `null`），
中文用户就会看到英文/系统语言。

**关键更正**：一开始误以为“网页设的简体中文存在服务器、App 漏读了 `ui.locale`”，
做了“登录后读服务器 `ui.locale` 同步到 App”的方案——但查 open-webui 0.10.2 源码
证实该方案**无效、已撤销**：

- 网页版界面语言用 i18next `LanguageDetector`，存在**浏览器 localStorage**
  （`src/lib/i18n/index.ts`：`caches:['localStorage']`、`lookupLocalStorage:'locale'`），
  `changeLanguage()` 只调 `i18next.changeLanguage`，**不写服务器**。
- 用户设置对象里**根本没有 `ui.locale` 字段**（`Settings` 类型无 locale/i18n 项）。
- 后端 prompt 模板变量只有 `USER_NAME`/`CURRENT_DATE` 等，**无任何语言变量**
  （`backend/open_webui/utils/task.py`）；**模型回复语言与界面语言无关**，由用户
  提问语言 / 模型系统提示词决定。

因此“从服务器同步网页语言”这条路在 OpenWebUI 里**不存在**。App 本地默认简体中文是
唯一可靠做法。

### 改动文件

| 文件 | 改动 |
|------|------|
| `lib/core/providers/app_providers.dart` | `AppLocale.build()` 无本地值时返回 `const Locale('zh')`（原 `null`）|

```dart
// AppLocale.build() 末尾：
// dev-0.0.1 定制：首次启动（用户未在 App 里选过语言）默认简体中文。
return const Locale('zh');
```

### 效果与边界

- ✅ 首次启动界面即简体中文；「应用语言」显示“简体中文”
  （`Locale('zh').toLanguageTag()=='zh'` → `_resolveLanguageLabel` → 简体中文）。
- ✅ 用户仍可在「外观 → 应用语言」改成其它语言或“跟随系统”，选择被持久化、
  优先于此默认（`build()` 先读本地存储）。
- ⚠️ 边界：用户若选“跟随系统”，`setLocale(null)` 不写本地 → 下次启动又回落到 zh
  默认。对中文用户产品可接受；如需“系统”也持久化，需给 storage 增加一个显式哨兵值，
  属更大改动，未做。
- ⚠️ **不影响模型回复语言**（见上，二者无关）。若要模型默认中文，需在服务器端模型的
  系统提示词里加“用中文回答”，非 App 可改。
- `flutter analyze` No issues found。

> **已撤销**：`ServerUserSettings.locale` 字段、`AppLocale.applyServerLocaleIfUnset()`、
> `_loadSettings` 里的 locale 同步块、`_localeAppliedServerId`——均已删除，
> `server_user_settings.dart` 回到与上游逐字节一致。

### ⚠️ 升级注意

- `app_providers.dart` 是上游会改动的文件，合并后 grep 确认默认值仍在：
  - `grep -n "return const Locale('zh')" lib/core/providers/app_providers.dart`

---

## 26. 生图（image-gen pipe）裸 `<details>` 被转义导致思考不折叠

### 背景（现象）

生图模型（OpenWebUI 的 `gemini_image.py` pipe）出图后，思考内容不折叠，`<details>` /
`<summary>思考用时 (Ns)</summary>` 原始标签裸露成纯文本（见 docs/5.jpg）；同一模型
**网页端正常折叠**（docs/17.png）。

### 根因（调试框取真实字节确认；非合并引入）

在渲染入口加临时调试框打印真实 content，得到（docs/5.jpg 复现）：

```
idx=-1  raw="&lt;details&gt;\n&lt;summary&gt;思考用时 (24s)&lt;/summary&gt;\n\n&gt; **Generating...**"
```

`idx=-1` 表示**没有明文 `<details`**——整块被 HTML 转义成了 `&lt;details&gt;`，与第 24 章
**同源**（转义后折叠解析器不认）。但**关键差异**：这个 pipe 发的是**裸 `<details>`
（无 `type` 属性）**（`gemini_image.py:3705`），而第 24 章的修复
`repairEscapedSemanticDetails` 当时**要求带 `type="reasoning|tool_calls|..."` 属性**才
还原，于是漏掉了这个 bare 块。

### 修复（放宽 repair 的识别判据）

把 `repairEscapedSemanticDetails`（`markdown_preprocessor.dart`）的检测判据从
「带语义 `type` 属性」改为「**转义的 `<details>` 块内含转义的 `<summary>`**」——
`<summary>` 是所有可折叠块（reasoning / 生图 / 工具调用）的共同特征。改为**整块匹配**
（`&lt;details…&lt;summary&gt;…&lt;/summary&gt;…&lt;/details&gt;`）后只还原块内的
标签脚手架（`<details>` / `<summary>` / `</details>`），body 仍不动。

| 文件 | 改动 |
|------|------|
| `lib/shared/widgets/markdown/markdown_preprocessor.dart` | `repairEscapedSemanticDetails` 判据放宽为「含转义 `<summary>` 的转义 `<details>` 块」，覆盖 bare（无 type）场景 |
| `test/shared/widgets/markdown/escaped_semantic_details_repair_test.dart` | 新增 bare 生图场景用例（共 5 例） |

### 为什么安全

- 仍只还原**标签脚手架**，body 不动；仅新增一个预处理判据的覆盖面。
- **普通转义文本不误伤**：`&lt;details&gt;hello&lt;/details&gt;`（无 `<summary>`）
  不匹配 → 原样保留（回归测试覆盖）。
- 向后兼容第 24 章：reasoning（带 type）、双重转义 body、明文块 no-op 全部仍通过。
- 5 例回归测试全过 + `flutter analyze` No issues found。

### ⚠️ 升级注意

- 与第 24 章共用 `repairEscapedSemanticDetails`；合并后 grep 确认仍在：
  - `grep -n "repairEscapedSemanticDetails" lib/shared/widgets/markdown/*.dart`
- 同第 24 章：这是**渲染层兜底**，根源「content 被二次转义」仍在上游代码（未改持久化）。

---

## 27. App 聊天输入框补齐「模型级配置项（Valves）」入口

### 背景（现象）

带 `UserValves` 的 Function/Pipe 模型（如「众小智-AI生图」，暴露 Enable Google
Search / 图片比例 / 分辨率三项），**网页端**聊天输入框底部会显示一个旋钮按钮，点开是
「配置项」弹窗（docs/18.png、docs/18-1.png);而 **App** 输入框没有这个入口
（docs/18.jpg），用户无法在对话里调这些参数。

### 根因（非缺陷，是功能未移植）

对照上游 `MessageInput.svelte:1797`，网页端按钮显示条件为
`selectedModelIds.length === 1 && $models.find(...)?.has_user_valves`，点击打开
function 的 user valves（`/api/v1/functions/id/{id}/valves/user` 及 `.../spec`）。
App 侧盘点:

- 数据层已解析 `has_user_valves`（`model.dart`)；
- API 层已有 `getUserFunctionValves` / `updateUserFunctionValves`，**缺** user valves
  的 **spec** 接口；
- valves 表单组件 `WorkspaceValveForm` 已存在，但**仅用于工作区工具编辑器**，聊天输入框
  **没有**模型级入口按钮。

即:数据/API/表单三层都在,唯独缺「聊天里针对当前模型弹出 valves」的入口与弹窗。

### 实现（纯增量，不改现有 API/按钮/普通模型流程）

| 文件 | 改动 |
|------|------|
| `lib/core/services/api_service.dart` | 新增 `getUserFunctionValvesSpec`（`GET /api/v1/functions/id/{id}/valves/user/spec`），镜像 `getUserToolValvesSpec` |
| `lib/l10n/app_en.arb` / `app_zh.arb` | 新增 `modelValves*` 文案键（标题「配置项」等,中英） |
| `lib/features/chat/widgets/model_valves_sheet.dart` | 新建 `ModelValvesSheet`:仅编辑 user valves + 手动「保存」,复用 `WorkspaceValveForm` 及 array 逗号串↔列表转换;直接经 `apiServiceProvider` 调 API |
| `lib/features/chat/widgets/modern_chat_input.dart` | 底部工具行(quickPills)新增条件按钮;抽出可测纯函数 `resolveModelValvesFunctionId`;`_buildPillButton` 加可选 `Key?` 参数 |
| `test/features/chat/model_valves_visibility_test.dart` | 显示条件 6 例单测 |

### 显示条件（完全仿 Web）

```
选中恰好 1 个模型
&& model.metadata['has_user_valves'] == true
&& (user.role == 'admin' || (permissions['chat']?['valves'] ?? true))
```

不满足则完全不渲染——普通模型输入框零变化。

### 为什么安全

- 纯加法:新增 1 个 API 方法、1 个弹窗文件、1 个条件按钮;不改现有 API/按钮逻辑。
- `apiServiceProvider` 实为 `Provider<ApiService?>`(可空),弹窗内加了 null 守卫
  （仿 `conversation_context_menu.dart`),错误走既有 load-error/save-snackbar 路径。
- `flutter analyze`(改动 3 文件)No issues found;显示条件 6 例单测全过。
- 已知与本次无关的既有失败测试(基线 644eef08 即失败):
  `reviewer_mode_service_test.dart`、`chat_voice_mode_controller_test.dart`。

### ⚠️ 升级注意

- 生成的 `app_localizations*.dart` 在本仓库被 gitignore,只提交 arb 源文件;合并/构建前需
  跑 `flutter gen-l10n`。
- `flutter test` 若报 flutter_tester WebSocket 错,需清代理:
  `NO_PROXY=127.0.0.1,localhost` 且清空 `HTTP(S)_PROXY`。
- 合并后 grep 确认定制仍在:
  - `grep -n "getUserFunctionValvesSpec" lib/core/services/api_service.dart`
  - `grep -n "resolveModelValvesFunctionId" lib/features/chat/widgets/modern_chat_input.dart`
- 真机回归:选中带 valves 的模型→按钮出现→改值保存→重开值已持久化;切普通模型→按钮消失。

---

## 21. 升级操作检查清单

从上游合并新版本后，按以下清单逐项检查：

### 配置类

- [ ] `lib/core/config/app_config.dart` 存在且 `serverUrl` 正确
- [ ] `lib/core/providers/app_providers.dart` 中 `activeServer` 自动配置逻辑完整
- [ ] `lib/core/models/backend_config.dart` 中 `OAuthProviders.focusmedia` 字段存在

### 认证流程

- [ ] `lib/features/auth/views/authentication_page.dart` 中 `AuthMode.focusmedia` 枚举值存在
- [ ] `_buildFocusMediaForm()` 和 `_launchFocusMediaLogin()` 方法存在
- [ ] Token/API Key 模式已移除
- [ ] SSO 自动检测逻辑已移除（改为固定三个 tab）
- [ ] 返回按钮和服务器域名显示已移除

### SSO WebView

- [ ] `lib/features/auth/views/sso_auth_page.dart` 中 `oauthLoginPath` 和 `title` 参数存在
- [ ] `NavigationDelegate` 中 `onSslAuthError: _onSslAuthError` 已添加
- [ ] `_onSslAuthError` 方法调用 `error.proceed()` 接受 SSL 错误
- [ ] `_initializeWebView()` 和 `_refresh()` 使用 `widget.oauthLoginPath ?? '/auth'`

### 路由

- [ ] `lib/core/router/app_router.dart` 中无服务器时重定向到 `Routes.authentication`
- [ ] SSO 路由支持 `Map<String, dynamic>` extra（含 oauthLoginPath/title）
- [ ] `lib/core/services/navigation_service.dart` 中导航方法指向 `Routes.authentication`

### 品牌

- [ ] 全局搜索 `Conduit`（区分大小写），用户可见文本已替换为 `众小智AI`
- [ ] `lib/shared/services/brand_service.dart` 中 `brandName` 为 `众小智AI`
- [ ] 所有 `lib/l10n/app_*.arb` 中的品牌文本已更新
- [ ] Android `strings.xml`、`AndroidManifest.xml` 已更新
- [ ] iOS `Info.plist`、`InfoPlist.strings`、`ShareExtension/Info.plist` 已更新

### 图标

- [ ] `assets/icons/app_icon.png` 存在
- [ ] `pubspec.yaml` 中 `flutter_launcher_icons` 配置存在
- [ ] 运行 `flutter pub run flutter_launcher_icons` 重新生成各平台图标

### 构建

- [ ] `android/app/build.gradle.kts` 中签名配置包含 V1-V4 和 debug 回退
- [ ] `android/gradle.properties` 中 JVM 内存参数合适
- [ ] 合并后跑 `flutter pub get` + `dart run build_runner build --delete-conflicting-outputs` 重新生成 `.g.dart`/`.freezed.dart`
- [ ] `flutter analyze lib` 无手写代码错误（`.g.dart` 报错通常是没跑 build_runner）

### Embed（PPT）

- [ ] `web_content_embed.dart` 中 `_wrapHtmlDocument` 的 `useSandbox` 参数存在
- [ ] `useFixedViewport == true` 时走非 sandbox 顶层直插（PPT 注入脚本才生效）
- [ ] `_injectExternalOpenBridge` / `_injectFixedViewportScroll` 保留
- [ ] 真机回归：PPT 进度条、图片显示、多页内部滚动、下载不白屏

### API / 语音（补录定制）

- [ ] `grep -n "receiveTimeout: Duration.zero" lib/core/services/api_service.dart`
- [ ] `grep -n "handle: '众小智AI'" lib/features/chat/voice_mode/chat_voice_mode_controller.dart`

### 品牌（补充）

- [ ] cs / ja / sk 三语言 arb 用户可见 Conduit 已改众小智AI（key 名保持英文）
