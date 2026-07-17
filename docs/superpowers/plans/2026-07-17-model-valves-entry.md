# 模型级配置项(Valves)聊天入口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 App 聊天输入框复刻 Web 端的模型级 Valves 入口——当选中的模型带 `has_user_valves` 时,底部工具行显示一个「配置项」按钮,点开可编辑并保存该模型的用户级 valves。

**Architecture:** 两层纯增量改动:API 层新增 function user-valves 的 spec 接口(读/写方法已存在);UI 层新增一个复用 `WorkspaceValveForm` 的弹窗 `ModelValvesSheet`(直接经 `apiServiceProvider` 调用,与 chat 侧其他代码一致)和一个在 `modern_chat_input.dart` 底部工具行按条件渲染的按钮。不修改任何现有 API/按钮/普通模型流程。

**Tech Stack:** Flutter / Riverpod / Dio;复用现有 `WorkspaceValveSpec`、`WorkspaceValveForm`、`ThemedSheets`、`ConduitButton`。

## Global Constraints

- 包名前缀:`package:conduit/...`(本仓库 pubspec name = `conduit`)。
- 后端 API 基础:Open WebUI v0.10.2,function user valves 端点为
  `/api/v1/functions/id/{id}/valves/user`、`.../valves/user/spec`、`.../valves/user/update`。
- l10n:所有用户可见文案必须走 `AppLocalizations`;新增键需同时加进 `lib/l10n/app_en.arb`
  与 `lib/l10n/app_zh.arb`,并运行 `flutter gen-l10n` 生成。
- 显示条件(完全仿 Web,三者与):选中恰好 1 个模型 && 该模型
  `metadata['has_user_valves'] == true` && `(user.role == 'admin' || (permissions['chat']?['valves'] ?? true))`。
- 保存方式:仅编辑 user valves + 手动「保存」按钮(不做 debounce 自动保存)。
- array 类型 valve 值在加载时 join 为逗号串、保存时 split 回 list(与
  `WorkspaceToolValvesSheet._hydrate/_serialize` 完全一致)。

---

## File Structure

- `lib/core/services/api_service.dart` — 新增 `getUserFunctionValvesSpec`
  (`getUserFunctionValves`/`updateUserFunctionValves` 已存在)。
- `lib/features/chat/widgets/model_valves_sheet.dart` — 新文件,模型级 valves 弹窗;
  直接 `ref.read(apiServiceProvider)` 调用 API(chat 侧惯例)。
- `lib/features/chat/widgets/modern_chat_input.dart` — 底部工具行新增条件按钮。
- `lib/l10n/app_en.arb` / `lib/l10n/app_zh.arb` — 新增文案键。

**注:** 不新增 workspace provider 封装。`workspaceFunctionsProvider` 是
`FutureProvider<List<...>>`(非带方法的 notifier),而 chat 侧统一用
`ref.read(apiServiceProvider)` 直调 `ApiService`,弹窗遵循此惯例。

---

## Task 1: API 层新增 function user-valves spec 接口

**Files:**
- Modify: `lib/core/services/api_service.dart`(在 `getUserFunctionValves` 之后,约 5688 行)

**Interfaces:**
- Consumes: 现有 `WorkspaceValveSpec.fromJson`(`lib/features/workspace/models/workspace_resources.dart:303`);`ApiService._dio`。
- Produces: `Future<WorkspaceValveSpec?> ApiService.getUserFunctionValvesSpec(String functionId)`。

- [ ] **Step 1: 确认 import 已存在**

`WorkspaceValveSpec` 已在 `api_service.dart` 中用于 `getToolValvesSpec`,无需新增 import。
用 Grep 确认:`grep -n "WorkspaceValveSpec" lib/core/services/api_service.dart` 应有多处命中。

- [ ] **Step 2: 新增方法**

在 `getUserFunctionValves` 方法(约 5682-5688 行)之后插入,镜像 `getUserToolValvesSpec`
(5582 行)的实现:

