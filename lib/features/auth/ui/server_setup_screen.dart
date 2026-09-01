import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  /// Saves the URL, then reaches the server once so a certificate the user
  /// has not vouched for is caught here rather than surfacing as an opaque
  /// connection error on the login screen.
  Future<void> _save() async {
    setState(() => _saving = true);
    ({String host, String fingerprint})? rejected;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .setServerUrl(_controller.text.trim());
      rejected = await _probeForUntrustedCertificate();
    } finally {
      // Drop the progress indicator before any prompt: leaving it spinning
      // under a modal sheet is both wrong and untestable.
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (rejected != null && !await _askToTrust(rejected)) return;
    if (mounted) context.go('/login');
  }

  /// Reaches the server and reports the certificate that was turned away, if
  /// any. Other failures are ignored on purpose: a server that is merely
  /// offline should not block setup.
  Future<({String host, String fingerprint})?>
  _probeForUntrustedCertificate() async {
    final pins = ref.read(apiClientProvider).pins..lastRejection = null;
    try {
      await ref.read(authRepositoryProvider).fetchRegistrationEnabled();
      // Any failure other than a rejected certificate is not this screen's
      // problem; the rejection, if there was one, is recorded on the pins.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // fall through to the recorded rejection below
    }
    return pins.lastRejection;
  }

  Future<bool> _askToTrust(({String host, String fingerprint}) rejected) async {
    final trusted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TrustCertificateSheet(rejected: rejected),
    );
    if (trusted ?? false) {
      await ref
          .read(apiClientProvider)
          .pins
          .trust(rejected.host, rejected.fingerprint);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(authControllerProvider.notifier).serverUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/Cuenti.png', width: 80, height: 80),
                const SizedBox(height: 16),
                Text(
                  L.of(context).serverSetupTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: L.of(context).serverUrl,
                    hintText: 'http://192.168.1.100:8080',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(L.of(context).serverSaveContinue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Asks the user to vouch for a self-signed certificate, showing the
/// fingerprint so they can compare it against what their server reports
/// (`openssl x509 -fingerprint -sha256`).
class _TrustCertificateSheet extends StatelessWidget {
  const _TrustCertificateSheet({required this.rejected});

  final ({String host, String fingerprint}) rejected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.of(context).serverUntrustedTitle,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${rejected.host} presented a certificate no certificate '
            'authority vouches for. That is normal for a self-hosted Cuenti '
            'server, but it is also what an intercepted connection looks '
            'like. Trust it only if this fingerprint matches your server.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SelectableText(
            rejected.fingerprint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(L.of(context).commonCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(L.of(context).serverTrust),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
