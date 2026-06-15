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
  bool _baseOnly = true;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(readWsCards),
      variables: {
        'setCode': widget.setCode,
        'pageNum': pageKey,
        'pageSize': _pageSize,
        'baseOnly': _baseOnly,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    ));

    if (!mounted) return;

    if (result.hasException) {
      _pagingController.error = result.exception.toString();
      return;
    }

    final List? fetched = result.data?['cards'];
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Base'),
              selected: _baseOnly,
              onSelected: (_) => _toggleBaseOnly(),
            ),
          ),
        ),
        Expanded(
          child: PagedGridView<int, WsCard>(
            pagingController: _pagingController,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.7,
            ),
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: (context, card, index) => RepaintBoundary(
                child: GestureDetector(
                  onTap: () => _showCardZoom(context, card),
                  child: _CardTile(card: card),
                ),
              ),
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Text(_pagingController.error.toString()),
              ),
              noItemsFoundIndicatorBuilder: (context) =>
                  const Center(child: Text('No cards found')),
            ),
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
