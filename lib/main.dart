import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: PokemonGrid(),
    theme: ThemeData(
      primarySwatch: Colors.red,
    ),
  ));
}

class PokemonGrid extends StatefulWidget {
  @override
  _PokemonGridState createState() => _PokemonGridState();
}

class _PokemonGridState extends State<PokemonGrid> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> pokemons = [];
  bool isLoading = false;
  int currentPage = 0;
  final int itemsPerPage = 50;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredPokemons = [];
  List<String> selectedTypes = [];
  Map<String, dynamic> pokemonDetails = {};
  final List<String> pokemonTypes = [
    'normal',
    'lucha',
    'volador',
    'veneno',
    'tierra',
    'roca',
    'bicho',
    'fantasma',
    'acero',
    'fuego',
    'agua',
    'planta',
    'eléctrico',
    'psíquico',
    'hielo',
    'dragón',
    'siniestro',
    'hada'
  ];

  @override
  void initState() {
    super.initState();
    _loadMorePokemons();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_filterPokemons);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePokemons();
    }
  }

  Future<void> _loadMorePokemons() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://pokeapi.co/api/v2/pokemon?offset=${currentPage * itemsPerPage}&limit=$itemsPerPage'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newPokemons = data['results'] as List;

        setState(() {
          pokemons.addAll(newPokemons);
          filteredPokemons = pokemons;
          currentPage++;
          isLoading = false;
        });

        // Cargar detalles de cada nuevo Pokémon
        for (int i = 0; i < newPokemons.length; i++) {
          final index = (currentPage - 1) * itemsPerPage + i;
          await _loadPokemonDetails(newPokemons[i]['url'], index);
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPokemonDetails(String url, int index) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pokemonDetails[index.toString()] = data;
          _filterPokemons();
        });
      }
    } catch (e) {
      print('Error loading pokemon details: $e');
    }
  }

  void _showPokemonDetails(BuildContext context, String pokemonName) {
    final pokemon = pokemons.firstWhere((p) => p['name'] == pokemonName);
    final index = pokemons.indexOf(pokemon);
    final details = pokemonDetails[index.toString()];

    if (details == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No se pudieron cargar los detalles'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(pokemonName.toUpperCase()),
            Text('#${(index + 1).toString().padLeft(3, '0')}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      details['sprites']['front_default'],
                      height: 100,
                    ),
                    Image.network(
                      details['sprites']['back_default'] ??
                          details['sprites']['front_default'],
                      height: 100,
                    ),
                  ],
                ),
              ),
              Divider(),
              Text('Características:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Altura: ${details['height'] / 10} m'),
              Text('Peso: ${details['weight'] / 10} kg'),
              Text('Experiencia base: ${details['base_experience']} XP'),
              SizedBox(height: 10),
              Text('Tipos:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 4,
                children: (details['types'] as List)
                    .map((type) => Chip(
                          label: Text(
                            type['type']['name'].toString().toUpperCase(),
                          ),
                          backgroundColor:
                              _getTypeColor(type['type']['name'].toString()),
                        ))
                    .toList(),
              ),
              SizedBox(height: 10),
              Text('Habilidades:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (details['abilities'] as List).map((ability) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${ability['ability']['name'].toString().toUpperCase()}'
                      '${ability['is_hidden'] ? ' (Oculta)' : ''}',
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Text('Estadísticas base:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: (details['stats'] as List).map((stat) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(stat['stat']['name'].toString().toUpperCase()),
                      Text(stat['base_stat'].toString()),
                    ],
                  );
                }).toList(),
              ),
              if (details['moves'] != null) ...[
                SizedBox(height: 10),
                Text('Movimientos principales:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: (details['moves'] as List).take(5).map((move) {
                    return Chip(
                      label: Text(
                        move['move']['name'].toString().toUpperCase(),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _filterPokemons() {
    setState(() {
      List<dynamic> typeFiltered = pokemons;

      // Filtrar por tipos seleccionados
      if (selectedTypes.isNotEmpty) {
        typeFiltered = pokemons.where((pokemon) {
          final index = pokemons.indexOf(pokemon);
          final details = pokemonDetails[index.toString()];
          if (details == null) return false;

          final pokemonTypes = (details['types'] as List)
              .map((type) =>
                  _translateTypeToSpanish(type['type']['name'].toString()))
              .toList();

          return selectedTypes
              .every((selectedType) => pokemonTypes.contains(selectedType));
        }).toList();
      }

      // Filtrar por texto de búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        typeFiltered = typeFiltered
            .where((pokemon) =>
                pokemon['name'].toString().toLowerCase().contains(searchTerm))
            .toList();
      }

      filteredPokemons = typeFiltered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pokédex',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize:
              Size.fromHeight(110), // Aumentado para acomodar el buscador
          child: Column(
            children: [
              // Buscador
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar Pokémon...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              // Filtros de tipo
              Container(
                height: 50,
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: pokemonTypes.map((type) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selectedTypes.contains(type)
                                ? Colors.white
                                : _getTypeColor(type),
                          ),
                        ),
                        selected: selectedTypes.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedTypes.add(type);
                            } else {
                              selectedTypes.remove(type);
                            }
                            _filterPokemons();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: _getTypeColor(type),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _getTypeColor(type),
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        labelPadding: EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Contador de resultados
              if (selectedTypes.isNotEmpty || _searchController.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${filteredPokemons.length} Pokémon encontrados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: filteredPokemons.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredPokemons.length) {
            return isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                  )
                : SizedBox();
          }

          final pokemon = filteredPokemons[index];
          final pokemonId = pokemons.indexOf(pokemon) + 1;
          final details = pokemonDetails[index.toString()];

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              onTap: () => _showPokemonDetails(context, pokemon['name']),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Imagen del Pokémon
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Image.network(
                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png',
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.catching_pokemon,
                            color: Colors.grey[300]),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Información del Pokémon
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pokemon['name'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '#${pokemonId.toString().padLeft(3, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (details != null) ...[
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: (details['types'] as List).map((type) {
                                String spanishType = _translateTypeToSpanish(
                                    type['type']['name'].toString());
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(spanishType)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    spanishType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getTypeColor(spanishType),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    final typeColors = {
      'normal': Colors.grey[400],
      'lucha': Colors.red[700],
      'volador': Colors.indigo[200],
      'veneno': Colors.purple,
      'tierra': Colors.brown[300],
      'roca': Colors.grey[700],
      'bicho': Colors.lightGreen,
      'fantasma': Colors.purple[700],
      'acero': Colors.blueGrey,
      'fuego': Colors.red,
      'agua': Colors.blue,
      'planta': Colors.green,
      'eléctrico': Colors.yellow[600],
      'psíquico': Colors.pink,
      'hielo': Colors.cyan,
      'dragón': Colors.indigo,
      'siniestro': Colors.grey[800],
      'hada': Colors.pink[200],
    };
    return typeColors[type] ?? Colors.grey;
  }

  String _translateTypeToSpanish(String englishType) {
    final translations = {
      'normal': 'normal',
      'fighting': 'lucha',
      'flying': 'volador',
      'poison': 'veneno',
      'ground': 'tierra',
      'rock': 'roca',
      'bug': 'bicho',
      'ghost': 'fantasma',
      'steel': 'acero',
      'fire': 'fuego',
      'water': 'agua',
      'grass': 'planta',
      'electric': 'eléctrico',
      'psychic': 'psíquico',
      'ice': 'hielo',
      'dragon': 'dragón',
      'dark': 'siniestro',
      'fairy': 'hada'
    };
    return translations[englishType] ?? englishType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
