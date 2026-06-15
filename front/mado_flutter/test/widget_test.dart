import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:gql/ast.dart';
import 'package:mado_flutter/src/ws_set/ws_set_list_view.dart';
import 'package:mado_flutter/src/ws_set/ws_set_models.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// Minimal Link that returns a fixed response for all queries.
class _StubLink extends Link {
  final Map<String, dynamic> data;

  _StubLink(this.data);

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    yield Response(
        data: data,
        errors: null,
        context: const Context(),
        response: {'data': data});
  }
}

GraphQLClient _stubClient(Map<String, dynamic> data) => GraphQLClient(
      link: _StubLink(data),
      cache: GraphQLCache(),
    );

void main() {
  group('MyWidget', () {
    testWidgets('should display a string of text', (WidgetTester tester) async {
      const myWidget = MaterialApp(home: Scaffold(body: Text('Hello')));
      await tester.pumpWidget(myWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('SetStatsBar', () {
    testWidgets('shows spinners when allCategories is null',
        (WidgetTester tester) async {
      /// The stats bar shows a spinner per slot when no data has loaded yet.
      ///
      /// Given:
      /// - allCategories is null (initial load not complete)
      ///
      /// When:
      /// - SetStatsBar is rendered
      ///
      /// Then:
      /// - CircularProgressIndicator widgets are present
      await tester.pumpWidget(_wrap(
        const SetStatsBar(allCategories: null, filtered: null),
      ));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows total count when loaded', (WidgetTester tester) async {
      /// The stats bar displays the resolved total count.
      ///
      /// Given:
      /// - WsSetStats with total=110, byProductType=[ブースターパック×80, トライアルデッキ×30]
      ///
      /// When:
      /// - SetStatsBar is rendered with data
      ///
      /// Then:
      /// - "110" appears in the widget tree
      final cats = [
        const CategoryStat(name: 'ブースターパック', count: 80),
        const CategoryStat(name: 'トライアルデッキ', count: 30),
      ];
      final stats = WsSetStats(total: 110, byProductType: cats);

      await tester.pumpWidget(_wrap(
        SetStatsBar(allCategories: cats, filtered: stats),
      ));

      expect(find.textContaining('110'), findsOneWidget);
    });

    testWidgets('shows all categories with zero-count for missing entries',
        (WidgetTester tester) async {
      /// The stats bar always renders all known categories; unmatched ones show 0.
      ///
      /// Given:
      /// - allCategories has [ブースターパック, トライアルデッキ]
      /// - filtered stats only contains ブースターパック×5
      ///
      /// When:
      /// - SetStatsBar is rendered
      ///
      /// Then:
      /// - Two chips render: ブースターパック=5, トライアルデッキ=0 (grayed out)
      final allCats = [
        const CategoryStat(name: 'ブースターパック', count: 80),
        const CategoryStat(name: 'トライアルデッキ', count: 30),
      ];
      final filtered = WsSetStats(
        total: 5,
        byProductType: [const CategoryStat(name: 'ブースターパック', count: 5)],
      );

      await tester.pumpWidget(_wrap(
        SetStatsBar(allCategories: allCats, filtered: filtered),
      ));

      expect(find.textContaining('ブースターパック'), findsOneWidget);
      expect(find.textContaining('トライアルデッキ'), findsOneWidget);
      expect(find.textContaining('5'), findsWidgets);
      expect(find.textContaining('0'), findsOneWidget);
    });
  });

  group('WsSetListView', () {
    testWidgets('renders SetStatsBar with spinners on initial load',
        (WidgetTester tester) async {
      /// WsSetListView shows SetStatsBar with spinners before stats data arrives.
      ///
      /// Given:
      /// - A stub GraphQL client that never responds
      ///
      /// When:
      /// - WsSetListView is pumped
      ///
      /// Then:
      /// - SetStatsBar is present in the widget tree
      /// - CircularProgressIndicator widgets are present
      final client = _stubClient({});

      await tester.pumpWidget(MaterialApp(
        home: GraphQLProvider(
          client: ValueNotifier(client),
          child: const Scaffold(body: WsSetListView()),
        ),
      ));

      expect(find.byType(SetStatsBar), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
