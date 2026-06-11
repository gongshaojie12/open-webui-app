import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conduit/l10n/app_localizations.dart';

import '../theme/theme_extensions.dart';
import 'webview_content_height.dart';

const _embedDefaultHeight = 360.0;
const _embedFallbackHeight = 160.0;
const _embedMinHeight = 220.0;
// 提高上限：PPT 查看器（缩略图侧栏 + 大图）和进度条提示可能超过 900px，
// 旧值会把内容裁短导致下方留白/无法完整显示。
const _embedMaxHeight = 2000.0;

class WebContentEmbed extends StatefulWidget {
  const WebContentEmbed({
    super.key,
    required this.source,
    this.argsText = '',
    this.deferUntilExpanded = true,
    this.initiallyExpanded = false,
    this.showChrome = true,
    this.fillAvailableHeight = false,
    this.useFixedViewport = false,
    this.previewTitle,
    this.previewDescription,
    @visibleForTesting this.debugTreatAsSupported,
    @visibleForTesting this.debugSeedControllerForTesting = false,
    @visibleForTesting this.debugOnControllerReset,
  });

  final String source;
  final String argsText;
  final bool deferUntilExpanded;
  final bool initiallyExpanded;
  final bool showChrome;
  final bool fillAvailableHeight;

  /// 固定视口模式：embed 用一个基于屏幕高度的固定高度（约 60% 屏高），内容
  /// 在 WebView 内部垂直滚动，**不再**测量内容高度去撑外层。用于 PPT 进度条/
  /// 查看器这类“整页文档”型 embed——它们带 flex/min-height 满屏布局，动态测高
  /// 会把外层越撑越高、出现大片空白。开启后内部允许垂直滚动（手势交给 WebView）。
  final bool useFixedViewport;
  final String? previewTitle;
  final String? previewDescription;
  @visibleForTesting
  final bool? debugTreatAsSupported;
  @visibleForTesting
  final bool debugSeedControllerForTesting;
  @visibleForTesting
  final VoidCallback? debugOnControllerReset;

  @override
  State<WebContentEmbed> createState() => _WebContentEmbedState();
}

