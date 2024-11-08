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
}