```dart
  Future<WorkspaceValveSpec?> getUserFunctionValvesSpec(
    String functionId,
  ) async {
    _traceApi('Fetching user function valves spec: $functionId');
    final response = await _dio.get(
      '/api/v1/functions/id/$functionId/valves/user/spec',
    );
    return response.data is Map
        ? WorkspaceValveSpec.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          )
        : null;
  }
```

- [ ] **Step 3: 静态分析**

Run: `flutter analyze lib/core/services/api_service.dart`
Expected: No issues found(或仅有与本改动无关的既有告警)。

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/api_service.dart
git commit -m "feat(api): 新增 function user valves spec 接口"
```

---

## Task 2: 新增 l10n 文案键

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

**Interfaces:**
- Produces: `AppLocalizations` 上的 getter `modelValvesTitle`、`modelValvesEmpty`、
  `modelValvesSaved`、`modelValvesSaveFailed`、`modelValvesLoadFailed`、`modelValvesTooltip`。
  (`save`、`close` 已存在,直接复用。)

- [ ] **Step 1: 在 app_en.arb 新增键**

在 `workspaceToolValvesLoadFailed` 键(约 4323 行)之后插入:

```json
  "modelValvesTitle": "Valves",
  "@modelValvesTitle": {"description":"Title of the model (function) valves sheet in chat."},
  "modelValvesTooltip": "Valves",
  "@modelValvesTooltip": {"description":"Tooltip/label for the chat composer valves button."},
  "modelValvesEmpty": "No valves",
  "@modelValvesEmpty": {"description":"Empty state when the model defines no user valves."},
  "modelValvesSaved": "Valves updated",
  "@modelValvesSaved": {"description":"Confirmation that model valves were saved."},
  "modelValvesSaveFailed": "Couldn't update valves.",
  "@modelValvesSaveFailed": {"description":"Error shown when saving model valves fails."},
  "modelValvesLoadFailed": "Couldn't load valves.",
  "@modelValvesLoadFailed": {"description":"Error shown when loading model valves fails."},
```

- [ ] **Step 2: 在 app_zh.arb 新增键(中文文案)**

在 `workspaceToolValvesLoadFailed` 键(约 2359 行)之后插入:

```json
  "modelValvesTitle": "配置项",
  "modelValvesTooltip": "配置项",
  "modelValvesEmpty": "没有配置项",
  "modelValvesSaved": "配置项已更新",
  "modelValvesSaveFailed": "配置项更新失败。",
  "modelValvesLoadFailed": "配置项加载失败。",
```

- [ ] **Step 3: 生成本地化代码**

Run: `flutter gen-l10n`
Expected: 成功生成,`lib/l10n/app_localizations.dart` 出现 `modelValvesTitle` 等 getter。
验证:`grep -n "modelValvesTitle" lib/l10n/app_localizations.dart` 有命中。

- [ ] **Step 4: 静态分析**

Run: `flutter analyze lib/l10n/`
Expected: No issues found。

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations*.dart
git commit -m "feat(l10n): 新增模型级配置项弹窗文案"
```

---

## Task 3: 新增 ModelValvesSheet 弹窗

**Files:**
- Create: `lib/features/chat/widgets/model_valves_sheet.dart`

**Interfaces:**
- Consumes: `apiServiceProvider`(`lib/core/providers/app_providers.dart`,返回
  `ApiService`);Task 1 的 `getUserFunctionValvesSpec` 及现有
  `getUserFunctionValves`/`updateUserFunctionValves`;`WorkspaceValveForm`、
  `WorkspaceValveSpec`、`ThemedSheets.showCustom`、`ConduitModalSheetSurface`、
  `ConduitButton`、`SheetCloseButton`、`AdaptiveSnackBar`;Task 2 的 l10n 键。
- Produces: `ModelValvesSheet.show(BuildContext context, {required String functionId})`。

- [ ] **Step 1: 创建文件**

