import 'package:cuentimobile/core/api/reachability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late Reachability r;

  setUp(() {
    now = DateTime(2026, 9, 28, 12);
    r = Reachability(clock: () => now);
  });

  test('lets everything through until a failure', () {
    expect(r.admit(), isTrue);
    expect(r.admit(), isTrue);
    expect(r.isOpen, isFalse);
  });

  test('after a failure, holds requests back for the window', () {
    r.recordOffline();

    expect(r.admit(), isFalse);
    now = now.add(Reachability.initialWindow - const Duration(seconds: 1));
    expect(r.admit(), isFalse);
  });

  test('when the window is over, lets exactly one request through to find '
      'out', () {
    r.recordOffline();
    now = now.add(Reachability.initialWindow);

    expect(r.admit(), isTrue, reason: 'the probe');
    expect(r.admit(), isFalse, reason: 'everyone else waits on it');
  });

  test('a failed probe doubles the wait, up to the cap', () {
    r.recordOffline();
    var expected = Reachability.initialWindow;
    for (var i = 0; i < 6; i++) {
      now = now.add(expected);
      expect(r.admit(), isTrue);
      r.recordOffline();
      final doubled = expected * 2;
      expected = doubled > Reachability.maxWindow
          ? Reachability.maxWindow
          : doubled;
      now = now.add(expected - const Duration(seconds: 1));
      expect(r.admit(), isFalse, reason: 'round $i');
      now = now.add(const Duration(seconds: 1) - expected);
    }
    expect(expected, Reachability.maxWindow);
  });

  test('failures from requests already in flight do not stretch the '
      'window', () {
    r
      ..recordOffline()
      ..recordOffline()
      ..recordOffline();

    now = now.add(Reachability.initialWindow);
    expect(r.admit(), isTrue);
  });

  test('a successful probe closes it and starts the window over', () {
    r.recordOffline();
    now = now.add(Reachability.initialWindow);
    r
      ..admit()
      ..recordReachable();

    expect(r.admit(), isTrue);
    expect(r.admit(), isTrue);
    r.recordOffline();
    now = now.add(Reachability.initialWindow);
    expect(r.admit(), isTrue, reason: 'back to the first window');
  });

  test('a probe that never reports back does not hold everything forever', () {
    r.recordOffline();
    now = now.add(Reachability.initialWindow);
    expect(r.admit(), isTrue);

    now = now.add(Reachability.probeTimeout);

    expect(r.admit(), isTrue);
  });

  test('a released probe lets the next request probe instead', () {
    r.recordOffline();
    now = now.add(Reachability.initialWindow);
    expect(r.admit(), isTrue);

    r.release();

    expect(r.admit(), isTrue);
  });

  test('reset forgets the failure', () {
    r
      ..recordOffline()
      ..reset();

    expect(r.admit(), isTrue);
    expect(r.isOpen, isFalse);
  });
}
