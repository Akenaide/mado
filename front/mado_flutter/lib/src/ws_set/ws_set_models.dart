// Define the Set type based on your GraphQL schema
class WsSet {
  final String releaseDate;
  final String title;
  final String imagePath;
  final String setCode;

  WsSet({
    required this.releaseDate,
    required this.title,
    required this.imagePath,
    required this.setCode,
  });
}

const readWsSet = """
query {
  sets {
    releaseDate
    setCode
    title
    imagePath
  }
}
""";

const searchWsSets = """
query SearchSets(\$query: String!) {
  searchSets(query: \$query) {
    releaseDate
    setCode
    title
    imagePath
  }
}
""";
