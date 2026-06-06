import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mado_flutter/src/ws_set/ws_set_models.dart';

class WsSetListView extends StatefulWidget {
  const WsSetListView({super.key});

  @override
  State<WsSetListView> createState() => _WsSetListViewState();
}

class _WsSetListViewState extends State<WsSetListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search sets…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: Query(
            options: QueryOptions(
              document: gql(isSearching ? searchWsSets : readWsSet),
              variables: isSearching ? {'query': _searchQuery} : {},
              pollInterval: isSearching ? null : const Duration(seconds: 10),
            ),
            builder: (QueryResult result,
                {VoidCallback? refetch, FetchMore? fetchMore}) {
              if (result.hasException) {
                return Center(child: Text(result.exception.toString()));
              }

              if (result.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final List? sets =
                  result.data?[isSearching ? 'searchSets' : 'sets'];

              if (sets == null || sets.isEmpty) {
                return const Center(child: Text('No sets found'));
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 280,
                ),
                itemCount: sets.length,
                itemBuilder: (context, index) {
                  final set = sets[index];
                  return _SetCard(set: set);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SetCard extends StatelessWidget {
  final Map set;

  const _SetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    final imagePath = set['imagePath'] as String?;
    final backendUrl = const String.fromEnvironment('BACKEND_URL');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: imagePath != null
                ? Image.network(
                    '$backendUrl$imagePath',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _FallbackImage(),
                  )
                : const _FallbackImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  set['title'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  set['releaseDate'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );
  }
}
