/// Catálogo de produtos e tokens da Radar Consultas.
class RadarProdutoInfo {
  final String codigo;
  final String nome;
  final String token;
  final List<String> parametrosAceitos; // 'placa', 'chassi', 'motor', etc.
  final String descricao;

  const RadarProdutoInfo({
    required this.codigo,
    required this.nome,
    required this.token,
    required this.parametrosAceitos,
    this.descricao = '',
  });

  bool aceitaParametro(String param) => parametrosAceitos.contains(param.toLowerCase());
}

class RadarProdutos {
  static const Map<String, RadarProdutoInfo> catalogo = {
    'numero_crv': RadarProdutoInfo(
      codigo: 'numero_crv',
      nome: 'Número CRV',
      token: '21696E59C08FB7F176883961615M79UH32B1WOVGJHFY255O0I',
      parametrosAceitos: ['placa'],
      descricao: 'Consulta do Número CRV do veículo pela placa',
    ),
    'codigo_crv': RadarProdutoInfo(
      codigo: 'codigo_crv',
      nome: 'Código CRV',
      token: '21697118FF9B1101769019647Q5BFBB9FWVUYXKE9DRDLFYWFZ',
      parametrosAceitos: ['placa'],
      descricao: 'Consulta do Código CRV do veículo pela placa',
    ),
    'auto_completa': RadarProdutoInfo(
      codigo: 'auto_completa',
      nome: 'AUTO COMPLETA',
      token: '21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76',
      parametrosAceitos: ['placa'],
      descricao: 'Consulta completa de dados veiculares',
    ),
    'auto_bin': RadarProdutoInfo(
      codigo: 'auto_bin',
      nome: 'AUTO BIN',
      token: '21589A1C74E953B1486494836NQ70TJ0EUZFTS9K7GGLAMHKOJ',
      parametrosAceitos: ['placa', 'chassi'],
      descricao: 'Base de Índice Nacional (BIN) padrão por placa ou chassi',
    ),
    'auto_base_estadual': RadarProdutoInfo(
      codigo: 'auto_base_estadual',
      nome: 'AUTO BASE ESTADUAL',
      token: '21589C4F6FE5D851486638959Z74PAKY8WJ4M8EF5LQB945K5N',
      parametrosAceitos: ['placa'],
      descricao: 'Consulta na base estadual do Detran',
    ),
    'auto_pericia': RadarProdutoInfo(
      codigo: 'auto_pericia',
      nome: 'AUTO PERÍCIA',
      token: '2158B04671523351487947377ALQNCW8LN4VGIJHLHSFJDD5G9',
      parametrosAceitos: ['placa'],
      descricao: 'Perícia veicular cadastral',
    ),
    'auto_leilao': RadarProdutoInfo(
      codigo: 'auto_leilao',
      nome: 'AUTO LEILÃO',
      token: '2158DD027974724149087909770OG7270OE8LK17N7RET0LSJ3',
      parametrosAceitos: ['placa', 'chassi'],
      descricao: 'Histórico de leilões e ofertas',
    ),
    'auto_estadual_proprietario': RadarProdutoInfo(
      codigo: 'auto_estadual_proprietario',
      nome: 'AUTO ESTADUAL + PROPRIETÁRIO',
      token: '2158DE583B7654714909665876FV8VSPNER2DHLZR81SPVLMZ0',
      parametrosAceitos: ['placa'],
      descricao: 'Base estadual com identificação do proprietário',
    ),
    'auto_decodificador_chassi': RadarProdutoInfo(
      codigo: 'auto_decodificador_chassi',
      nome: 'AUTO DECODIFICADOR DE CHASSI',
      token: '2158F0F1EF0ADB11492185583PRLK042XHWPU83FX7V5DJ8MRT',
      parametrosAceitos: ['chassi'],
      descricao: 'Decodificação e especificações técnicas a partir do chassi',
    ),
    'auto_gravame': RadarProdutoInfo(
      codigo: 'auto_gravame',
      nome: 'AUTO GRAVAME',
      token: '2158FA1C23B8B8C1492786211KU65H6GRCDCNNLXZARBEQRLGY',
      parametrosAceitos: ['chassi'],
      descricao: 'Consulta de restrições financeiras e gravame no SNG',
    ),
    'auto_debitos_recall': RadarProdutoInfo(
      codigo: 'auto_debitos_recall',
      nome: 'AUTO DÉBITOS + RECALL',
      token: '2159EA6BFB60104150853529156RSGFTC62RP1XWPKV9CT99P1',
      parametrosAceitos: ['placa', 'chassi'],
      descricao: 'Consulta de débitos estaduais, multas e chamados de recall pendentes',
    ),
    'auto_analise': RadarProdutoInfo(
      codigo: 'auto_analise',
      nome: 'AUTO ANÁLISE',
      token: '215C7D7C9C6A8151551727772AXVADBADNQZAWS5M9SLVVF0R1',
      parametrosAceitos: ['placa'],
      descricao: 'Análise cadastral veicular',
    ),
    'auto_analise_plus': RadarProdutoInfo(
      codigo: 'auto_analise_plus',
      nome: 'AUTO ANÁLISE +',
      token: '215C7D7D8400EAB1551728004RDCEG7NQ58EGUG34O9O4ATTRI',
      parametrosAceitos: ['placa'],
      descricao: 'Análise cadastral aprofundada',
    ),
    'auto_pericia_hrf': RadarProdutoInfo(
      codigo: 'auto_pericia_hrf',
      nome: 'AUTO PERÍCIA HRF',
      token: '2162AB9E27B63CD1655414311NO8UOXTCZ2SC4CW1L75PRFEVN',
      parametrosAceitos: ['placa'],
      descricao: 'Histórico de roubo e furto e perícia completa',
    ),
    'bin_por_motor': RadarProdutoInfo(
      codigo: 'bin_por_motor',
      nome: 'PESQUISA DE MOTOR',
      token: '2162E98433071ED165947089995HQEQV32WR95PCLFIHJS2AOD',
      parametrosAceitos: ['motor'],
      descricao: 'Consulta oficial através da numeração do motor',
    ),
    'e_crlv_nova': RadarProdutoInfo(
      codigo: 'e_crlv_nova',
      nome: 'E-CRLV NOVA',
      token: '216952A87095C431767024752XO8PQAC1LARXMPKCF9J3DQ428',
      parametrosAceitos: ['placa'],
      descricao: 'Emissão e dados do CRLV digital',
    ),
  };

