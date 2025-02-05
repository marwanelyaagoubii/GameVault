import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  _CataloguePageState createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  // Liste des jeux vidéo
  List<Map<String, String>> games = [];

  // Contrôleurs pour les champs du formulaire
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  // Charger les jeux depuis SharedPreferences
  _loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedGames = prefs.getString('games');
    if (savedGames != null) {
      setState(() {
        games = List<Map<String, String>>.from(
          json.decode(savedGames).map((game) => Map<String, String>.from(game)),
        );
      });
    }
  }

  // Sauvegarder les jeux dans SharedPreferences
  _saveGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('games', json.encode(games));
  }

  // Fonction pour ajouter un jeu
  Future<void> _addGame() async {
    final title = _titleController.text;  // Titre du jeu
    final platform = _platformController.text;  // Plateforme du jeu

    if (title.isEmpty || platform.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    // Ajouter le jeu à la liste locale
    setState(() {
      games.add({"title": title, "platform": platform});
    });

    // Sauvegarder la liste mise à jour dans SharedPreferences
    _saveGames();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jeu ajouté avec succès')),
    );

    // Fermer le formulaire
    Navigator.pop(context);
  }

  // Afficher le formulaire d'ajout
  void _showAddGameForm() {
    _titleController.clear();
    _platformController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ajouter un jeu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Titre du jeu"),
              ),
              TextField(
                controller: _platformController,
                decoration: const InputDecoration(labelText: "Plateforme(s)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _addGame,  // Appel de la fonction d'ajout
              child: const Text("Ajouter"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Annuler
              },
              child: const Text("Annuler"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catalogue des jeux")),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(games[index]["title"]!),
            subtitle: Text("Plateforme: ${games[index]["platform"]}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  games.removeAt(index); // Supprimer le jeu
                });
                _saveGames(); // Sauvegarder après suppression
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGameForm, // Ouvrir le formulaire d'ajout
        child: const Icon(Icons.add),
      ),
    );
  }
}
