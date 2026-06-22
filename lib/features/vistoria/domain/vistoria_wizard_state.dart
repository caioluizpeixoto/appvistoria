import 'package:flutter/foundation.dart';
import 'vistoria_type.dart';

/// Estado compartilhado do wizard de vistoria.
/// Mantém todos os dados temporários enquanto o vistoriador percorre as etapas.
class VistoriaWizardState extends ChangeNotifier {
  // ── Identificação ──────────────────────────────────────────────────────────
  final String vistoriaId;
  String numeroLaudo = '';
  int currentStep;

  // ── Dados Gerais (Step 1) ──────────────────────────────────────────────────
  String tipoVistoria = 'Vistoria Cautelar Automotiva';
  String clienteNome = '';
  String unidade = '';
  String vistoriadorNome = '';
  String vistoriadorCpf = '';
  String status = 'Em andamento';

  // ── Dados do Veículo (Step 2) ──────────────────────────────────────────────
  String placa = '';
  String chassiBin = '';
  String chassiVeiculo = '';
  String motorBin = '';
  String motorVeiculo = '';
  String cambioBin = '';
  String cambioVeiculo = '';
  String renavam = '';
  String marca = '';
  String modelo = '';
  String anoFabricacao = '';
  String anoModelo = '';
  String cor = '';
  String combustivel = '';
  String municipio = '';
  String uf = '';
  String km = '';
  String numeroGrv = '';

  // ── Checklist de itens: status e observação por itemId ────────────────────
  // Todas as etapas de inspeção usam este mapa
  final Map<String, String> checklistStatus = {};
  final Map<String, String> checklistObs = {};
  final Map<String, String> checklistCodigo = {}; // Para vidros: código gravado
  final List<String> vidrosExtrasIds = [];

  // ── Fotos: itemId -> lista de caminhos locais ─────────────────────────────
  final Map<String, List<String>> fotosLocais = {};
  // itemId -> lista de URLs Supabase
  final Map<String, List<String>> fotosUrls = {};

  // ── Fotos Extras (Step 12) ────────────────────────────────────────────────
  final List<Map<String, dynamic>> fotosExtras = [];

  // ── Observações Gerais (Step 13) ──────────────────────────────────────────
  String observacoesVeiculo = '';
  String observacoesVistoriador = '';
  String divergenciasEncontradas = '';
  String recomendacoes = '';

  // ── Conclusão (Step 14) ───────────────────────────────────────────────────
  String resultadoFinal = '';
  String parecerTecnico = '';
  String? assinaturaPath;

  // ── Controle de loading ───────────────────────────────────────────────────
  bool isSaving = false;

  // ── Flags Auxiliares ───────────────────────────────────────────────────────
  TipoVistoria get tipoEnum => TipoVistoria.fromString(tipoVistoria);
  bool get isCaminhao => tipoEnum == TipoVistoria.cautelarCaminhao;
  bool get temCroqui => tipoEnum != TipoVistoria.cautelarCaminhao;
  bool get temAvarias => tipoEnum == TipoVistoria.carroComCroqui;

  VistoriaWizardState({
    required this.vistoriaId,
    this.currentStep = 0,
  });

  // ── Navegação ──────────────────────────────────────────────────────────────

  int get totalSteps {
    int count = 10;
    if (temCroqui) count++;
    if (temAvarias) count++;
    return count;
  }
  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep >= totalSteps - 1;

