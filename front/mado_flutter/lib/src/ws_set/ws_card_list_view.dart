import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mado_flutter/src/ws_set/ws_card_models.dart';

const _pageSize = 20;

class WsCardListView extends StatefulWidget {
  final String setCode;

  const WsCardListView({
    super.key,
    required this.setCode,
  });

  @override
  State<WsCardListView> createState() => _WsCardListViewState();
}

class _WsCardListViewState extends State<WsCardListView> {
  final _pagingController = PagingController<int, WsCard>(firstPageKey: 1);
  final _searchController = TextEditingController();
  bool _baseOnly = true;
  bool _readMode = false;
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
    final result = await client.query(QueryOptions(
      document: gql(isSearching ? searchWsCards : readWsCards),
      variables: {
        'setCode': widget.setCode,
        'pageNum': pageKey,
        'pageSize': _pageSize,
        'baseOnly': _baseOnly,
        if (isSearching) 'query': _searchQuery,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    ));

    if (!mounted) return;

    if (result.hasException) {
      _pagingController.error = result.exception.toString();
      return;
    }

    final List? fetched = result.data?[isSearching ? 'searchCards' : 'cards'];
    final items = (fetched ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WsCard.fromMap)
        .toList();

    if (items.length < _pageSize) {
      _pagingController.appendLastPage(items);
    } else {
      _pagingController.appendPage(items, pageKey + 1);
    }
  }

  void _showCardZoom(BuildContext context, WsCard card) {
    final backendUrl = const String.fromEnvironment('BACKEND_URL');
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: card.imagePath != null
                ? card.isCx
                    ? RotatedBox(
                        quarterTurns: 1,
                        child: Image.network(
                          '$backendUrl${card.imagePath}',
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.network(
                        '$backendUrl${card.imagePath}',
                        fit: BoxFit.contain,
                      )
                : const _FallbackImage(),
          ),
        ),
      ),
    );
  }

  void _toggleBaseOnly() {
    setState(() => _baseOnly = !_baseOnly);
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search cards…',
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
              const SizedBox(height: 4),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Base'),
                    selected: _baseOnly,
                    onSelected: (_) => _toggleBaseOnly(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_readMode ? Icons.grid_on : Icons.view_agenda),
                    tooltip: _readMode ? 'Explore' : 'Read',
                    onPressed: () => setState(() => _readMode = !_readMode),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final readColumns = constraints.maxWidth < 600 ? 2 : 3;
              return PagedGridView<int, WsCard>(
                pagingController: _pagingController,
                padding: const EdgeInsets.all(8),
                gridDelegate: _readMode
                    ? SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: readColumns,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 0.7,
                      )
                    : const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 0.7,
                      ),
                builderDelegate: PagedChildBuilderDelegate(
                  itemBuilder: (context, card, index) => RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(
                        '/set/${widget.setCode}/card/${Uri.encodeComponent(card.idCard)}',
                      ),
                      onLongPress: () => _showCardZoom(context, card),
                      child: _CardTile(card: card),
                    ),
                  ),
                  firstPageErrorIndicatorBuilder: (context) => Center(
                    child: Text(_pagingController.error.toString()),
                  ),
                  noItemsFoundIndicatorBuilder: (context) =>
                      const Center(child: Text('No cards found')),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final WsCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final backendUrl = const String.fromEnvironment('BACKEND_URL');

    Widget image = card.imagePath != null
        ? Image.network(
            '$backendUrl${card.imagePath}',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FallbackImage(),
          )
        : const _FallbackImage();

    if (card.isCx) {
      image = RotatedBox(quarterTurns: 1, child: image);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: image,
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
    );
  }
}
