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
14. [升级操作检查清单](#14-升级操作检查清单)

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

```dart
class AppConfig {
  AppConfig._();
  static const String serverUrl = 'https://1.94.62.87';
  static const bool allowSelfSignedCertificates = true;
}
```

**作用：** 将服务器地址和 SSL 配置集中管理，供 `activeServerProvider` 自动配置时使用。升级时需要根据环境修改 `serverUrl`。

---

## 4. 服务器自动配置（免手动输入）

**文件：** `lib/core/providers/app_providers.dart`（第 175-199 行）

### 原代码（main）

```dart
if (activeId == null || configs.isEmpty) return null;
for (final config in configs) {
  if (config.id == activeId) return config;
}
return null;
```

当没有配置服务器时返回 `null`，用户需要手动在服务器连接页输入 URL。

### 新代码（dev-0.0.1）

```dart
if (activeId != null && configs.isNotEmpty) {
  for (final config in configs) {
    if (config.id == activeId) return config;
  }
}

// 自动使用 AppConfig 中的默认服务器
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

当没有已保存的服务器时，自动创建一个使用 `AppConfig.serverUrl` 的默认配置，用户无需手动输入服务器地址。

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

## 14. 升级操作检查清单

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