以 `workspace_tool_valves_sheet.dart` 为蓝本,去掉服务器/用户 SegmentedButton,只保留
user valves。完整内容:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:conduit/core/providers/app_providers.dart';
import 'package:conduit/core/utils/debug_logger.dart';
import 'package:conduit/features/workspace/models/workspace_resources.dart';
import 'package:conduit/features/workspace/widgets/workspace_valve_form.dart';
import 'package:conduit/l10n/app_localizations.dart';
import 'package:conduit/shared/theme/theme_extensions.dart';
import 'package:conduit/shared/widgets/conduit_components.dart';
import 'package:conduit/shared/widgets/conduit_loading.dart';
import 'package:conduit/shared/widgets/themed_sheets.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Bottom sheet that edits a model's (function/pipe) per-user valves in chat.
/// Mirrors Open WebUI's model-level valves modal: user valves only, manual save.
class ModelValvesSheet extends ConsumerStatefulWidget {
  const ModelValvesSheet({super.key, required this.functionId});

  final String functionId;

  static Future<void> show(
    BuildContext context, {
    required String functionId,
  }) {
    return ThemedSheets.showCustom<void>(
      context: context,
      builder: (_) => ModelValvesSheet(functionId: functionId),
    );
  }

  @override
  ConsumerState<ModelValvesSheet> createState() => _ModelValvesSheetState();
}

class _ModelValvesSheetState extends ConsumerState<ModelValvesSheet> {
  bool _loading = true;
  bool _saving = false;
  bool _loadError = false;

