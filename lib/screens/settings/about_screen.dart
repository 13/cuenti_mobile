import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _packageInfo?.version ?? '...';
    final buildNumber = _packageInfo?.buildNumber ?? '...';
    final appName = _packageInfo?.appName ?? 'Cuenti';

    const buildDate = String.fromEnvironment('BUILD_DATE', defaultValue: 'Development');
    const buildTime = String.fromEnvironment('BUILD_TIME', defaultValue: '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // App Hero Card
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                Image.asset('assets/Cuenti.png', width: 80, height: 80),
                const SizedBox(height: 16),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A mobile cuenti app',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Build Details Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Software Info', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _infoRow('Version', version),
                _infoRow('Build Number', buildNumber),
                _infoRow('Build Date', buildDate),
                if (buildTime.isNotEmpty) _infoRow('Build Time', buildTime),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Description Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About Cuenti', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const Text(
                  'Cuenti is a personal finance management application that helps you track your transactions, manage accounts, and monitor your assets across different currencies.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {}, // Optional: Open project website
                  icon: const Icon(Icons.language),
                  label: const Text('Visit Website'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Footer
        Center(
          child: Text(
            '© ${DateTime.now().year} Cuenti Team',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
