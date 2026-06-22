import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mado_flutter/src/ws_set/ws_card_models.dart';

class WsCardDetailView extends StatelessWidget {
  final WsCard card;
  final String setCode;

  const WsCardDetailView(
      {super.key, required this.card, required this.setCode});

  @override
  Widget build(BuildContext context) {
    final backendUrl = const String.fromEnvironment('BACKEND_URL');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/set/$setCode'),
        ),
        title: Text(card.name ?? card.idCard),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardImage(card: card, backendUrl: backendUrl),
                const SizedBox(width: 16),
                Expanded(child: _StatBlock(card: card)),
              ],
            ),
            if (card.abilities.isNotEmpty) ...[
              const Divider(height: 32),
              ..._abilityRows(card.abilities),
            ],
            if (card.flavourText != null && card.flavourText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                card.flavourText!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _abilityRows(List<String> abilities) => abilities
      .map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectableText(a.replaceAll('<br>', '\n')),
          ))
      .toList();
}

class _CardImage extends StatelessWidget {
  final WsCard card;
  final String backendUrl;

  const _CardImage({required this.card, required this.backendUrl});

  @override
  Widget build(BuildContext context) {
    Widget image = card.imagePath != null
        ? Image.network(
            '$backendUrl${card.imagePath}',
            width: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _FallbackImage(),
          )
        : const _FallbackImage();

    if (card.isCx) {
      image = RotatedBox(quarterTurns: 1, child: image);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: image,
    );
  }
}

class _StatBlock extends StatelessWidget {
  final WsCard card;

  const _StatBlock({required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          card.name ?? card.idCard,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Lv.${card.level ?? "-"} · Cost ${card.cost ?? "-"} '
          '· Power ${card.power ?? "-"} · Soul ${card.soul ?? "-"}',
        ),
        const SizedBox(height: 4),
        Text('${card.color ?? "-"} · ${card.cardType}'),
        if (card.triggers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Trigger: ${card.triggers.join(", ")}'),
        ],
        if (card.specialAttribute.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Trait: ${card.specialAttribute.join(" / ")}'),
        ],
      ],
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) => Container(
        width: 120,
        height: 168,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
      );
}

/// Route that fetches a single card then shows [WsCardDetailView].
class WsCardDetailRoute extends StatefulWidget {
  final String idCard;
  final String setCode;

  const WsCardDetailRoute({
    super.key,
    required this.idCard,
    required this.setCode,
  });

  @override
  State<WsCardDetailRoute> createState() => _WsCardDetailRouteState();
}

class _WsCardDetailRouteState extends State<WsCardDetailRoute> {
  WsCard? _card;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_card == null && _error == null) _fetch();
  }

  Future<void> _fetch() async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(
      document: gql(getWsCard),
      variables: {'idCard': widget.idCard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted) return;
    if (result.hasException) {
      setState(() => _error = result.exception.toString());
      return;
    }
    final data = result.data?['card'] as Map<String, dynamic>?;
    if (data == null) {
      setState(() => _error = 'Card not found');
      return;
    }
    setState(() => _card = WsCard.fromMap(data));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed('/set/${widget.setCode}'),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }
    if (_card == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed('/set/${widget.setCode}'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return WsCardDetailView(card: _card!, setCode: widget.setCode);
  }
}
