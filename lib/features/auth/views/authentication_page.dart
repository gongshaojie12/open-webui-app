import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/backend_config.dart';
import '../../../core/models/server_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/input_validation_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/widgets/conduit_components.dart';
import '../../../core/auth/auth_state_manager.dart';
import '../../../core/utils/debug_logger.dart';
import 'package:conduit/l10n/app_localizations.dart';
import '../providers/unified_auth_providers.dart';

/// Authentication mode options
enum AuthMode {
  credentials, // Email/password
  token, // JWT token
  sso, // OAuth/OIDC via WebView
  ldap, // LDAP username/password
  focusmedia, // FocusMedia IAM (竹云) via OAuth WebView
}

class AuthenticationPage extends ConsumerStatefulWidget {
  final ServerConfig? serverConfig;
  final BackendConfig? backendConfig;

  const AuthenticationPage({super.key, this.serverConfig, this.backendConfig});

  @override
  ConsumerState<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends ConsumerState<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ldapUsernameController = TextEditingController();
  final TextEditingController _ldapPasswordController = TextEditingController();

  bool _obscurePassword = true;
  AuthMode _authMode = AuthMode.credentials;
  String? _loginError;
  bool _isSigningIn = false;
  bool _serverConfigSaved = false;
  /// Whether the login form (email/password) is enabled on the server.
  bool get _hasLoginFormEnabled =>
      widget.backendConfig?.enableLoginForm ?? true;

  /// Available auth modes for the segmented control.
  List<AuthMode> get _availableAuthModes {
    final modes = <AuthMode>[];
    if (_hasLoginFormEnabled) modes.add(AuthMode.credentials);
    modes.add(AuthMode.ldap);
    modes.add(AuthMode.focusmedia);
    return modes;
  }

