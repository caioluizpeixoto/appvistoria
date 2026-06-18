/// Itens de inspeção pré-definidos por tipo de veículo e categoria.
class AppConstants {
  AppConstants._();

  static const List<ItemTemplate> itensAutomovel = [
    // ── Identificação ────────────────────────────────────────────────────────
    ItemTemplate(categoria: 'identificacao', nome: 'CRLV', ordem: 1),
    ItemTemplate(categoria: 'identificacao', nome: 'Placa e lacre', ordem: 2),
    ItemTemplate(
        categoria: 'identificacao', nome: 'Gravação do chassi', ordem: 3),
    ItemTemplate(
        categoria: 'identificacao', nome: 'Gravação do motor', ordem: 4),
    ItemTemplate(
        categoria: 'identificacao', nome: 'KM / Hodômetro', ordem: 5),
    ItemTemplate(
        categoria: 'identificacao',
        nome: 'Etiqueta de identificação',
        ordem: 6),
    ItemTemplate(
        categoria: 'identificacao', nome: 'Cinto de segurança', ordem: 7),
    // ── Vidros ───────────────────────────────────────────────────────────────
    ItemTemplate(
        categoria: 'vidros', nome: 'Gravação vidro frontal', ordem: 1),
    ItemTemplate(
        categoria: 'vidros', nome: 'Gravação vidro traseiro', ordem: 2),
    ItemTemplate(
        categoria: 'vidros',
        nome: 'Gravação vidro lateral direito dianteiro',
        ordem: 3),
    ItemTemplate(
        categoria: 'vidros',
        nome: 'Gravação vidro lateral esquerdo dianteiro',
        ordem: 4),
    ItemTemplate(
        categoria: 'vidros',
        nome: 'Gravação vidro lateral direito traseiro',
        ordem: 5),
    ItemTemplate(
        categoria: 'vidros',
        nome: 'Gravação vidro lateral esquerdo traseiro',
        ordem: 6),
    // ── Estrutura ────────────────────────────────────────────────────────────
    ItemTemplate(
        categoria: 'estrutura',
        nome: 'Longarina dianteira direita',
        ordem: 1),
    ItemTemplate(
        categoria: 'estrutura',
        nome: 'Longarina dianteira esquerda',
        ordem: 2),
    ItemTemplate(
        categoria: 'estrutura',
        nome: 'Longarina centro direita',
        ordem: 3),
    ItemTemplate(
        categoria: 'estrutura',
        nome: 'Longarina centro esquerda',
        ordem: 4),
    ItemTemplate(
        categoria: 'estrutura',
        nome: 'Longarina traseira direita',
        ordem: 5),
    ItemTemplate(
        categoria: 'estrutura',
        nome: 'Longarina traseira esquerda',
        ordem: 6),
    ItemTemplate(
        categoria: 'estrutura', nome: 'Painel dianteiro', ordem: 7),
    ItemTemplate(
        categoria: 'estrutura', nome: 'Painel traseiro', ordem: 8),
    ItemTemplate(categoria: 'estrutura', nome: 'Teto', ordem: 9),
    ItemTemplate(categoria: 'estrutura', nome: 'Assoalho', ordem: 10),
    // ── Extras ───────────────────────────────────────────────────────────────
    ItemTemplate(
        categoria: 'extras',
        nome: 'Painel de instrumentos',
        ordem: 1),
    ItemTemplate(
        categoria: 'extras', nome: 'Frente esquerda 45°', ordem: 2),
    ItemTemplate(
        categoria: 'extras', nome: 'Traseira 45°', ordem: 3),
  ];

  static const List<ItemTemplate> itensCaminhao = [
    ...itensAutomovel,
    ItemTemplate(
        categoria: 'extras', nome: 'Painel corta-fogo', ordem: 10),
    ItemTemplate(
        categoria: 'extras', nome: 'Plaqueta da cabine', ordem: 11),
    ItemTemplate(
        categoria: 'vidros',
        nome: 'Para-brisa (original/não original)',
        ordem: 10),
    ItemTemplate(
        categoria: 'vidros', nome: 'Gravação vidro da porta', ordem: 11),
  ];

