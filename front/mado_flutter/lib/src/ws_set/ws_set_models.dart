// Define the Set type based on your GraphQL schema
class WsSet {
  final String releaseDate;
  final String title;
  final String? imagePath;
  final String setCode;

  const WsSet({
    required this.releaseDate,
    required this.title,
    this.imagePath,
    required this.setCode,
  });

  factory WsSet.fromMap(Map<String, dynamic> m) => WsSet(
        releaseDate: m['releaseDate'] as String? ?? '',
        title: m['title'] as String? ?? '',
        imagePath: m['imagePath'] as String?,
        setCode: m['setCode'] as String? ?? '',
      );
}

const readWsSet = """
query GetSets(\$pageNum: Int, \$pageSize: Int) {
  sets(pageNum: \$pageNum, pageSize: \$pageSize) {
    releaseDate
    setCode
    title
    imagePath
  }
}
""";

const searchWsSets = """
query SearchSets(\$query: String!, \$pageNum: Int, \$pageSize: Int) {
  searchSets(query: \$query, pageNum: \$pageNum, pageSize: \$pageSize) {
    releaseDate
    setCode
    title
    imagePath
  }
}
""";
