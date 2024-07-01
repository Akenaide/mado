import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mado_flutter/src/ws_set/ws_set_models.dart';

// Future<List<WsSet>> fetchSets(ValueNotifier<GraphQLClient> notifier) {}

// final setBuilder = FutureBuilder<List<WsSet>>(
//   future: fetchSets(valueNotifier),
//   builder: (context, snapshot) {
//     if (snapshot.hasData) {
//       return WsSetListView(sets: snapshot.data!);
//     } else {
//       return const CircularProgressIndicator();
//     }
//   },
// );

class WsSetListView extends StatefulWidget {

  const WsSetListView({super.key});

  @override
  _WsSetListViewState createState() => _WsSetListViewState();
}

class _WsSetListViewState extends State<WsSetListView> {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(readWsSet), // this is the query string you just created
        pollInterval: const Duration(seconds: 10),
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.hasException) {
          return Text(result.exception.toString());
        }

        if (result.isLoading) {
          return const Text('Loading');
        }

        List? sets = result.data?['sets'];

        if (sets == null) {
          return const Text('No repositories');
        }

        return ListView.builder(
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final set = sets[index];
            return Card(
              child: ListTile(
                leading: Image.network(set["imageUrl"]),
                title: Text(set["title"]),
                subtitle: Text('Release Date: ${set["releaseDate"]}'),
              ),
            );
          },
        );
      },
    );
  }
}
