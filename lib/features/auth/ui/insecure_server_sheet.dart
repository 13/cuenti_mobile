import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Whether [url] will be reached without TLS.
///
/// A scheme-less entry is left alone: the client resolves it, and guessing
/// at the user's intent here would warn about the wrong thing.
bool isInsecureServerUrl(String url) =>
    url.trim().toLowerCase().startsWith('http://');

/// The host part of [url], for naming in the warning. Falls back to the
/// whole string when it will not parse -- an unparseable URL is still worth
/// warning about.
String serverHostOf(String url) {
  final host = Uri.tryParse(url.trim())?.host;
  return host == null || host.isEmpty ? url.trim() : host;
}

/// Warns that a server will be reached over plain http, and reports whether
/// the user wants to go ahead.
///
/// The app checks self-signed certificates fingerprint by fingerprint, and
/// none of that machinery does anything when there is no certificate at
/// all: over http the password, the bearer token and every figure the app
/// loads cross the network in the clear. A LAN server is a real reason to
/// want this, so it stays possible -- but it is now a decision rather than
/// a default the example URL quietly nudged people into.
Future<bool> promptForInsecureServer(BuildContext context, String url) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _InsecureServerSheet(host: serverHostOf(url)),
  );
  return accepted ?? false;
}

class _InsecureServerSheet extends StatelessWidget {
  const _InsecureServerSheet({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.serverInsecureTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.serverInsecureBody(host), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l.commonCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l.serverInsecureContinue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
