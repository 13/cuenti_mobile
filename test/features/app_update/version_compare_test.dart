import 'package:cuentimobile/features/app_update/domain/version_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newer patch/minor/major detected', () {
    expect(isNewerVersion('2.0.4', 'v2.0.5'), isTrue);
    expect(isNewerVersion('2.0.4', 'v2.1.0'), isTrue);
    expect(isNewerVersion('2.0.4', 'v3.0.0'), isTrue);
  });

  test('equal or older is not newer', () {
    expect(isNewerVersion('2.0.4', 'v2.0.4'), isFalse);
    expect(isNewerVersion('2.0.4', 'v2.0.3'), isFalse);
    expect(isNewerVersion('2.1.0', 'v2.0.9'), isFalse);
  });

  test('build number and v prefix ignored', () {
    expect(isNewerVersion('2.0.4+12', 'v2.0.5'), isTrue);
    expect(isNewerVersion('2.0.4', '2.0.5'), isTrue);
  });

  test('malformed input is never newer', () {
    expect(isNewerVersion('2.0.4', 'nightly'), isFalse);
    expect(isNewerVersion('', 'v2.0.5'), isFalse);
  });
}