  WorkspaceValveSpec? _userSpec;
  Map<String, dynamic> _userValues = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    final api = ref.read(apiServiceProvider);
    try {
      final userSpec = await api.getUserFunctionValvesSpec(widget.functionId);
      final userValues = await api.getUserFunctionValves(widget.functionId);
      if (!mounted) return;
      setState(() {
        _userSpec = userSpec;
        _userValues = _hydrate(userSpec, userValues);
        _loading = false;
      });
    } catch (error, stackTrace) {
      DebugLogger.error(
        'model valves load failed',
        scope: 'chat/valves',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  Map<String, dynamic> _hydrate(
    WorkspaceValveSpec? spec,
    Map<String, dynamic> values,
  ) {
    final result = Map<String, dynamic>.from(values);
    if (spec == null) return result;
    spec.properties.forEach((property, raw) {
      final propSpec = raw is Map ? raw : const {};
      if (propSpec['type'] == 'array') {
        final current = result[property];
        result[property] = current is List ? current.join(', ') : current;
      }
    });
    return result;
  }

  Map<String, dynamic> _serialize(
    WorkspaceValveSpec? spec,
    Map<String, dynamic> values,
  ) {
    final result = Map<String, dynamic>.from(values);
    if (spec == null) return result;
    spec.properties.forEach((property, raw) {
      final propSpec = raw is Map ? raw : const {};
      if (propSpec['type'] == 'array') {
        final current = result[property];
        if (current is String) {
          result[property] = current
              .split(',')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty)
              .toList(growable: false);
        }
      }
    });
    return result;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final api = ref.read(apiServiceProvider);
    setState(() => _saving = true);
    try {
      await api.updateUserFunctionValves(
        widget.functionId,
        _serialize(_userSpec, _userValues),
      );
      if (!mounted) return;
      AdaptiveSnackBar.show(
        context,
        message: l10n.modelValvesSaved,
        type: AdaptiveSnackBarType.success,
      );
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      DebugLogger.error(
        'model valves save failed',
        scope: 'chat/valves',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      AdaptiveSnackBar.show(
        context,
        message: l10n.modelValvesSaveFailed,
        type: AdaptiveSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.conduitTheme;

    return ConduitModalSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.modelValvesTitle, style: theme.headingSmall),
              ),
              SheetCloseButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Center(child: ConduitLoading.inline(context: context)),
            )
          else if (_loadError)
            Padding(
              key: const Key('model-valves-error'),
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Text(
                l10n.modelValvesLoadFailed,
                style: theme.bodySmall?.copyWith(color: theme.error),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: WorkspaceValveForm(
                  key: const ValueKey('model-valve-form'),
                  spec: _userSpec ?? const WorkspaceValveSpec(schema: {}),
                  initialValues: _userValues,
                  enabled: !_saving,
                  onChanged: (values) {
                    _userValues = values;
                  },
                ),
              ),
            ),
          const SizedBox(height: Spacing.md),
          ConduitButton(
            key: const Key('model-valves-save'),
            text: l10n.save,
            isLoading: _saving,
            isFullWidth: true,
            onPressed: (_loading || _loadError || _saving) ? null : _save,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 校正 import 与 widget 参数**

确认 `apiServiceProvider` 来自 `package:conduit/core/providers/app_providers.dart`
(Grep 核对)。若 `WorkspaceValveForm` 的实际参数名(`spec`/`initialValues`/
`enabled`/`onChanged`)与 `workspace_tool_valves_sheet.dart:228-239` 不同,以该文件为准对齐。

- [ ] **Step 3: 静态分析**

Run: `flutter analyze lib/features/chat/widgets/model_valves_sheet.dart`
Expected: No issues found。若报某 widget/参数不存在,回到对应源文件核对真实签名后修正。

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/widgets/model_valves_sheet.dart
git commit -m "feat(chat): 新增模型级配置项弹窗 ModelValvesSheet"
```

---

## Task 4: 输入框底部工具行新增「配置项」按钮

**Files:**
- Modify: `lib/features/chat/widgets/modern_chat_input.dart`

**Interfaces:**
- Consumes: `selectedModelProvider`(返回 `Model?`,已在本文件多处使用,如 1545、1812 行);
  `currentUserProvider`(`lib/core/providers/app_providers.dart`,返回 `User?`,`user.role`);
  `userPermissionsProvider`(返回 `AsyncValue<Map<String, dynamic>>`);Task 3 的
  `ModelValvesSheet.show`;现有 `_buildPillButton`(3112 行)。
- Produces: quickPills 列表中在满足显示条件时追加一个旋钮按钮。

- [ ] **Step 1: 新增显示条件辅助方法**

在 `modern_chat_input.dart` 的 State 类中新增一个纯函数辅助(放在 `_buildPillButton`
附近即可)。它读取 selectedModel、currentUser、permissions 并返回可显示的 functionId
或 null:

```dart
  /// Returns the function id whose user-valves should be editable from the
  /// composer, or null when the model-valves button must not show.
  ///
  /// Mirrors Open WebUI MessageInput.svelte:1797 + permission gate.
  String? _modelValvesFunctionId() {
    final model = ref.read(selectedModelProvider);
    if (model == null) return null;
    final hasUserValves = model.metadata?['has_user_valves'] == true;
    if (!hasUserValves) return null;

    // Permission gate (admin bypass, chat.valves default true).
    final user = ref.read(currentUserProvider).value;
    if (user?.role != 'admin') {
      final perms = ref.read(userPermissionsProvider).value;
      final chat = perms?['chat'];
      final allowed = chat is Map ? (chat['valves'] ?? true) : true;
      if (allowed != true) return null;
    }

    // Web uses selectedModelIds[0].split('.')[0].
    final id = model.id;
    if (id.isEmpty) return null;
    return id.split('.').first;
  }
```

注意:
- 确认 `Model` 上访问 metadata 的方式(本文件其他处或 `model.dart`)。若 metadata 可能为
  null,已用 `?.` 保护。
- 确认 `currentUserProvider` 与 `userPermissionsProvider` 的返回类型:两者均为 Async——
  用 `.value` 取已加载值(未加载时为 null,按"默认允许"降级,与全局约束一致)。
- 若这些 provider 尚未 import 到本文件,补 import
  `package:conduit/core/providers/app_providers.dart`(先 Grep 确认)。

- [ ] **Step 2: 在 quickPills 构建处追加按钮**

在 `quickPills` 的 for 循环结束之后、`final bool showCompactComposer = quickPills.isEmpty;`
(约 2214 行)之前,插入:

```dart
    if (!isHermesComposer) {
      final valvesFunctionId = _modelValvesFunctionId();
      if (valvesFunctionId != null) {
        final l10n = AppLocalizations.of(context)!;
        final IconData icon = Platform.isIOS
            ? CupertinoIcons.slider_horizontal_3
            : Icons.tune;
        quickPills.add(
          _buildPillButton(
            key: const ValueKey('model-valves-pill'),
            icon: icon,
            label: l10n.modelValvesTooltip,
            isActive: false,
            dense: true,
            onTap: widget.enabled && !_isRecording
                ? () => ModelValvesSheet.show(
                      context,
                      functionId: valvesFunctionId,
                    )
                : null,
          ),
        );
      }
    }
```

注意:`_buildPillButton` 当前签名(3112 行)无 `key` 参数。若要传 `key`,先给
`_buildPillButton` 增补一个可选 `Key? key` 参数并透传给最外层 `Semantics`/`GestureDetector`
的父级;若不想改签名,则删掉上面的 `key:` 一行(测试改用 label 文本定位)。二选一,保持一致。

- [ ] **Step 3: 补 import**

确认文件顶部已 import:
`import 'package:conduit/features/chat/widgets/model_valves_sheet.dart';`
以及 `flutter/cupertino.dart`(用到 `CupertinoIcons`,本文件应已 import)。用 Grep 核对后补缺。

- [ ] **Step 4: 静态分析**

Run: `flutter analyze lib/features/chat/widgets/modern_chat_input.dart`
Expected: No issues found。

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/widgets/modern_chat_input.dart
git commit -m "feat(chat): 输入框新增模型级配置项入口按钮"
```

---

## Task 5: 显示条件单元测试

**Files:**
- Create: `test/features/chat/model_valves_visibility_test.dart`

**Interfaces:**
- Consumes: `_modelValvesFunctionId` 的判定逻辑。由于该方法是 State 私有方法,难以直接单测,
  本任务将判定逻辑抽为一个可测的纯顶层函数,再让 Step 1 的方法调用它。

- [ ] **Step 1: 抽出可测纯函数**

在 `modern_chat_input.dart` 文件末尾(类外)新增顶层纯函数,并让 `_modelValvesFunctionId`
改为调用它:

```dart
/// Pure decision for the model-valves composer button. Returns the function id
/// to edit, or null when the button must be hidden. Exposed for testing.
String? resolveModelValvesFunctionId({
  required String? modelId,
  required bool hasUserValves,
  required String? userRole,
  required Map<String, dynamic>? permissions,
}) {
  if (modelId == null || modelId.isEmpty) return null;
  if (!hasUserValves) return null;
  if (userRole != 'admin') {
    final chat = permissions?['chat'];
    final allowed = chat is Map ? (chat['valves'] ?? true) : true;
    if (allowed != true) return null;
  }
  return modelId.split('.').first;
}
```

然后把 `_modelValvesFunctionId()` 改写为:

```dart
  String? _modelValvesFunctionId() {
    final model = ref.read(selectedModelProvider);
    return resolveModelValvesFunctionId(
      modelId: model?.id,
      hasUserValves: model?.metadata?['has_user_valves'] == true,
      userRole: ref.read(currentUserProvider).value?.role,
      permissions: ref.read(userPermissionsProvider).value,
    );
  }
```

- [ ] **Step 2: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/features/chat/widgets/modern_chat_input.dart';

void main() {
  group('resolveModelValvesFunctionId', () {
    test('returns base function id when model has valves and user allowed', () {
      final id = resolveModelValvesFunctionId(
        modelId: 'zhongxiaozhi.pipe-1',
        hasUserValves: true,
        userRole: 'user',
        permissions: {'chat': {'valves': true}},
      );
      expect(id, 'zhongxiaozhi');
    });

    test('null when model has no user valves', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'm.x',
          hasUserValves: false,
          userRole: 'user',
          permissions: {'chat': {'valves': true}},
        ),
        isNull,
      );
    });

    test('null when chat.valves permission is false and not admin', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'm.x',
          hasUserValves: true,
          userRole: 'user',
          permissions: {'chat': {'valves': false}},
        ),
        isNull,
      );
    });