  void nextStep() {
    if (!isLastStep) {
      currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (!isFirstStep) {
      currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    currentStep = step;
    notifyListeners();
  }

  // ── Checklist ─────────────────────────────────────────────────────────────

  String getStatus(String itemId) => checklistStatus[itemId] ?? '';
  String getObs(String itemId) => checklistObs[itemId] ?? '';
  String getCodigo(String itemId) => checklistCodigo[itemId] ?? '';

  void setStatus(String itemId, String status) {
    checklistStatus[itemId] = status;
    notifyListeners();
  }

  void setObs(String itemId, String obs) {
    checklistObs[itemId] = obs;
    notifyListeners();
  }

  void setCodigo(String itemId, String codigo) {
    checklistCodigo[itemId] = codigo;
    notifyListeners();
  }

  void addVidroExtra() {
    vidrosExtrasIds.add('vidro_extra_${DateTime.now().millisecondsSinceEpoch}');
    notifyListeners();
  }

  void removeVidroExtra(String itemId) {
    vidrosExtrasIds.remove(itemId);
    notifyListeners();
  }

  // ── Fotos ──────────────────────────────────────────────────────────────────

  List<String> getFotosLocais(String itemId) => fotosLocais[itemId] ?? [];
  List<String> getFotosUrls(String itemId) => fotosUrls[itemId] ?? [];

  bool hasFoto(String itemId) =>
      (fotosLocais[itemId]?.isNotEmpty ?? false) ||
      (fotosUrls[itemId]?.isNotEmpty ?? false);

  void addFotoLocal(String itemId, String path) {
    fotosLocais.putIfAbsent(itemId, () => []).add(path);
    notifyListeners();
  }

  void addFotoUrl(String itemId, String url) {
    fotosUrls.putIfAbsent(itemId, () => []).add(url);
    notifyListeners();
  }

  void removeFoto(String itemId, int index) {
    if (fotosLocais[itemId] != null && index < fotosLocais[itemId]!.length) {
      fotosLocais[itemId]!.removeAt(index);
    }
    notifyListeners();
  }

  // ── Fotos extras ──────────────────────────────────────────────────────────

  void addFotoExtra({
    required String pathLocal,
    String? url,
    String titulo = '',
    String obs = '',
    String categoria = 'Outro',
  }) {
    fotosExtras.add({
      'pathLocal': pathLocal,
      'url': url,
      'titulo': titulo,
      'obs': obs,
      'categoria': categoria,
    });
    notifyListeners();
  }

  void removeFotoExtra(int index) {
    if (index < fotosExtras.length) {
      fotosExtras.removeAt(index);
      notifyListeners();
    }
  }

  // ── Pré-preencher do veículo ──────────────────────────────────────────────

  void preencherDadosVeiculo(Map<String, dynamic> dados) {
    placa = dados['placa'] ?? placa;
    chassiBin = dados['chassi'] ?? chassiBin;
    chassiVeiculo = dados['chassi'] ?? chassiVeiculo;
    motorBin = dados['motor'] ?? motorBin;
    motorVeiculo = dados['motor'] ?? motorVeiculo;
    marca = dados['marca'] ?? marca;
    modelo = dados['modelo'] ?? modelo;
    anoFabricacao = dados['anoFabricacao'] ?? anoFabricacao;
    anoModelo = dados['anoModelo'] ?? anoModelo;
    cor = dados['cor'] ?? cor;
    renavam = dados['renavam'] ?? renavam;
    municipio = dados['municipio'] ?? municipio;
    uf = dados['uf'] ?? uf;
    combustivel = dados['combustivel'] ?? combustivel;
    notifyListeners();
  }

  // ── Validação ─────────────────────────────────────────────────────────────

  /// Fotos obrigatórias que precisam estar preenchidas para gerar o PDF
  static const List<String> fotosObrigatorias = [
    'frente_direita',
    'frente_esquerda',
    'traseira_direita',
    'traseira_esquerda',
    'lateral_direita',
    'lateral_esquerda',
    'placa_dianteira',
    'placa_traseira',
    'compartimento_motor',
    'painel_hodometro',
    'chassi_gravacao',
    'motor_gravacao',
  ];

  List<String> get fotasObrigatoriasFaltando =>
      fotosObrigatorias.where((id) => !hasFoto(id)).toList();

  bool get podeGerarPdf =>
      fotasObrigatoriasFaltando.isEmpty &&
      resultadoFinal.isNotEmpty &&
      (assinaturaPath != null);

  /// Retorna todos os itens com divergência detectada
  List<String> get itensDivergentes {
    final List<String> divergentes = [];
    checklistStatus.forEach((id, status) {
      if (status.toLowerCase().contains('divergente') ||
          status.toLowerCase().contains('remarcado') ||
          status.toLowerCase().contains('adulteração') ||
          status.toLowerCase().contains('reprovado')) {
        divergentes.add(id);
      }
    });
    // Verifica divergência chassi/motor
    if (chassiBin.isNotEmpty &&
        chassiVeiculo.isNotEmpty &&
        chassiBin != chassiVeiculo) {
      if (!divergentes.contains('chassi_divergencia')) {
        divergentes.add('chassi_divergencia');
      }
    }
    if (motorBin.isNotEmpty &&
        motorVeiculo.isNotEmpty &&
        motorBin != motorVeiculo) {
      if (!divergentes.contains('motor_divergencia')) {
        divergentes.add('motor_divergencia');
      }
    }
    return divergentes;
  }

  /// Status sugerido com base nos itens inspecionados
  String get statusSugerido {
    final divs = itensDivergentes;
    if (divs.isEmpty && fotasObrigatoriasFaltando.isEmpty) {
      final temObs = checklistStatus.values.any((s) =>
          s.toLowerCase().contains('reparo') ||
          s.toLowerCase().contains('observação') ||
          s.toLowerCase().contains('repintura'));
      return temObs ? 'Conforme com observações' : 'Conforme';
    }
    if (divs.isNotEmpty) {
      return divs.length >= 2 ? 'Reprovado' : 'Necessita análise complementar';
    }
    return 'Em andamento';
  }

  int get totalFotos {
    int count = 0;
    fotosLocais.forEach((_, list) => count += list.length);
    count += fotosExtras.length;
    return count;
  }

  // ── Serialização para persistência local ──────────────────────────────────

  Map<String, dynamic> toObservacoes() => {
        'veículo': observacoesVeiculo,
        'vistoriador': observacoesVistoriador,
        'divergências': divergenciasEncontradas,
        'recomendações': recomendacoes,
      };

  void forceUpdate() {
    notifyListeners();
  }
}