  /// Label for each auth mode segment.
  String _authModeLabel(AuthMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case AuthMode.credentials:
        return l10n.credentials;
      case AuthMode.sso:
        return l10n.sso;
      case AuthMode.ldap:
        return l10n.ldap;
      case AuthMode.token:
        return l10n.token;
      case AuthMode.focusmedia:
        return '竹云';
    }
  }

  @override
  void initState() {
    super.initState();
    _setDefaultAuthMode();
    _loadSavedCredentials();
    // Check for auth errors (e.g., forced logout due to API key)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStateError();
    });
  }

  /// Set the default auth mode based on what the server supports.
  void _setDefaultAuthMode() {
    if (_hasLoginFormEnabled) {
      _authMode = AuthMode.credentials;
    } else {
      _authMode = AuthMode.ldap;
    }
  }

  void _checkAuthStateError() {
    final authState = ref.read(authStateManagerProvider).asData?.value;
    if (authState?.error != null && authState!.error!.isNotEmpty) {
      setState(() {
        _loginError = _formatLoginError(authState.error!);
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    final storage = ref.read(optimizedStorageServiceProvider);
    final savedCredentials = await storage.getSavedCredentials();
    if (savedCredentials != null) {
      setState(() {
        _usernameController.text = savedCredentials['username'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _ldapUsernameController.dispose();
    _ldapPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    // FocusMedia mode launches WebView directly, no form validation needed
    if (_authMode == AuthMode.focusmedia) {
      _launchFocusMediaLogin();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSigningIn = true;
      _loginError = null;
    });

    try {
      // Save server config on first sign-in attempt if it's a new config
      // This persists the server so user can retry with different credentials
      if (widget.serverConfig != null && !_serverConfigSaved) {
        await _saveServerConfig(widget.serverConfig!);
        _serverConfigSaved = true;
      }

      final actions = ref.read(authActionsProvider);
      bool success;

      switch (_authMode) {
        case AuthMode.credentials:
          success = await actions.login(
            _usernameController.text.trim(),
            _passwordController.text,
            rememberCredentials: true,
          );
        case AuthMode.ldap:
          success = await actions.ldapLogin(
            _ldapUsernameController.text.trim(),
            _ldapPasswordController.text,
            rememberCredentials: true,
          );
        case AuthMode.focusmedia:
        case AuthMode.token:
        case AuthMode.sso:
          return;
      }

      if (!success) {
        final authState = ref.read(authStateManagerProvider);
        throw Exception(authState.error ?? l10n.loginFailed);
      }

      // Success - navigation will be handled by auth state change
    } catch (e) {
      // Don't clear server config on auth failure - user should be able to retry
      // The server config is valid (passed OpenWebUI verification), only the
      // credentials were wrong or there was a network issue
      setState(() {
        _loginError = _formatLoginError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _saveServerConfig(ServerConfig config) async {
    final storage = ref.read(optimizedStorageServiceProvider);
    await storage.saveServerConfigs([config]);
    await storage.setActiveServerId(config.id);
    ref.invalidate(serverConfigsProvider);
    ref.invalidate(activeServerProvider);
  }

  String _formatLoginError(String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('apiKeyNotSupported')) {
      return l10n.apiKeyNotSupported;
    } else if (error.contains('apiKeyNoLongerSupported')) {
      return l10n.apiKeyNoLongerSupported;
    } else if (error.contains('LDAP authentication is not enabled')) {
      return l10n.ldapNotEnabled;
    } else if (error.contains('401') || error.contains('Unauthorized')) {
      return l10n.invalidCredentials;
    } else if (error.contains('redirect')) {
      return l10n.serverRedirectingHttps;
    } else if (error.contains('SocketException')) {
      return l10n.unableToConnectServer;
    } else if (error.contains('timeout')) {
      return l10n.requestTimedOut;
    }
    return l10n.genericSignInFailed;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to navigate on successful login
    ref.listen<AsyncValue<AuthState>>(authStateManagerProvider, (
      previous,
      next,
    ) {
      final nextState = next.asData?.value;
      final prevState = previous?.asData?.value;
      if (mounted &&
          nextState?.isAuthenticated == true &&
          prevState?.isAuthenticated != true) {
        DebugLogger.auth(
          'Authentication successful, initializing background resources',
        );

        // Model selection will be handled by the chat page
        // to avoid widget disposal issues

        DebugLogger.auth('Navigating to chat page');
        // Navigate directly to chat page on successful authentication
        context.go(Routes.chat);
      }
    });

    final safePadding = MediaQuery.of(context).padding;

    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: context.conduitTheme.surfaceBackground,
        body: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: Spacing.pagePadding,
                        right: Spacing.pagePadding,
                        top: safePadding.top + Spacing.md,
                      ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: Spacing.xl),

                          // Brand icon + title header
                          _buildHeader(),

                          const SizedBox(height: Spacing.xxl),

                          // Auth mode selector
                          if (_availableAuthModes.length > 1) ...[
                            _buildAuthModeSelector(),
                            const SizedBox(height: Spacing.lg),
                          ],

                          // Authentication form
                          _buildAuthForm(),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),

            // Bottom action button (hidden when FocusMedia mode is active)
            if (_authMode != AuthMode.focusmedia)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.pagePadding,
                  Spacing.md,
                  Spacing.pagePadding,
                  safePadding.bottom + Spacing.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildSignInButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = context.conduitTheme;

    return Column(
      children: [
        // App icon
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 72,
            height: 72,
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Title
        Text(
          AppLocalizations.of(context)!.signIn,
          textAlign: TextAlign.center,
          style: theme.headingLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: AppTypography.letterSpacingTight,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthModeSelector() {
    final modes = _availableAuthModes;
    final selectedIndex = modes.indexOf(_authMode);
    final theme = context.conduitTheme;

    if (!Platform.isAndroid) {
      return AdaptiveSegmentedControl(
        labels: modes.map(_authModeLabel).toList(),
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onValueChanged: (index) {
          setState(() {
            _authMode = modes[index];
            _loginError = null;
            _obscurePassword = true;
          });
        },
      );
    }

    // Android: custom segmented control without checkmark
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.button),
        border: Border.all(
          color: theme.cardBorder,
          width: BorderWidth.thin,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (int i = 0; i < modes.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _authMode = modes[i];
                    _loginError = null;
                    _obscurePassword = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? theme.buttonPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.button - 2,
                    ),
                  ),
                  child: Text(
                    _authModeLabel(modes[i]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      fontWeight: i == selectedIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: i == selectedIndex
                          ? theme.buttonPrimaryText
                          : theme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  void _launchFocusMediaLogin() {
    context.push(
      Routes.ssoAuth,
      extra: <String, dynamic>{
        'oauthLoginPath': '/oauth/focusmedia/login',
        'title': '竹云',
      },
    );
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show the appropriate form based on auth mode
        if (_hasLoginFormEnabled && _authMode == AuthMode.credentials) ...[
          _buildCredentialsForm(),
        ] else if (_authMode == AuthMode.ldap) ...[
          _buildLdapForm(),
        ] else if (_authMode == AuthMode.focusmedia) ...[
          _buildFocusMediaForm(),
        ],

        if (_loginError != null) ...[
          const SizedBox(height: Spacing.md),
          _buildErrorMessage(_loginError!),
        ],
      ],
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

  Widget _buildCredentialsForm() {
    return AutofillGroup(
      child: Column(
        key: const ValueKey('credentials_form'),
        children: [
          AdaptiveTextFormField(
            controller: _usernameController,
            placeholder: AppLocalizations.of(context)!.usernameOrEmailHint,
            validator: (value) {
              final v = value ?? _usernameController.text;
              return InputValidationService.combine([
                InputValidationService.validateRequired,
                (val) => InputValidationService.validateEmailOrUsername(val),
              ])(v);
            },
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Platform.isIOS ? CupertinoIcons.person : Icons.person_outline,
              color: context.conduitTheme.iconSecondary,
            ),
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            cupertinoDecoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground,
              border: Border.all(
                color: context.conduitTheme.inputBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          AdaptiveTextFormField(
            controller: _passwordController,
            placeholder: AppLocalizations.of(context)!.passwordHint,
            validator: (value) {
              final v = value ?? _passwordController.text;
              return InputValidationService.combine([
                InputValidationService.validateRequired,
                (val) => InputValidationService.validateMinLength(
                  val,
                  1,
                  fieldName: AppLocalizations.of(context)!.password,
                ),
              ])(v);
            },
            obscureText: _obscurePassword,
            prefixIcon: Icon(
              Platform.isIOS ? CupertinoIcons.lock : Icons.lock_outline,
              color: context.conduitTheme.iconSecondary,
            ),
            suffixIcon: ConduitIconButton(
              icon: _obscurePassword
                  ? (Platform.isIOS
                        ? CupertinoIcons.eye_slash
                        : Icons.visibility_off)
                  : (Platform.isIOS
                        ? CupertinoIcons.eye
                        : Icons.visibility),
              iconColor: context.conduitTheme.iconSecondary,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword
                  ? 'Show password'
                  : 'Hide password',
              isCompact: true,
            ),
            onSubmitted: (_) => _signIn(),
            autofillHints: const [AutofillHints.password],
            cupertinoDecoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground,
              border: Border.all(
                color: context.conduitTheme.inputBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLdapForm() {
    final l10n = AppLocalizations.of(context)!;

    return AutofillGroup(
      child: Column(
        key: const ValueKey('ldap_form'),
        children: [
          AdaptiveTextFormField(
            controller: _ldapUsernameController,
            placeholder: l10n.ldapUsernameHint,
            validator: (value) => InputValidationService.validateRequired(
              value ?? _ldapUsernameController.text,
            ),
            keyboardType: TextInputType.text,
            prefixIcon: Icon(
              Platform.isIOS ? CupertinoIcons.person : Icons.person_outline,
              color: context.conduitTheme.iconSecondary,
            ),
            autofillHints: const [AutofillHints.username],
            cupertinoDecoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground,
              border: Border.all(
                color: context.conduitTheme.inputBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          AdaptiveTextFormField(
            controller: _ldapPasswordController,
            placeholder: l10n.passwordHint,
            validator: (value) {
              final v = value ?? _ldapPasswordController.text;
              return InputValidationService.combine([
                InputValidationService.validateRequired,
                (val) => InputValidationService.validateMinLength(
                  val,
                  1,
                  fieldName: l10n.password,
                ),
              ])(v);
            },
            obscureText: _obscurePassword,
            prefixIcon: Icon(
              Platform.isIOS ? CupertinoIcons.lock : Icons.lock_outline,
              color: context.conduitTheme.iconSecondary,
            ),
            suffixIcon: ConduitIconButton(
              icon: _obscurePassword
                  ? (Platform.isIOS
                        ? CupertinoIcons.eye_slash
                        : Icons.visibility_off)
                  : (Platform.isIOS
                        ? CupertinoIcons.eye
                        : Icons.visibility),
              iconColor: context.conduitTheme.iconSecondary,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword
                  ? 'Show password'
                  : 'Hide password',
              isCompact: true,
            ),
            onSubmitted: (_) => _signIn(),
            autofillHints: const [AutofillHints.password],
            cupertinoDecoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemBackground,
              border: Border.all(
                color: context.conduitTheme.inputBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            l10n.ldapDescription,
            style: context.conduitTheme.bodySmall?.copyWith(
              color: context.conduitTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    final l10n = AppLocalizations.of(context)!;

    String buttonText;
    if (_isSigningIn) {
      buttonText = l10n.signingIn;
    } else {
      switch (_authMode) {
        case AuthMode.credentials:
          buttonText = l10n.signIn;
        case AuthMode.token:
          buttonText = l10n.signInWithToken;
        case AuthMode.ldap:
          buttonText = l10n.signInWithLdap;
        case AuthMode.focusmedia:
          buttonText = '竹云登录';
        case AuthMode.sso:
          buttonText = l10n.signInWithSso;
      }
    }

    return ConduitButton(
      text: buttonText,
      icon: _isSigningIn
          ? null
          : (Platform.isIOS
                ? CupertinoIcons.arrow_right
                : Icons.arrow_forward),
      onPressed: _isSigningIn ? null : _signIn,
      isLoading: _isSigningIn,
      isFullWidth: true,
    );
  }

  Widget _buildErrorMessage(String message) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: context.conduitTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
          border: Border.all(
            color: context.conduitTheme.error.withValues(alpha: 0.2),
            width: BorderWidth.standard,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.exclamationmark_circle
                  : Icons.error_outline,
              color: context.conduitTheme.error,
              size: IconSize.small,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.conduitTheme.bodySmall?.copyWith(
                  color: context.conduitTheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
