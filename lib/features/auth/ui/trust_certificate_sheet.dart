import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puts [rejected] in front of the user and, if they vouch for it, pins it
/// for that host. Returns whether the certificate is trusted afterwards.
///
/// Shared by the two places a rejection can surface: server setup, where the
/// user has just typed a URL, and the login screen, which is where a fresh
/// install meets the default server without ever passing through setup.
Future<bool> promptToTrustCertificate(
  BuildContext context,
  WidgetRef ref,
  ({String host, String fingerprint}) rejected,
) async {
  final trusted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => TrustCertificateSheet(rejected: rejected),
  );
  if (!(trusted ?? false)) return false;
  await ref
      .read(apiClientProvider)
      .pins
      .trust(rejected.host, rejected.fingerprint);
  return true;
}

/// Asks the user to vouch for a self-signed certificate, showing the
/// fingerprint so they can compare it against what their server reports
/// (`openssl x509 -fingerprint -sha256`).
class TrustCertificateSheet extends StatelessWidget {
  const TrustCertificateSheet({required this.rejected, super.key});

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
            L.of(context).serverUntrustedBody(rejected.host),
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
