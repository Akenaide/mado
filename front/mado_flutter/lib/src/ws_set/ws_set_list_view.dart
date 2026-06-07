import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mado_flutter/src/ws_set/ws_set_models.dart';

const _pageSize = 20;

class WsSetListView extends StatefulWidget {
  const WsSetListView({super.key});

  @override
  State<WsSetListView> createState() => _WsSetListViewState();
}

class _WsSetListViewState extends State<WsSetListView> {
  final _searchController = TextEditingController();
  final _pagingController = PagingController<int, WsSet>(firstPageKey: 1);
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
      _pagingController.refresh();
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    final isSearching = _searchQuery.isNotEmpty;
    final client = GraphQLProvider.of(context).value;

    final options = QueryOptions(
      document: gql(isSearching ? searchWsSets : readWsSet),
      variables: {
        'pageNum': pageKey,
        'pageSize': _pageSize,
        if (isSearching) 'query': _searchQuery,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.query(options);

    if (!mounted) return;

    if (result.hasException) {
      _pagingController.error = result.exception.toString();
      return;
    }

    final List? fetched = result.data?[isSearching ? 'searchSets' : 'sets'];
    final items = (fetched ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WsSet.fromMap)
        .toList();

    if (items.length < _pageSize) {
      _pagingController.appendLastPage(items);
    } else {
      _pagingController.appendPage(items, pageKey + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        _onSearchChanged('');
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
          child: PagedGridView<int, WsSet>(
            pagingController: _pagingController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 280,
            ),
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: (context, set, index) =>
                  RepaintBoundary(child: _SetCard(set: set)),
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Text(_pagingController.error.toString()),
              ),
              noItemsFoundIndicatorBuilder: (context) =>
                  const Center(child: Text('No sets found')),
            ),
          ),
        ),
      ],
    );
  }
}

class _SetCard extends StatelessWidget {
  final WsSet set;

  const _SetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    final backendUrl = const String.fromEnvironment('BACKEND_URL');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: set.imagePath != null
                ? Image.network(
                    '$backendUrl${set.imagePath}',
                    fit: BoxFit.contain,
                    cacheWidth: 400,
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
                  set.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  set.releaseDate,
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