  /// Lista padrão exibida no seletor de tipos de consulta
  static List<Map<String, dynamic>> get listaParaSelecao => [
        {'nome': 'AUTO BIN (Placa / Chassi)', 'codigo': 'auto_bin', 'param': 'placa'},
        {'nome': 'PESQUISA DE MOTOR', 'codigo': 'bin_por_motor', 'param': 'motor'},
        {'nome': 'AUTO PERÍCIA', 'codigo': 'auto_pericia', 'param': 'placa'},
        {'nome': 'AUTO PERÍCIA HRF (Recomendado)', 'codigo': 'auto_pericia_hrf', 'param': 'placa'},
        {'nome': 'AUTO COMPLETA', 'codigo': 'auto_completa', 'param': 'placa'},
        {'nome': 'AUTO LEILÃO', 'codigo': 'auto_leilao', 'param': 'placa'},
        {'nome': 'AUTO BASE ESTADUAL', 'codigo': 'auto_base_estadual', 'param': 'placa'},
        {'nome': 'AUTO DÉBITOS E RECALL', 'codigo': 'auto_debitos_recall', 'param': 'placa'},
        {'nome': 'AUTO GRAVAME (Chassi)', 'codigo': 'auto_gravame', 'param': 'chassi'},
        {'nome': 'AUTO DECODIFICADOR (Chassi)', 'codigo': 'auto_decodificador_chassi', 'param': 'chassi'},
        {'nome': 'AUTO ANÁLISE', 'codigo': 'auto_analise', 'param': 'placa'},
        {'nome': 'NÚMERO CRV', 'codigo': 'numero_crv', 'param': 'placa'},
        {'nome': 'CÓDIGO CRV', 'codigo': 'codigo_crv', 'param': 'placa'},
      ];
}
