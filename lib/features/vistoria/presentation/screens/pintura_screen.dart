import 'package:flutter/material.dart';

class PinturaScreen extends StatelessWidget {
  final String vistoriaId;
  const PinturaScreen({super.key, required this.vistoriaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Pintura')),
      body: Center(child: Text('Pintura — Vistoria: $vistoriaId')),
    );
  }
}
