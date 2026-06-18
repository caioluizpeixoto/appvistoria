import 'package:flutter/material.dart';

enum TipoVistoria {
  cautelarCarro,
  cautelarCaminhao,
  carroComCroqui;

  String get titulo {
    switch (this) {
      case TipoVistoria.cautelarCarro:
        return 'Vistoria Croqui + Avarias';
      case TipoVistoria.cautelarCaminhao:
        return 'Caminhão';
      case TipoVistoria.carroComCroqui:
        return 'Vistoria Croqui';
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
    }
  }

  IconData get icone {
    switch (this) {
      case TipoVistoria.cautelarCarro:
        return Icons.directions_car_rounded;
      case TipoVistoria.cautelarCaminhao:
        return Icons.local_shipping_rounded;
      case TipoVistoria.carroComCroqui:
        return Icons.account_tree_rounded;
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
    }
  }

  static TipoVistoria fromSlug(String slug) {
    return TipoVistoria.values.firstWhere(
      (t) => t.slug == slug,
      orElse: () => TipoVistoria.cautelarCarro,
    );
  }
}
