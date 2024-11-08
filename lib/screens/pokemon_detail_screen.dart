import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonDetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name.toUpperCase()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'pokemon-${pokemon.id}',
              child: Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '#${pokemon.id.toString().padLeft(3, '0')}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: pokemon.types
                  .map((type) => Card(
                        color: _getTypeColor(type),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            type.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            _buildStatsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTable() {
    return Table(
      children: [
        _buildTableRow('Altura', '${pokemon.height / 10} m'),
        _buildTableRow('Peso', '${pokemon.weight / 10} kg'),
        ...pokemon.stats.entries.map(
          (stat) => _buildTableRow(
            _formatStatName(stat.key),
            stat.value.toString(),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value),
        ),
      ],
    );
  }

  String _formatStatName(String statName) {
    return statName
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getTypeColor(String type) {
    final colors = {
      'normal': Colors.brown.shade400,
      'fire': Colors.red,
      'water': Colors.blue,
      'grass': Colors.green,
      'electric': Colors.amber,
      'ice': Colors.cyan,
      'fighting': Colors.orange.shade900,
      'poison': Colors.purple,
      'ground': Colors.brown,
      'flying': Colors.indigo,
      'psychic': Colors.pink,
      'bug': Colors.lightGreen,
      'rock': Colors.grey,
      'ghost': Colors.deepPurple,
      'dragon': Colors.indigo.shade900,
      'dark': Colors.grey.shade800,
      'steel': Colors.blueGrey,
      'fairy': Colors.pinkAccent,
    };
    return colors[type] ?? Colors.grey;
  }
}
