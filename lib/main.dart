import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final List<String> types;
  final List<String> abilities;
  final String imageUrl;
  final List<PokemonStat> stats;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.types,
    required this.abilities,
    required this.imageUrl,
    required this.stats,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .toList(),
      abilities: (json['abilities'] as List)
          .map((a) => a['ability']['name'] as String)
          .toList(),
      imageUrl: json['sprites']['front_default'] as String,
      stats: (json['stats'] as List)
          .map((s) => PokemonStat.fromJson(s))
          .toList(),
    );
  }
}

class PokemonStat {
  final String name;
  final int baseStat;

  PokemonStat({
    required this.name,
    required this.baseStat,
  });

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['stat']['name'] as String,
      baseStat: json['base_stat'] as int,
    );
    }
}

Future<Pokemon> fetchPokemon(String name) async {
  final cleanedName = name.trim().toLowerCase();
  final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$cleanedName');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Pokemon.fromJson(data);
  } else if (response.statusCode == 404) {
    throw Exception('Pokémon no encontrado');
  } else {
    throw Exception('Error al consultar la API (código: ${response.statusCode})');
  }
}

/// App principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex Simple',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PokemonSearchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PokemonSearchPage extends StatefulWidget {
  const PokemonSearchPage({super.key});

  @override
  State<PokemonSearchPage> createState() => _PokemonSearchPageState();
}

class _PokemonSearchPageState extends State<PokemonSearchPage> {
  final TextEditingController _controller = TextEditingController(text: 'ditto');
  Pokemon? _pokemon;
  bool _isLoading = false;
  String? _error;

  Future<void> _searchPokemon() async {
    final name = _controller.text;
    if (name.trim().isEmpty) {
      setState(() {
        _error = 'Ingresa el nombre de un Pokémon';
        _pokemon = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _pokemon = null;
    });

    try {
      final pokemon = await fetchPokemon(name);
      setState(() {
        _pokemon = pokemon;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (pokemon.imageUrl.isNotEmpty)
                  Image.network(
                    pokemon.imageUrl,
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pokemon.name.toUpperCase()} (#${pokemon.id})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Altura: ${pokemon.height}'),
                      Text('Peso: ${pokemon.weight}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Tipos:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: pokemon.types
                  .map((t) => Chip(label: Text(t)))
                  .toList(),
            ),
            const SizedBox(height: 12),

            Text(
              'Habilidades:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: pokemon.abilities
                  .map((a) => Chip(label: Text(a)))
                  .toList(),
            ),
            const SizedBox(height: 12),

            Text(
              'Estadísticas base:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: pokemon.stats
                  .map(
                    (s) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(s.name)),
                        Text(s.baseStat.toString()),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex - PokeAPI'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nombre del Pokémon (ej: ditto, pikachu)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                  },
                ),
              ),
              onSubmitted: (_) => _searchPokemon(),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchPokemon,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ] else if (_pokemon != null) ...[
              Expanded(child: SingleChildScrollView(child: _buildPokemonCard(_pokemon!))),
            ] else ...[
              const SizedBox(height: 16),
              const Text('Ingresa un nombre y presiona Buscar.'),
            ],
          ],
        ),
      ),
    );
  }
}
