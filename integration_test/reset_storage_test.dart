import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// One-shot device-storage reset used after E2E runs against a tunneled
/// local backend: restores the production server URL and drops the test
/// session token. Not part of any suite — run explicitly when needed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reset stored server url and token', (tester) async {
    const storage = SecureStorage();
    await storage.write('server_url', 'https://cuenti.muh');
    await storage.delete('jwt_token');
    expect(await storage.read('server_url'), 'https://cuenti.muh');
  });
}
