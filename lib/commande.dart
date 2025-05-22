import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  List<dynamic> commandes = [];
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  Future<void> _loadCommandes() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/commandes'));
    if (response.statusCode == 200) {
      setState(() {
        commandes = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      print('Erreur : ${response.statusCode}');
    }
  }

  Future<void> _updateCommandeStatut(int id, int etat) async {
    setState(() => isUpdating = true);

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/commandes/$id/statut'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'etat': etat}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commande $id mise à jour.')));
      await _loadCommandes();
    } else {
      print('Erreur update : ${response.body}');
    }

    setState(() => isUpdating = false);
  }

  String _formatDateSimple(String dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Date inconnue';
    try {
      final parts = dateStr.split('T');
      final datePart = parts[0];
      final timePart = parts.length > 1 ? parts[1].split('.')[0] : '00:00:00';
      return '$datePart $timePart';
    } catch (_) {
      return 'Date invalide';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Gestion des Commandes", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4B0082)))
              : commandes.isEmpty
                  ? const Center(child: Text("Aucune commande en attente.", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: commandes.length,
                      itemBuilder: (context, index) {
                        final cmd = commandes[index];
final montant = double.tryParse(cmd['montant'].toString()) ?? 0.0;
                        final etat = cmd['etat'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Commande #${cmd['id']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Date : ${_formatDateSimple(cmd['date'] ?? '')}', style: const TextStyle(color: Colors.white70)),
                              Text('Montant : ${montant.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => _updateCommandeStatut(cmd['id'], 2),
                                    child: const Text('Expédier'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => _updateCommandeStatut(cmd['id'], 3),
                                    child: const Text('Annuler'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
          if (isUpdating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4B0082)),
              ),
            ),
        ],
      ),
    );
  }
}
