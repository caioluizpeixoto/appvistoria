import 'package:flutter/material.dart';

class FotosScreen extends StatelessWidget {
  final String vistoriaId;
  const FotosScreen({super.key, required this.vistoriaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos')),
      body: Center(child: Text('Fotos — Vistoria: $vistoriaId')),
    );
  }
}
