class CategoryStat {
  final String name;
  final int count;

  const CategoryStat({required this.name, required this.count});

  factory CategoryStat.fromMap(Map<String, dynamic> m) => CategoryStat(
        name: m['name'] as String? ?? '',
        count: m['count'] as int? ?? 0,
      );
}

class WsSetStats {
  final int total;
  final List<CategoryStat> byProductType;

  const WsSetStats({required this.total, required this.byProductType});

  factory WsSetStats.fromMap(Map<String, dynamic> m) => WsSetStats(
        total: m['total'] as int? ?? 0,
        byProductType: (m['byProductType'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CategoryStat.fromMap)
            .toList(),
      );
}

const getSetStats = """
query GetSetStats(\$query: String) {
  setStats(query: \$query) {
    total
    byProductType { name count }
  }
}
""";

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
