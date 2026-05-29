import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/services/login_credentials_service.dart';
import 'package:souma_parfumerie/core/widgets/app_footer.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';
import 'package:souma_parfumerie/core/widgets/selectable_content.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _totpCode = TextEditingController();
  final _credentials = LoginCredentialsService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loadingCreds = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.sessionExpired) {
        auth.clearSessionExpiredFlag();
        final l10n = AppLocalizations.of(context)!;
        AppNotifier.warning(l10n.sessionExpired, context: context);
      }
    });
  }

  Future<void> _loadSavedCredentials() async {
    final remember = await _credentials.isRememberEnabled();
    final saved = await _credentials.load();
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (saved.username != null) _username.text = saved.username!;
      if (saved.password != null) _password.text = saved.password!;
      _loadingCreds = false;
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _totpCode.dispose();
    super.dispose();
  }

  String _errorMessage(AppLocalizations l10n, String? errorKey) {
    return switch (errorKey) {
      'connectionError' => l10n.connectionError,
      'loginError' => l10n.loginError,
      'accountLocked' => l10n.accountLocked,
      'totpInvalid' => l10n.totpInvalid,
      'dbMigrationRequired' => l10n.dbMigrationRequired,
      _ => l10n.errorGeneric,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (auth.needsTotp) {
      final ok = await auth.verifyTotp(_totpCode.text);
      if (!ok && mounted) {
        AppNotifier.error(_errorMessage(l10n, auth.error), context: context);
      }
      return;
    }

    final user = _username.text.trim();
    final pass = _password.text;

    final ok = await auth.login(user, pass);
    if (!ok && mounted) {
      if (auth.needsTotp) {
        setState(() {});
        return;
      }
      AppNotifier.show(
        _errorMessage(l10n, auth.error),
        context: context,
        kind: auth.error == 'connectionError'
            ? AppNoticeKind.warning
            : AppNoticeKind.error,
      );
      return;
    }

    if (ok) {
      await _credentials.save(
        username: user,
        password: pass,
        remember: _rememberMe,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final needsTotp = auth.needsTotp;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SelectableContent(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Container(
                      width: 420,
                      padding: const EdgeInsets.all(32),
                      child: _loadingCreds
                          ? const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AppLogo(size: 120, showBorder: true),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.appTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    needsTotp ? l10n.twoFactorAuth : l10n.login,
                                  ),
                                  const SizedBox(height: 24),
                                  if (!needsTotp) ...[
                                    TextFormField(
                                      controller: _username,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      decoration: InputDecoration(
                                        labelText: l10n.username,
                                        prefixIcon: const Icon(Icons.person),
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? l10n.username
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: l10n.password,
                                        prefixIcon: const Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.isEmpty
                                          ? l10n.password
                                          : null,
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 8),
                                    CheckboxListTile(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false,
                                      ),
                                      title: Text(
                                        l10n.rememberCredentials,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ] else ...[
                                    Text(
                                      l10n.totpEnterCode,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _totpCode,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.totpCode,
                                        prefixIcon: const Icon(Icons.pin),
                                      ),
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) =>
                                          v == null || v.length != 6
                                              ? l10n.totpCode
                                              : null,
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    TextButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () {
                                              auth.cancelTotp();
                                              _totpCode.clear();
                                            },
                                      child: Text(l10n.cancel),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          auth.isLoading ? null : _submit,
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              needsTotp
                                                  ? l10n.signIn
                                                  : l10n.signIn,
                                            ),
                                    ),
                                  ),
                                  if (!needsTotp) ...[
                                    const SizedBox(height: 16),
                                    SegmentedButton<String>(
                                      segments: [
                                        ButtonSegment(
                                          value: 'fr',
                                          label: Text(l10n.french),
                                        ),
                                        ButtonSegment(
                                          value: 'ar',
                                          label: Text(l10n.arabic),
                                        ),
                                      ],
                                      selected: {locale.locale.languageCode},
                                      onSelectionChanged: (s) =>
                                          locale.setLocale(s.first),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const AppFooter(onDarkBackground: true),
            ],
          ),
        ),
      ),
    );
  }
}
