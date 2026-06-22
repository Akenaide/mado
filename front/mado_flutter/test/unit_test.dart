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
    test('fromMap parses full stat fields', () {
      """
      WsCard.fromMap populates all stat fields from a full getCard payload.

      Given:
      - A Map with name, level, cost, power, soul, color, triggers,
        abilities, specialAttribute, flavourText

      When:
      - WsCard.fromMap is called

      Then:
      - All stat fields match the input values
      """;
      final card = WsCard.fromMap({
        'idCard': 'X',
        'setCode': 'Y',
        'cardType': 'CH',
        'name': 'Asuna',
        'level': 2,
        'cost': 1,
        'power': 8500,
        'soul': 1,
        'color': 'Blue',
        'triggers': ['Soul'],
        'abilities': ['[A] When this card attacks, draw 1 card.'],
        'specialAttribute': ['Sword', 'Net Game'],
        'flavourText': 'I will protect you.',
      });
      expect(card.name, 'Asuna');
      expect(card.level, 2);
      expect(card.cost, 1);
      expect(card.power, 8500);
      expect(card.soul, 1);
      expect(card.color, 'Blue');
      expect(card.triggers, ['Soul']);
      expect(card.abilities, ['[A] When this card attacks, draw 1 card.']);
      expect(card.specialAttribute, ['Sword', 'Net Game']);
      expect(card.flavourText, 'I will protect you.');
    });

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
