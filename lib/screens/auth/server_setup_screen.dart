import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _controller.text = auth.serverUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dns, size: 64),
            const SizedBox(height: 24),
            Text('Server URL', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Enter the URL of your Cuenti server'),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://192.168.1.100:8080',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await auth.setServerUrl(_controller.text.trim());
                if (context.mounted) context.go('/login');
              },
              child: const Text('Save & Continue'),
            ),
          ],
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
