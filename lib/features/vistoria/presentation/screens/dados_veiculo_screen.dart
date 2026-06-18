import 'package:flutter/material.dart';

class DadosVeiculoScreen extends StatefulWidget {
  const DadosVeiculoScreen({super.key});

  @override
  State<DadosVeiculoScreen> createState() => _DadosVeiculoScreenState();
}

class _DadosVeiculoScreenState extends State<DadosVeiculoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados do Veículo')),
      body: const Center(
        child: Text('Em construção — Fase 4'),
      ),
    );
  }
}
