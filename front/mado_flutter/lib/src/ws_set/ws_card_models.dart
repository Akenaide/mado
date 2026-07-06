class WsCard {
  final String idCard;
  final String setCode;
  final String? imagePath;
  final String cardType;
  final String? name;
  final int? level;
  final int? cost;
  final int? power;
  final int? soul;
  final String? color;
  final List<String> triggers;
  final List<String> abilities;
  final List<String> specialAttribute;
  final String? flavourText;
  final List<String> relatedCards;

  const WsCard({
    required this.idCard,
    required this.setCode,
    this.imagePath,
    this.cardType = '',
    this.name,
    this.level,
    this.cost,
    this.power,
    this.soul,
    this.color,
    this.triggers = const [],
    this.abilities = const [],
    this.specialAttribute = const [],
    this.flavourText,
    this.relatedCards = const [],
  });

  bool get isCx => cardType == 'CX';

  factory WsCard.fromMap(Map<String, dynamic> m) => WsCard(
        idCard: m['idCard'] as String? ?? '',
        setCode: m['setCode'] as String? ?? '',
        imagePath: m['imagePath'] as String?,
        cardType: m['cardType'] as String? ?? '',
        name: m['name'] as String?,
        level: m['level'] as int?,
        cost: m['cost'] as int?,
        power: m['power'] as int?,
        soul: m['soul'] as int?,
        color: m['color'] as String?,
        triggers: (m['triggers'] as List?)?.cast<String>() ?? [],
        abilities: (m['abilities'] as List?)?.cast<String>() ?? [],
        specialAttribute:
            (m['specialAttribute'] as List?)?.cast<String>() ?? [],
        flavourText: m['flavourText'] as String?,
        relatedCards: (m['relatedCards'] as List?)?.cast<String>() ?? [],
      );
}

const readWsCards = """
query GetCards(\$setCode: String!, \$pageNum: Int, \$pageSize: Int, \$baseOnly: Boolean,
               \$levels: [Int!], \$cardTypes: [String!], \$costs: [Int!], \$triggers: [String!]) {
  cards(setCode: \$setCode, pageNum: \$pageNum, pageSize: \$pageSize, baseOnly: \$baseOnly,
        levels: \$levels, cardTypes: \$cardTypes, costs: \$costs, triggers: \$triggers) {
    idCard
    setCode
    imagePath
    cardType
  }
}
""";

const searchWsCards = """
query SearchCards(\$setCode: String!, \$query: String!, \$pageNum: Int, \$pageSize: Int, \$baseOnly: Boolean,
                  \$levels: [Int!], \$cardTypes: [String!], \$costs: [Int!], \$triggers: [String!]) {
  searchCards(setCode: \$setCode, query: \$query, pageNum: \$pageNum, pageSize: \$pageSize, baseOnly: \$baseOnly,
              levels: \$levels, cardTypes: \$cardTypes, costs: \$costs, triggers: \$triggers) {
    idCard
    setCode
    imagePath
    cardType
  }
}
""";

const getRelatedWsCards = """
query GetCardsByIds(\$idCards: [String!]!) {
  cardsByIds(idCards: \$idCards) {
    idCard
    setCode
    imagePath
    cardType
    name
  }
}
""";

const getWsCard = """
query GetCard(\$idCard: String!) {
  card(idCard: \$idCard) {
    idCard
    setCode
    imagePath
    cardType
    name
    level
    cost
    power
    soul
    color
    triggers
    abilities
    specialAttribute
    flavourText
    relatedCards
  }
}
""";