  static const List<ItemTemplate> itensMoto = [
    ItemTemplate(categoria: 'identificacao', nome: 'CRLV', ordem: 1),
    ItemTemplate(
        categoria: 'identificacao', nome: 'Placa e lacre', ordem: 2),
    ItemTemplate(
        categoria: 'identificacao', nome: 'Gravação do chassi', ordem: 3),
    ItemTemplate(
        categoria: 'identificacao', nome: 'Gravação do motor', ordem: 4),
    ItemTemplate(
        categoria: 'identificacao', nome: 'KM / Hodômetro', ordem: 5),
    ItemTemplate(
        categoria: 'extras', nome: 'Painel de instrumentos', ordem: 1),
    ItemTemplate(
        categoria: 'extras', nome: 'Quadro / chassi', ordem: 2),
  ];

  static const List<ItemTemplate> itensUtilitario = [
    ...itensAutomovel,
    ItemTemplate(
        categoria: 'extras', nome: 'Plaqueta do veículo', ordem: 5),
    ItemTemplate(
        categoria: 'extras', nome: 'Gravação de chassis adicional', ordem: 6),
  ];

  static List<ItemTemplate> itensPorTipo(String tipo) {
    switch (tipo) {
      case 'caminhao':
        return itensCaminhao;
      case 'moto':
        return itensMoto;
      case 'utilitario':
        return itensUtilitario;
      case 'automovel':
      default:
        return itensAutomovel;
    }
  }

  static const List<String> pecasPintura = [
    'capo_dianteiro',
    'capo_traseiro',
    'teto',
    'porta_dianteira_dir',
    'porta_dianteira_esq',
    'porta_traseira_dir',
    'porta_traseira_esq',
    'lateral_traseira_dir',
    'lateral_traseira_esq',
    'para_lama_dir',
    'para_lama_esq',
  ];

  static const List<String> pecasEstrutura = [
    'longarina_dianteira_dir',
    'longarina_dianteira_esq',
    'longarina_centro_dir',
    'longarina_centro_esq',
    'longarina_traseira_dir',
    'longarina_traseira_esq',
    'painel_dianteiro',
    'painel_traseiro',
    'painel_corta_fogo',
    'teto',
    'assoalho',
  ];

  static const List<String> fotosObrigatorias = [
    'Frente esquerda',
    'Traseira 45°',
    'Placa e lacre',
    'Gravação do chassi',
    'Gravação do motor',
    'Painel / hodômetro',
  ];

  static String nomePecaPintura(String peca) {
    const nomes = {
      'capo_dianteiro': 'Capô Dianteiro',
      'capo_traseiro': 'Capô Traseiro / Tampa',
      'teto': 'Teto',
      'porta_dianteira_dir': 'Porta Dianteira Direita',
      'porta_dianteira_esq': 'Porta Dianteira Esquerda',
      'porta_traseira_dir': 'Porta Traseira Direita',
      'porta_traseira_esq': 'Porta Traseira Esquerda',
      'lateral_traseira_dir': 'Lateral Traseira Direita',
      'lateral_traseira_esq': 'Lateral Traseira Esquerda',
      'para_lama_dir': 'Para-lama Direito',
      'para_lama_esq': 'Para-lama Esquerdo',
    };
    return nomes[peca] ?? peca;
  }

  static String nomePecaEstrutura(String peca) {
    const nomes = {
      'longarina_dianteira_dir': 'Longarina Dianteira Direita',
      'longarina_dianteira_esq': 'Longarina Dianteira Esquerda',
      'longarina_centro_dir': 'Longarina Centro Direita',
      'longarina_centro_esq': 'Longarina Centro Esquerda',
      'longarina_traseira_dir': 'Longarina Traseira Direita',
      'longarina_traseira_esq': 'Longarina Traseira Esquerda',
      'painel_dianteiro': 'Painel Dianteiro',
      'painel_traseiro': 'Painel Traseiro',
      'painel_corta_fogo': 'Painel Corta-fogo',
      'teto': 'Teto',
      'assoalho': 'Assoalho',
    };
    return nomes[peca] ?? peca;
  }

  static const Map<String, String> categoriaLabel = {
    'identificacao': 'Identificação',
    'estrutura': 'Estrutura',
    'pintura': 'Pintura',
    'vidros': 'Vidros',
    'extras': 'Itens Extras',
  };

  static const Map<String, String> tipoLabel = {
    'automovel': 'Automóvel',
    'caminhao': 'Caminhão',
    'moto': 'Moto',
    'utilitario': 'Utilitário',
  };
}

class ItemTemplate {
  final String categoria;
  final String nome;
  final int ordem;

  const ItemTemplate({
    required this.categoria,
    required this.nome,
    required this.ordem,
  });
}
