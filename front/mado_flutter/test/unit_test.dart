import 'package:flutter_test/flutter_test.dart';
import 'package:mado_flutter/src/ws_set/ws_set_models.dart';
import 'package:mado_flutter/src/ws_set/ws_card_models.dart';

void main() {
  group('Plus Operator', () {
    test('should add two numbers together', () {
      expect(1 + 1, 2);
    });
  });

  group('WsCard', () {
    test('fromMap parses all fields', () {
      /// Parsing a valid cards GraphQL payload produces correct WsCard.
      ///
      /// Given:
      /// - A Map with idCard, setCode, and imagePath fields
      ///
      /// When:
      /// - WsCard.fromMap is called
      ///
      /// Then:
      /// - All fields are populated correctly
      final card = WsCard.fromMap({
        'idCard': 'BCS/W52-001',
        'setCode': 'BCS/W52',
        'imagePath': '/medias/BCS_W52/BCS_W52-001.png',
      });

      expect(card.idCard, 'BCS/W52-001');
      expect(card.setCode, 'BCS/W52');
      expect(card.imagePath, '/medias/BCS_W52/BCS_W52-001.png');
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
