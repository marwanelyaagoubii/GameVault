import 'package:flutter/material.dart';

class CommandesPage extends StatelessWidget {
  const CommandesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commandes")),
      body: const Center(
        child: Text('Bienvenue dans la gestion des commandes !'),
      ),
    );
  }
}
