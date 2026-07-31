import 'package:flutter/material.dart';

enum TipoVistoria {
  cautelarCarro,
  cautelarCaminhao,
  carroComCroqui,
  vistoriaEntrada;

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
    if (lower.contains('entrada')) return TipoVistoria.vistoriaEntrada;
    if (lower.contains('caminh')) return TipoVistoria.cautelarCaminhao;
    if (lower.contains('avaria') || lower.contains('pintura')) return TipoVistoria.carroComCroqui;
    return TipoVistoria.cautelarCarro; // default fallback
  }
}

