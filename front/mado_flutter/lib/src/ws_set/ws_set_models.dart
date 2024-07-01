// Define the Set type based on your GraphQL schema
class WsSet {
  final String releaseDate;
  final String title;
  final String imageUrl;
  final String setCode;

  WsSet({
    required this.releaseDate,
    required this.title,
    required this.imageUrl,
    required this.setCode,
  });
}

const readWsSet = """
query {
  sets {
    releaseDate
    setCode
    title
    imageUrl
  }
}
""";
