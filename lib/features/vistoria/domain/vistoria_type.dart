import 'package:flutter/material.dart';

enum TipoVistoria {
  cautelarCarro,
  cautelarCaminhao,
  carroComCroqui,
  vistoriaEntrada,
  checklistPesado,
  checklistPasseio;

  String get titulo {
    switch (this) {
      case TipoVistoria.cautelarCarro:
        return 'Vistoria Lojista';
      case TipoVistoria.cautelarCaminhao:
        return 'Vistoria Cautelar Caminhão';
      case TipoVistoria.carroComCroqui:
        return 'Vistoria Cautelar Croqui + Avarias';
      case TipoVistoria.vistoriaEntrada:
        return 'Vistoria de Entrada';
      case TipoVistoria.checklistPesado:
        return 'Vistoria de Entrada Caminhão';
      case TipoVistoria.checklistPasseio:
        return 'Vistoria de Entrada Passeio';
    }
  }

  String get descricao {
    switch (this) {
      case TipoVistoria.cautelarCarro:
        return 'Inspeção completa para veículos de passeio';
      case TipoVistoria.cautelarCaminhao:
        return 'Inspeção completa para caminhões e veículos pesados';
      case TipoVistoria.carroComCroqui:
        return 'Vistoria com mapeamento detalhado de danos e croqui';
      case TipoVistoria.vistoriaEntrada:
        return 'Checklist visual de recebimento do veículo na loja';
      case TipoVistoria.checklistPesado:
        return 'Vistoria de Entrada para Caminhões e Ônibus';
      case TipoVistoria.checklistPasseio:
        return 'Vistoria de Entrada para Caminhonetes e Carros';
    }
  }

  IconData get icone {
    switch (this) {
      case TipoVistoria.cautelarCarro:
        return Icons.directions_car_rounded;
      case TipoVistoria.cautelarCaminhao:
        return Icons.local_shipping_rounded;
      case TipoVistoria.carroComCroqui:
        return Icons.car_repair_rounded;
      case TipoVistoria.vistoriaEntrada:
        return Icons.fact_check_rounded;
      case TipoVistoria.checklistPesado:
        return Icons.local_shipping_rounded;
      case TipoVistoria.checklistPasseio:
        return Icons.directions_car_rounded;
    }
  }

  String get slug {
    switch (this) {
      case TipoVistoria.cautelarCarro:
        return 'cautelar-carro';
      case TipoVistoria.cautelarCaminhao:
        return 'cautelar-caminhao';
      case TipoVistoria.carroComCroqui:
        return 'carro-croqui';
      case TipoVistoria.vistoriaEntrada:
        return 'vistoria-entrada';
      case TipoVistoria.checklistPesado:
        return 'checklist-pesado';
      case TipoVistoria.checklistPasseio:
        return 'checklist-passeio';
    }
  }

  static TipoVistoria fromSlug(String slug) {
    return TipoVistoria.values.firstWhere(
      (t) => t.slug == slug,
      orElse: () => TipoVistoria.cautelarCarro,
    );
  }

  static TipoVistoria fromString(String val) {
    final lower = val.toLowerCase();
    if (lower.contains('caminhão') || lower.contains('caminhao') || lower.contains('pesado')) {
      if (lower.contains('entrada') || lower.contains('checklist')) return TipoVistoria.checklistPesado;
      return TipoVistoria.cautelarCaminhao;
    }
    if (lower.contains('passeio') && (lower.contains('entrada') || lower.contains('checklist'))) {
      return TipoVistoria.checklistPasseio;
    }
    if (lower.contains('entrada')) return TipoVistoria.vistoriaEntrada;
    if (lower.contains('checklist')) return TipoVistoria.checklistPasseio;
    if (lower.contains('avaria') || lower.contains('pintura') || lower.contains('croqui')) return TipoVistoria.carroComCroqui;
    return TipoVistoria.cautelarCarro; // default fallback
  }
}

