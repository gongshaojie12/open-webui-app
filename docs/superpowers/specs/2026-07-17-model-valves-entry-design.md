# 设计文档:App 聊天输入框「模型级配置项(Valves)」入口

日期:2026-07-17
分支:dev-0.0.1

## 背景

Open WebUI Web 端:当聊天中选中的模型带有 `has_user_valves`(即该 Function/Pipe
模型定义了 `UserValves`)时,输入框底部工具行会显示一个旋钮(Knobs)按钮,点击后
弹出「配置项(Valves)」弹窗,供用户编辑该模型暴露的自定义参数(如 Enable Google
Search、图片比例、分辨率)。

对应源码(参考 `D:\NLP\open-webui-0.10.2`):
- `src/lib/components/chat/MessageInput.svelte:1797` — 按钮显示条件
  `selectedModelIds.length === 1 && $models.find(m => m.id === selectedModelIds[0])?.has_user_valves`
- 点击后 `selectedValvesType = 'function'; selectedValvesItemId = selectedModelIds[0].split('.')[0]; showValvesModal = true;`
- `src/lib/components/chat/Controls/Valves.svelte` — 弹窗内容,function 分支走
  `/api/v1/functions/id/{id}/valves/user` 与 `.../valves/user/spec`,debounce 自动保存。

App(Flutter,本仓库)现状:
- 数据层:`model.dart` 已解析 `has_user_valves` 到 metadata。
- API 层:已有 `getUserFunctionValves` / `updateUserFunctionValves`;**缺** function 的
  user valves **spec** 接口(仅 tools 有 `getToolValvesSpec` 系列)。
- UI 层:valves 表单组件 `WorkspaceValveForm` 与弹窗 `WorkspaceToolValvesSheet` 已存在,
  但**仅用于「工作区 → 工具编辑器」**;聊天输入框**没有**模型级 valves 入口按钮。

## 目标

在 App 聊天输入框复刻 Web 端的模型级 valves 入口:当选中带 valves 的模型时,底部
工具行显示一个按钮,点开可编辑并保存该模型的用户级 valves。

## 非目标

- 不实现服务器级 valves 编辑(Web 端模型级入口本就只编辑 user valves)。
- 不改动现有工作区的 valves 功能。
- 不做 debounce 自动保存(见「决策」)。

## 决策(已与用户确认)

1. **按钮位置**:输入框底部工具行(仿 Web),与附件/web 搜索/图像生成按钮同排,
   显示为一个旋钮图标按钮。
2. **保存方式**:仅编辑 user valves + 底部「保存」按钮(手动保存),与 App 现有
   `WorkspaceToolValvesSheet` 交互一致;不采用 Web 的 debounce 自动保存。
3. **权限检查**:完全仿 Web,显示条件包含用户权限判断。

## 架构

三层改动,均为增量,不修改现有 API/按钮/普通模型流程。

### 1. API 层 — `lib/core/services/api_service.dart`

新增 1 个方法:

```dart
Future<WorkspaceValveSpec?> getUserFunctionValvesSpec(String functionId) async {
  final response = await _dio.get(
    '/api/v1/functions/id/$functionId/valves/user/spec',
  );
  return response.data == null
      ? null
      : WorkspaceValveSpec.fromJson(response.data as Map<String, dynamic>);
}
```

已存在、复用不改:`getUserFunctionValves`、`updateUserFunctionValves`。

### 2. Provider 层 — `lib/features/workspace/providers/workspace_providers.dart`

新增读写封装(命名与现有 tool valves 封装对齐):
- `userFunctionValvesSpec(String id) → WorkspaceValveSpec?`
- `userFunctionValves(String id) → Map<String, dynamic>`
- `updateUserFunctionValves(String id, Map<String, dynamic> values)`

复用现有 `WorkspaceValveSpec` 模型。

### 3. UI 层

**新弹窗** `lib/features/chat/widgets/model_valves_sheet.dart`:
- 仿 `WorkspaceToolValvesSheet`,但**去掉服务器/用户切换 SegmentedButton**,只编辑
  user valves。
- 复用 `WorkspaceValveForm` 及 `_hydrate`/`_serialize`(array 值的逗号串 ↔ 列表转换)。
- 结构:标题「配置项」+ 关闭按钮 → 表单(加载中/加载失败/正常三态)→ 底部「保存」按钮。
- 入参:`functionId`。

**按钮** `lib/features/chat/widgets/modern_chat_input.dart`:
- 在底部工具行新增旋钮图标按钮(与现有 web 搜索/图像生成按钮同排)。
- 点击打开 `ModelValvesSheet(functionId: <selectedModelId>.split('.').first)`。

### 显示条件(完全仿 Web)

```
选中恰好 1 个模型
&& 该模型 metadata['has_user_valves'] == true
&& (user.role == 'admin' || (permissions['chat']?['valves'] ?? true))
```

不满足则完全不渲染。普通模型输入框零变化。

权限说明:App 的 `getUserPermissions()` 返回后端原始结构
(`{workspace:{}, chat:{}, features:{}}`),因此可直接读 `permissions['chat']['valves']`,
缺失时默认 `true`。

## 数据流

1. 用户选中带 valves 的模型 → 按钮出现。
2. 点按钮 → 打开 `ModelValvesSheet(functionId)`,`functionId = 模型 id.split('.').first`。
3. Sheet 加载:并行拉 `userFunctionValvesSpec` + `userFunctionValves`,`_hydrate`
   (array→逗号串)填入表单。
4. 改值 → 点「保存」→ `_serialize`(逗号串→array)→ `updateUserFunctionValves`
   → 成功 toast 并关闭。

## 错误处理(复用现有模式)

- 加载失败:sheet 内显示错误文案(仿 `WorkspaceToolValvesSheet._loadError`)。
- 保存失败:错误 toast,不关闭,可重试。
- spec 为空:显示空表单/「没有配置项」。
- `functionId` 取不到:按钮随显示条件一并不显示。

## 测试

- 显示条件单测:带/不带 valves、多选模型、无权限 → 按钮显隐。
- `_hydrate`/`_serialize` 的 array 转换复用现有已验证实现。
- 端到端:选中「众小智-AI生图」→ 按钮出现 → 打开显示三项 valves → 改值保存成功。

## 影响面

纯增量:
- 新增 1 个 API 方法。
- 新增 3 个 provider 方法。
- 新增 1 个弹窗文件。
- `modern_chat_input.dart` 加 1 个条件按钮。

不修改任何现有 API、现有按钮逻辑、普通模型聊天流程。唯一可见变化:带 UserValves
的模型,输入框多出一个「配置项」按钮。

## 涉及文件

- `lib/core/services/api_service.dart`(新增方法)
- `lib/features/workspace/providers/workspace_providers.dart`(新增方法)
- `lib/features/chat/widgets/model_valves_sheet.dart`(新文件)
- `lib/features/chat/widgets/modern_chat_input.dart`(新增按钮)
- l10n:如需「配置项」标题等文案,复用已有 `Valves` 相关键或新增。