    test('admin bypasses permission gate', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'm.x',
          hasUserValves: true,
          userRole: 'admin',
          permissions: {'chat': {'valves': false}},
        ),
        'm',
      );
    });

    test('defaults to allowed when permissions missing', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'abc',
          hasUserValves: true,
          userRole: 'user',
          permissions: null,
        ),
        'abc',
      );
    });

    test('null when modelId empty', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: '',
          hasUserValves: true,
          userRole: 'admin',
          permissions: null,
        ),
        isNull,
      );
    });
  });
}
```

- [ ] **Step 3: 运行测试,确认先失败(函数未导出前)后通过**

Run: `flutter test test/features/chat/model_valves_visibility_test.dart`
Expected: 在 Step 1 完成后应 PASS(6 个测试全绿)。若 `resolveModelValvesFunctionId`
未被正确导出/命名,先报编译错误——修正后重跑至全绿。

- [ ] **Step 4: 静态分析**

Run: `flutter analyze lib/features/chat/widgets/modern_chat_input.dart test/features/chat/model_valves_visibility_test.dart`
Expected: No issues found。

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/widgets/modern_chat_input.dart test/features/chat/model_valves_visibility_test.dart
git commit -m "test(chat): 模型级配置项按钮显示条件单测"
```

---

## Task 6: 端到端验证与收尾

