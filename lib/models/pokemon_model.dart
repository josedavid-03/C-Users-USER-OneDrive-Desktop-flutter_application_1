class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final int height;
  final int weight;
  final Map<String, int> stats;

  Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.height,
    required this.weight,
    required this.stats,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    List<String> typesList = (json['types'] as List)
        .map((type) => type['type']['name'] as String)
        .toList();

    Map<String, int> statsMap = {};
    for (var stat in json['stats']) {
      statsMap[stat['stat']['name']] = stat['base_stat'];
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      types: typesList,
      height: json['height'],
      weight: json['weight'],
      stats: statsMap,
    );
  }
}