class _WebContentEmbedState extends State<WebContentEmbed> {
  // 手势识别器：
  // - 固定视口模式（PPT 进度条/查看器）：把所有手势交给 WebView，让内容在
  //   组件内部上下滚动（PPT 多页时）。要滚动外层聊天列表，在 embed 外的区域滑动。
  // - 普通模式：只把水平拖动交给 WebView，垂直手势留给外层聊天列表，避免吞掉
  //   整页上下滑动。
  Set<Factory<OneSequenceGestureRecognizer>> get _gestureRecognizers {
    if (widget.useFixedViewport) {
      return <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      };
    }
    return <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(),
      ),
    };
  }

  InAppWebViewController? _controller;
  double _height = _embedDefaultHeight;
  bool _isLoading = true;
  bool _loadScheduled = false;
  bool _retryLoadScheduled = false;
  String? _loadError;
  int _loadRequestId = 0;
  late bool _isExpanded;
  bool _debugHasSeededController = false;
  bool _shouldRenderWebView = false;

  bool get _isRunningInTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }

  bool get _isSupported {
    if (widget.debugTreatAsSupported != null) {
      return widget.debugTreatAsSupported!;
    }
    if (kIsWeb) {
      return false;
    }
    if (_isRunningInTestEnvironment) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  bool get _isRemoteUrl {
    final raw = widget.source.trim();
    return raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('//');
  }

  Uri? get _resolvedRemoteUri {
    if (!_isRemoteUrl) {
      return null;
    }
    return Uri.tryParse(
      widget.source.startsWith('//') ? 'https:${widget.source}' : widget.source,
    );
  }

  bool get _hasController =>
      _controller != null || _debugHasSeededController || _shouldRenderWebView;

  String get _unsupportedMessage {
    if (_isRunningInTestEnvironment) {
      return 'Embedded content preview is unavailable in widget tests.';
    }
    return 'Embedded content is available on supported mobile and macOS builds.';
  }

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded || !widget.deferUntilExpanded;
    if (widget.debugSeedControllerForTesting) {
      _debugHasSeededController = true;
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant WebContentEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.argsText != widget.argsText ||
        oldWidget.deferUntilExpanded != widget.deferUntilExpanded ||
        oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _loadScheduled = false;
      _retryLoadScheduled = false;
      _isExpanded = widget.initiallyExpanded || !widget.deferUntilExpanded;
      _resetControllerState(isLoading: _isExpanded);
      if (_isExpanded) {
        unawaited(_initializeController(reuseCurrentRequestId: true));
      }
    }
  }

  void _resetControllerState({required bool isLoading}) {
    final hadController = _hasController;
    if (mounted) {
      setState(() {
        _loadRequestId += 1;
        _controller = null;
        _debugHasSeededController = false;
        _shouldRenderWebView = false;
        _height = _embedDefaultHeight;
        _isLoading = isLoading;
        _loadError = null;
      });
    } else {
      _loadRequestId += 1;
      _controller = null;
      _debugHasSeededController = false;
      _shouldRenderWebView = false;
      _height = _embedDefaultHeight;
      _isLoading = isLoading;
      _loadError = null;
    }
    if (hadController) {
      widget.debugOnControllerReset?.call();
    }
  }

  void _scheduleControllerInitialization(BuildContext context) {
    if (!_isExpanded || _loadScheduled || _shouldRenderWebView || !_isSupported) {
      return;
    }

    if (Scrollable.recommendDeferredLoadingForContext(context)) {
      if (_retryLoadScheduled) {
        return;
      }
      _retryLoadScheduled = true;
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) {
          return;
        }
        _retryLoadScheduled = false;
        if (!_hasController && !_loadScheduled) {
          setState(() {});
        }
      });
      return;
    }

    _retryLoadScheduled = false;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_initializeController());
    });
  }

  Future<void> _initializeController({bool reuseCurrentRequestId = false}) async {
    if (!_isSupported || !_isExpanded) {
      _loadScheduled = false;
      return;
    }

    if (_isRemoteUrl && _resolvedRemoteUri == null) {
      _loadScheduled = false;
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load embedded content.';
      });
      return;
    }

    try {
      if (!reuseCurrentRequestId) {
        _loadRequestId += 1;
      }
      setState(() {
        _controller = null;
        _debugHasSeededController = false;
        _shouldRenderWebView = true;
        _height = _embedDefaultHeight;
        _isLoading = true;
        _loadError = null;
      });
    } finally {
      _loadScheduled = false;
    }
  }

  Future<void> _handleWebViewCreated(
    InAppWebViewController controller,
    int requestId,
  ) async {
    if (requestId != _loadRequestId) {
      return;
    }

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    } else {
      _controller = controller;
    }

    try {
      if (_isRemoteUrl) {
        final uri = _resolvedRemoteUri;
        if (uri == null) {
          throw StateError('Invalid embed URL');
        }
        await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
      } else {
        final baseUrl = WebUri('https://embed.conduit.local/');
        await controller.loadData(
          data: _wrapHtmlDocument(widget.source),
          baseUrl: baseUrl,
          historyUrl: baseUrl,
        );
      }
    } catch (_) {
      if (!mounted || requestId != _loadRequestId) {
        return;
      }
      setState(() {
        _controller = null;
        _shouldRenderWebView = false;
        _isLoading = false;
        _loadError = 'Unable to load embedded content.';
      });
    }
  }

  Future<void> _injectArguments(InAppWebViewController controller) async {
    final argsText = widget.argsText.trim();
    if (argsText.isEmpty) {
      return;
    }

    try {
      await controller.evaluateJavascript(
        source: 'window.args = ${jsonEncode(argsText)};',
      );
    } catch (_) {}
  }

  /// 注入高度上报脚本：
  /// 1. 拦截 embed 内 `parent.postMessage({type:"iframe:height",height})`，
  ///    转交给 Flutter 的 `conduitEmbedHeight` handler（与 Web 端机制一致）。
  /// 2. 监听所有 `<img>` 的 load 事件与 window.resize / DOM 变化，图片异步
  ///    加载完成后重新测高并上报——解决 PPT 查看器首帧图片未加载导致的留白
  ///    （即“点下载返回后才显示”的本质：图片加载完成后重新布局）。
  Future<void> _injectHeightReporter(InAppWebViewController controller) async {
    const script = r'''
(function(){
  function report(){
    try{
      var h=Math.max(
        document.documentElement.scrollHeight||0,
        document.body?document.body.scrollHeight:0,
        document.documentElement.offsetHeight||0
      );
      if(h>0 && window.flutter_inappwebview){
        window.flutter_inappwebview.callHandler('conduitEmbedHeight', h);
      }
    }catch(e){}
  }
  // 拦截 embed 通过 parent.postMessage 上报的高度（pipe 进度条/查看器）
  try{
    window.addEventListener('message', function(ev){
      var d=ev&&ev.data;
      if(d&&d.type==='iframe:height'&&d.height>0&&window.flutter_inappwebview){
        window.flutter_inappwebview.callHandler('conduitEmbedHeight', d.height);
      }
    });
  }catch(e){}
  // 图片异步加载完成后重新测高
  try{
    var imgs=document.getElementsByTagName('img');
    for(var i=0;i<imgs.length;i++){
      if(!imgs[i].complete){
        imgs[i].addEventListener('load', report);
        imgs[i].addEventListener('error', report);
      }
    }
  }catch(e){}
  // DOM 变化（查看器切页换图）后重新测高
  try{
    new MutationObserver(report).observe(document.body,{childList:true,subtree:true,attributes:true});
  }catch(e){}
  window.addEventListener('resize', report);
  report();
  setTimeout(report,300);
  setTimeout(report,1000);
  setTimeout(report,2500);
})();
''';
    try {
      await controller.evaluateJavascript(source: script);
    } catch (_) {}
  }

  /// 重写 `window.open`（及 `window.parent.open`）：拦截下载/外链点击，转交
  /// Flutter 的 `conduitOpenExternal` handler 用系统浏览器打开。
  /// 解决：embed 下载按钮原走 WebView 新窗口机制，在 iOS 上跳转返回后白屏。
  Future<void> _injectExternalOpenBridge(
    InAppWebViewController controller,
  ) async {
    const script = r'''
(function(){
  function openExternal(u){
    try{
      if(u && window.flutter_inappwebview){
        window.flutter_inappwebview.callHandler('conduitOpenExternal', String(u));
      }
    }catch(e){}
    return null; // 阻止默认新窗口行为
  }
  try{ window.open = openExternal; }catch(e){}
  try{ if(window.parent && window.parent!==window){ window.parent.open = openExternal; } }catch(e){}
})();
''';
    try {
      await controller.evaluateJavascript(source: script);
    } catch (_) {}
  }

  /// 固定视口模式：让 embed 文档在固定高度的 WebView 内可垂直滚动。
  /// 部分 embed（如 PPT 进度条）body 设了 `overflow:hidden`，这里覆盖为可滚动，
  /// 并开启 iOS 动量滚动。
  Future<void> _injectFixedViewportScroll(
    InAppWebViewController controller,
  ) async {
    const script = r'''
(function(){
  try{
    var s=document.createElement('style');
    s.textContent='html,body{height:auto !important;min-height:100% !important;'
      +'overflow-y:auto !important;-webkit-overflow-scrolling:touch !important;}';
    document.head.appendChild(s);
  }catch(e){}
})();
''';
    try {
      await controller.evaluateJavascript(source: script);
    } catch (_) {}
  }

  void _scheduleHeightUpdates(InAppWebViewController controller, int requestId) {
    _updateHeight(controller, requestId);
    for (final delay in <int>[60, 250, 600]) {
      Future<void>.delayed(Duration(milliseconds: delay), () {
        _updateHeight(controller, requestId);
      });
    }
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || requestId != _loadRequestId || !_isLoading) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _updateHeight(
    InAppWebViewController controller,
    int requestId,
  ) async {
    try {
      final measuredHeight = await measureWebViewContentHeight(controller);
      if (!mounted ||
          requestId != _loadRequestId ||
          measuredHeight == null ||
          measuredHeight <= 0) {
        return;
      }
      final clampedHeight = widget.fillAvailableHeight
          ? _height
          : measuredHeight.clamp(_embedMinHeight, _embedMaxHeight).toDouble();
      setState(() {
        _height = clampedHeight;
        _isLoading = false;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    if (!_isSupported) {
      return _EmbedFallbackCard(
        source: widget.source,
        message: _unsupportedMessage,
      );
    }

    if (_loadError != null) {
      return _EmbedFallbackCard(source: widget.source, message: _loadError!);
    }

    if (!_isExpanded) {
      return _EmbedDeferredCard(
        title: widget.previewTitle ?? 'Embedded Preview',
        description:
            widget.previewDescription ??
            (_isRemoteUrl
                ? (widget.source.startsWith('//')
                      ? 'https:${widget.source}'
                      : widget.source)
                : 'Load the embedded preview when you need it.'),
        onOpen: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _isExpanded = true;
          });
        },
      );
    }

    if (!_shouldRenderWebView) {
      _scheduleControllerInitialization(context);
      if (!widget.showChrome) {
        return const Center(child: CircularProgressIndicator());
      }
      return const _EmbedLoadingCard();
    }

    final requestId = _loadRequestId;
    final webView = Stack(
      children: [
        Positioned.fill(
          child: InAppWebView(
            key: ValueKey<int>(requestId),
            gestureRecognizers: _gestureRecognizers,
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: true,
              // 关闭多窗口：embed 内的“下载”按钮用 window.open 打开链接，
              // 多窗口 + onCreateThis 在 iOS 上会让当前 WebView 变白（下载跳转
              // 返回后白屏）。改为注入脚本把 window.open 重写为调用 Flutter
              // handler（见 _injectExternalOpenBridge），由系统浏览器打开，
              // 完全不触发 WebView 新窗口/导航。
              supportMultipleWindows: false,
              useShouldOverrideUrlLoading: true,
            ),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) {
                return NavigationActionPolicy.ALLOW;
              }
              // 兜底：拦截用户手势触发的外部 http/https 顶层跳转（如 <a> 直链），
              // 交给系统浏览器，CANCEL 导航以免 embed WebView 被替换。
              final isUserGesture = navigationAction.hasGesture ?? false;
              final scheme = uri.scheme.toLowerCase();
              final isExternal = scheme == 'http' || scheme == 'https';
              if (isUserGesture && isExternal) {
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onWebViewCreated: (controller) {
              // 注册外链打开 handler（所有模式都需要：PPT 查看器下载按钮）。
              controller.addJavaScriptHandler(
                handlerName: 'conduitOpenExternal',
                callback: (args) async {
                  final raw = args.isNotEmpty ? args.first : null;
                  final urlStr = raw?.toString();
                  if (urlStr == null || urlStr.isEmpty) {
                    return;
                  }
                  final uri = Uri.tryParse(urlStr);
                  if (uri == null) {
                    return;
                  }
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              );
              // 固定视口模式不测高（高度恒定，内容内部滚动），跳过 handler。
              if (!widget.useFixedViewport) {
                // 监听 embed 内部主动上报的高度（pipe 的进度条/查看器通过
                // postMessage({type:"iframe:height",height}) 持续上报）。
                controller.addJavaScriptHandler(
                  handlerName: 'conduitEmbedHeight',
                  callback: (args) {
                    if (!mounted || requestId != _loadRequestId) {
                      return;
                    }
                    final raw = args.isNotEmpty ? args.first : null;
                    final h = raw is num ? raw.toDouble() : null;
                    if (h == null || h <= 0) {
                      return;
                    }
                    final clamped = widget.fillAvailableHeight
                        ? _height
                        : h.clamp(_embedMinHeight, _embedMaxHeight).toDouble();
                    setState(() {
                      _height = clamped;
                      _isLoading = false;
                    });
                  },
                );
              }
              unawaited(_handleWebViewCreated(controller, requestId));
            },
            onLoadStop: (controller, _) async {
              if (requestId != _loadRequestId) {
                return;
              }
              await _injectArguments(controller);
              // 重写 window.open → Flutter handler（系统浏览器打开），避免
              // 下载按钮触发 WebView 新窗口导致返回后白屏。所有模式都注入。
              await _injectExternalOpenBridge(controller);
              if (widget.useFixedViewport) {
                // 固定视口：高度恒定、内容内部滚动，不测高。注入 CSS 让文档在
                // WebView 视口内可垂直滚动（部分 embed body 设了 overflow:hidden）。
                await _injectFixedViewportScroll(controller);
                if (mounted && _isLoading) {
                  setState(() => _isLoading = false);
                }
              } else {
                await _injectHeightReporter(controller);
                _scheduleHeightUpdates(controller, requestId);
              }
            },
            onReceivedError: (controller, request, error) {
              if (requestId != _loadRequestId ||
                  !(request.isForMainFrame ?? false) ||
                  !mounted) {
                return;
              }
              setState(() {
                _controller = null;
                _shouldRenderWebView = false;
                _isLoading = false;
                _loadError = error.description;
              });
            },
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.transparent,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );

    final double effectiveHeight;
    if (widget.useFixedViewport) {
      // 固定视口：约 60% 屏高，并限制在 [320, 640] 区间，内容在 WebView 内部
      // 上下滚动，避免外层被撑出大片空白。
      final screenHeight = MediaQuery.of(context).size.height;
      effectiveHeight = (screenHeight * 0.6).clamp(320.0, 640.0);
    } else {
      effectiveHeight = _height;
    }

    final sizedWebView = widget.fillAvailableHeight
        ? LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.hasBoundedHeight) {
                return SizedBox.expand(child: webView);
              }
              return SizedBox(height: effectiveHeight, child: webView);
            },
          )
        : SizedBox(height: effectiveHeight, child: webView);

    if (!widget.showChrome) {
      return sizedWebView;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(color: theme.cardBorder),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: theme.cardShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: sizedWebView,
      ),
    );
  }

  static String _wrapHtmlDocument(String source) {
    final trimmed = source.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
      return source;
    }

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: transparent;
      }
    </style>
  </head>
  <body>
    $source
  </body>
</html>
''';
  }
}

class _EmbedLoadingCard extends StatelessWidget {
  const _EmbedLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(color: theme.cardBorder),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: const SizedBox(
        height: _embedFallbackHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmbedDeferredCard extends StatelessWidget {
  const _EmbedDeferredCard({
    required this.title,
    required this.description,
    required this.onOpen,
  });

  final String title;
  final String description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(color: theme.cardBorder),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.bodyMediumStyle.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              description,
              style: AppTypography.bodySmallStyle.copyWith(
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpen,
                child: Text(l10n?.openPreview ?? 'Open preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmbedFallbackCard extends StatelessWidget {
  const _EmbedFallbackCard({required this.source, required this.message});

  final String source;
  final String message;

  bool get _isRemoteUrl =>
      source.startsWith('http://') ||
      source.startsWith('https://') ||
      source.startsWith('//');

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(color: theme.cardBorder),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTypography.bodySmallStyle.copyWith(
                color: theme.textSecondary,
              ),
            ),
            if (_isRemoteUrl) ...[
              const SizedBox(height: Spacing.xs),
              SelectableText(
                source.startsWith('//') ? 'https:$source' : source,
                style: AppTypography.codeStyle.copyWith(color: theme.codeText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
