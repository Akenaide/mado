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
  List<CategoryStat>? _allCategories;
  WsSetStats? _filteredStats;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allCategories == null) _fetchStats('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats(String query) async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getSetStats),
      variables: {'query': query},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted) return;
    final data = result.data?['setStats'];
    if (data == null) return;
    final stats = WsSetStats.fromMap(data as Map<String, dynamic>);
    setState(() {
      // Categories are product types defined by the game — fixed regardless of search.
      // Fetched once on init so all chips are always visible, even when a search yields 0 for some.
      if (query.isEmpty) _allCategories = stats.byProductType;
      _filteredStats = stats;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
      _pagingController.refresh();
      _fetchStats(trimmed);
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
        SetStatsBar(allCategories: _allCategories, filtered: _filteredStats),
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

class SetStatsBar extends StatelessWidget {
  final List<CategoryStat>? allCategories;
  final WsSetStats? filtered;

  const SetStatsBar(
      {super.key, required this.allCategories, required this.filtered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (allCategories == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    final filteredMap = {
      for (final c in filtered?.byProductType ?? []) c.name: c.count
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${filtered?.total ?? 0} products',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          ...allCategories!.map((cat) {
            final count = filteredMap[cat.name] ?? 0;
            final isZero = count == 0;
            return Chip(
              label: Text('${cat.name} $count'),
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color: isZero ? theme.disabledColor : null,
              ),
              backgroundColor:
                  isZero ? theme.disabledColor.withValues(alpha: 0.1) : null,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }),
        ],
      ),
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
