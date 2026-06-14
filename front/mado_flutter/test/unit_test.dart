import 'package:flutter_test/flutter_test.dart';
import 'package:mado_flutter/src/ws_set/ws_set_models.dart';

void main() {
  group('Plus Operator', () {
    test('should add two numbers together', () {
      expect(1 + 1, 2);
    });
  });

  group('WsSetStats', () {
    test('fromMap parses total and categories', () {
      /// Parsing a valid setStats GraphQL payload produces correct WsSetStats.
      ///
      /// Given:
      /// - A Map with total=110, byProductType=[{name: "ブースターパック", count: 80}, ...]
      ///
      /// When:
      /// - WsSetStats.fromMap is called
      ///
      /// Then:
      /// - total equals 110
      /// - byProductType contains two CategoryStat entries with correct values
      final stats = WsSetStats.fromMap({
        'total': 110,
        'byProductType': [
          {'name': 'ブースターパック', 'count': 80},
          {'name': 'トライアルデッキ', 'count': 30},
        ],
      });

      expect(stats.total, 110);
      expect(stats.byProductType.length, 2);
      expect(stats.byProductType[0].name, 'ブースターパック');
      expect(stats.byProductType[0].count, 80);
      expect(stats.byProductType[1].name, 'トライアルデッキ');
      expect(stats.byProductType[1].count, 30);
    });
  });
}
