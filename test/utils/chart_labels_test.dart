import 'package:cuentimobile/utils/chart_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('labelStride', () {
    test('labels every point when they all fit', () {
      expect(labelStride(pointCount: 4, width: 320), 1);
    });

    test('steps over points when there are more than the width holds', () {
      // 320px holds six 48px labels; 30 points need one in five.
      expect(labelStride(pointCount: 30, width: 320), 5);
    });

    test('a narrower chart steps further', () {
      expect(
        labelStride(pointCount: 30, width: 160),
        greaterThan(labelStride(pointCount: 30, width: 320)),
      );
    });

    test('never returns zero, which would label nothing or divide by it', () {
      for (final count in [0, 1, 2, 200]) {
        for (final width in [0.0, 1.0, 320.0, 4000.0]) {
          expect(
            labelStride(pointCount: count, width: width),
            greaterThanOrEqualTo(1),
            reason: 'count $count at width $width',
          );
        }
      }
    });

    test('a chart with no width still yields a usable stride', () {
      expect(labelStride(pointCount: 30, width: 0), greaterThanOrEqualTo(1));
    });
  });

  group('showsLabel', () {
    test('the first and last points are always labelled', () {
      const count = 30;
      final stride = labelStride(pointCount: count, width: 320);

      expect(showsLabel(0, count, stride), isTrue);
      expect(showsLabel(count - 1, count, stride), isTrue);
    });

    test('with a stride of one, every point is labelled', () {
      expect([
        for (var i = 0; i < 4; i++) showsLabel(i, 4, 1),
      ], everyElement(isTrue));
    });

    test('points between are labelled on the stride', () {
      expect(showsLabel(5, 30, 5), isTrue);
      expect(showsLabel(6, 30, 5), isFalse);
    });

    test('a point too close to the end is skipped, so its label cannot '
        'collide with the last one, which is always drawn', () {
      // 20 sits a full stride clear of the final point at 29, so it stays.
      expect(showsLabel(20, 30, 5), isTrue);
      // 25 is on the stride but only four from the end -- closer than the
      // stride, so its label would crowd the last one.
      expect(showsLabel(25, 30, 5), isFalse);
      expect(showsLabel(28, 30, 5), isFalse);
    });

    test('a single point is labelled', () {
      expect(showsLabel(0, 1, 1), isTrue);
    });
  });
}
