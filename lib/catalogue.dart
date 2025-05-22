import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  List<Map<String, String>> allGames = [];
  List<Map<String, String>> games = [];
  bool isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _plateformeController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _quantitesController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    const String apiUrl = 'http://10.0.2.2:3000/jeux';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          allGames = data.map<Map<String, String>>((jeu) {
            return {
              "id": jeu["id"].toString(),
              "titre": jeu["titre"],
              "plateforme": jeu["plateforme"],
              "prix": jeu["prix"].toString(),
              "quantites": jeu["quantites"]?.toString() ?? '0',
              "genre": jeu["genre"] ?? '',
              "image": jeu["image"] ?? '',
            };
          }).toList();
          games = List.from(allGames);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur : $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _addGame() async {
    final titre = _titreController.text.trim();
    final plateforme = _plateformeController.text.trim();
    final prix = double.tryParse(_prixController.text.trim().replaceAll(',', '.'));
    final quantites = int.tryParse(_quantitesController.text.trim());
    final genre = _genreController.text.trim();
    final image = _imageController.text.trim();

    if (titre.isEmpty || plateforme.isEmpty || prix == null || quantites == null || genre.isEmpty || image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/ajouterJeu'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titre': titre,
        'plateforme': plateforme,
        'prix': prix,
        'quantites': quantites,
        'genre': genre,
        'image': image,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      _loadGames();
    }
  }

  Future<void> _updateGame(int index) async {
    final jeu = games[index];
    final id = int.tryParse(jeu["id"]!);
    final titre = _titreController.text.trim();
    final plateforme = _plateformeController.text.trim();
    final prix = double.tryParse(_prixController.text.trim().replaceAll(',', '.'));
    final quantites = int.tryParse(_quantitesController.text.trim());
    final genre = _genreController.text.trim();
    final image = _imageController.text.trim();

    if (id == null || titre.isEmpty || plateforme.isEmpty || prix == null || quantites == null || genre.isEmpty || image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Champs invalides.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/updateJeu'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'titre': titre,
        'plateforme': plateforme,
        'prix': prix,
        'quantites': quantites,
        'genre': genre,
        'image': image,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      _loadGames();
    }
  }

  Future<void> _deleteGame(int id) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/suppJeu'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode == 200) {
      _loadGames();
    }
  }

  void _showAddGameForm() {
    _titreController.clear();
    _plateformeController.clear();
    _prixController.clear();
    _quantitesController.clear();
    _genreController.clear();
    _imageController.clear();

    _showGameDialog("Ajouter un jeu", _addGame);
  }

  void _showEditGameForm(int index) {
    final jeu = games[index];
    _titreController.text = jeu["titre"]!;
    _plateformeController.text = jeu["plateforme"]!;
    _prixController.text = jeu["prix"]!;
    _quantitesController.text = jeu["quantites"]!;
    _genreController.text = jeu["genre"] ?? '';
    _imageController.text = jeu["image"] ?? '';

    _showGameDialog("Modifier un jeu", () => _updateGame(index));
  }

  void _showDeleteConfirmationDialog(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Êtes-vous sûr de vouloir supprimer ce jeu ?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Cette action est irréversible.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGame(id);
              },
              child: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showGameDialog(String title, VoidCallback onSave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_titreController, "Titre"),
              _buildTextField(_plateformeController, "Plateforme"),
              _buildTextField(_prixController, "Prix", isNumber: true),
              _buildTextField(_quantitesController, "Quantité", isNumber: true),
              _buildTextField(_genreController, "Genre"),
              _buildTextField(_imageController, "URL de l'image"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: onSave, child: const Text("Enregistrer", style: TextStyle(color: Color(0xFF4B0082)))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Catalogue des jeux", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Rechercher un jeu",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF333333),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4B0082)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => _searchProduct(),
            ),
          ),
          isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF4B0082))))
              : games.isEmpty
                  ? const Expanded(child: Center(child: Text("Aucun jeu trouvé.", style: TextStyle(color: Colors.white70))))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final jeu = games[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                jeu["image"] != null && jeu["image"]!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          jeu["image"]!,
                                          width: 85,
                                          height: 125,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(jeu["titre"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text("Prix: ${jeu["prix"]} €", style: const TextStyle(color: Colors.white70)),
                                      Text("Plateforme: ${jeu["plateforme"]}", style: const TextStyle(color: Colors.white70)),
                                      Text("Qté: ${jeu["quantites"]}", style: const TextStyle(color: Colors.white70)),
                                      Text("Genre: ${jeu["genre"]}", style: const TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF4B0082)),
                                      onPressed: () => _showEditGameForm(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () {
                                        final id = int.tryParse(jeu["id"]!);
                                        if (id != null) {
                                          _showDeleteConfirmationDialog(id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGameForm,
        backgroundColor: const Color(0xFF4B0082),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _searchProduct() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        games = List.from(allGames);
      } else {
        games = allGames.where((game) =>
          game['titre']!.toLowerCase().contains(query) ||
          game['plateforme']!.toLowerCase().contains(query) ||
          game['genre']!.toLowerCase().contains(query)
        ).toList();
      }
    });
  }
}
