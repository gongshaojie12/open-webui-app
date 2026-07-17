import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
      if (api == null) throw Exception('No API service');
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

  /// Joins `array`-typed values into comma strings for editing, matching the
  /// upstream load path.
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

  /// Splits comma strings back into lists for `array`-typed values before
  /// submit, matching the upstream save path.
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
      if (api == null) throw Exception('No API service');
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
