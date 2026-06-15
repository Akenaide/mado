class WsCard {
  final String idCard;
  final String setCode;
  final String? imagePath;
  final String cardType;

  const WsCard({
    required this.idCard,
    required this.setCode,
    this.imagePath,
    this.cardType = '',
  });

  bool get isCx => cardType == 'CX';

  factory WsCard.fromMap(Map<String, dynamic> m) => WsCard(
        idCard: m['idCard'] as String? ?? '',
        setCode: m['setCode'] as String? ?? '',
        imagePath: m['imagePath'] as String?,
        cardType: m['cardType'] as String? ?? '',
      );
}

const readWsCards = """
query GetCards(\$setCode: String!, \$pageNum: Int, \$pageSize: Int) {
  cards(setCode: \$setCode, pageNum: \$pageNum, pageSize: \$pageSize) {
    idCard
    setCode
    imagePath
    cardType
  }
}
""";