**Files:**
- 无代码改动(验证任务);如发现缺陷回到对应 Task 修复。

- [ ] **Step 1: 全量静态分析**

Run: `flutter analyze`
Expected: 无新增 issue(允许仓库既有、与本次无关的告警)。

- [ ] **Step 2: 运行相关测试**

Run: `flutter test test/features/chat/`
Expected: 全部通过。

- [ ] **Step 3: 真机/模拟器验证(使用 verify 或 run 技能)**

场景:
1. 选中「众小智-AI生图」(带 valves 的 Pipe 模型)→ 输入框底部出现「配置项」按钮。
2. 点击 → 弹出 sheet,显示三项(Enable Google Search / Aspect Ratio / Resolution)。
3. 改值 → 点「保存」→ 成功 toast,sheet 关闭。
4. 重新打开 sheet → 值已持久化。
5. 切换到普通模型(无 valves)→ 按钮消失。

- [ ] **Step 4: 记录变更(遵循仓库 docs 惯例)**

按仓库 docs 章节记录习惯(参考近期 commit 如 `docs: 记录第23章…`),在对应
docs 文件补一节说明本次「模型级配置项入口」的实现,然后:

```bash
git add docs/
git commit -m "docs: 记录模型级配置项(Valves)聊天入口实现"
```

---

## Self-Review

**Spec coverage:**
- API spec 接口 → Task 1 ✅
- ModelValvesSheet(user valves + 手动保存,array 转换,直调 apiServiceProvider)→ Task 3 ✅
- 底部工具行条件按钮(has_user_valves + 权限 + 单选)→ Task 4 ✅
- 显示条件测试 → Task 5 ✅
- 错误处理(load/save 失败、空 spec)→ Task 3 build 方法三态 ✅
- l10n → Task 2 ✅
- 端到端验证 → Task 6 ✅

**Placeholder scan:** 无 TBD/TODO;每个代码步骤含完整代码。存在数处"用 Grep 确认真实
import/参数名"的核对指令——这是必要的运行时校正点,非占位符。

**Type consistency:** `getUserFunctionValvesSpec`(Task 1)↔ sheet 调用(Task 3)一致;
`resolveModelValvesFunctionId` 签名(Task 5)↔ 调用(Task 4/5)一致;l10n 键
`modelValves*`(Task 2)↔ 使用(Task 3/4)一致。
