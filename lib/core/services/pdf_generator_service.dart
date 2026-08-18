import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../database/app_database.dart';
import '../../features/vistoria/domain/vistoria_type.dart';
import '../../features/vistoria/domain/vistoria_wizard_state.dart';
import '../../injection_container.dart';
import '../../database/daos/autocred_dao.dart';
import '../../database/daos/vistoria_dao.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'pdf_radar_generator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'pdf_checklist_generator.dart';
import '../utils/veiculo_parser.dart';
import '../normalizers/radar_normalizer.dart';
import '../normalizers/radar_normalized_data.dart';
import '../../features/consulta_bin/data/repositories/radar_repository.dart';
import '../../features/consulta_bin/domain/entities/radar_veiculo.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';

pw.ImageProvider? _globalRodapeImage;

Uint8List _processGrayscaleImage(Uint8List uint8list) {
  final decodedImage = img.decodeImage(uint8list);
  if (decodedImage != null) {
    img.grayscale(decodedImage);
    final bwBytes = img.encodePng(decodedImage);
    return Uint8List.fromList(bwBytes);
  }
  return uint8list;
}

Future<pw.ImageProvider?> _loadAssetImage(List<String> paths) async {
  for (final path in paths) {
    try {
      final bytes = await rootBundle.load(path);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
  }
  return null;
}

String _cleanItemName(String rawId) {
  var clean = rawId.trim();
  clean = clean.replaceFirst(
      RegExp(r'^(peca[_\s]+cam[_\s]+|peça[_\s]+cam[_\s]+|peca[_\s]+|peça[_\s]+|cam[_\s]+)',
          caseSensitive: false),
      '');
  clean = clean.replaceAll('_', ' ').trim().toUpperCase();

  const Map<String, String> mapLabels = {
    'CAPO': 'CAPÔ',
    'TETO': 'TETO',
    'PAINEL TRAS': 'PAINEL TRASEIRO',
    'PARACHOQUE DIAN': 'PARA-CHOQUE DIANTEIRO',
    'GRADE': 'GRADE',
    'PORTA ESQ': 'PORTA DIANTEIRA ESQUERDA',
    'PARALAMA ESQ': 'PARA-LAMA DIANTEIRO ESQUERDO',
    'COLUNA A ESQ': 'COLUNA A ESQUERDA',
    'COLUNA B ESQ': 'COLUNA B ESQUERDA',
    'LAT ESQ': 'LATERAL ESQUERDA',
    'SAIA ESQ': 'SAIA LATERAL ESQUERDA',
    'PARALAMA TRAS ESQ': 'PARA-LAMA TRASEIRO ESQUERDO',
    'PORTA DIR': 'PORTA DIANTEIRA DIREITA',
    'PARALAMA DIR': 'PARA-LAMA DIANTEIRO DIREITO',
    'COLUNA A DIR': 'COLUNA A DIREITA',
    'COLUNA B DIR': 'COLUNA B DIREITA',
    'LAT DIR': 'LATERAL DIREITA',
    'SAIA DIR': 'SAIA LATERAL DIREITA',
    'PARALAMA TRAS DIR': 'PARA-LAMA TRASEIRO DIREITO',
    'PARACHOQUE TRAS': 'PARA-CHOQUE TRASEIRO',
  };

  return mapLabels[clean] ?? clean;
}

// ── Paleta PDF ──────────────────────────────────────────────────────────────
const _kBlack = PdfColor.fromInt(0xFF222222);
const _kWhite = PdfColors.white;
const _kGreyLight = PdfColor.fromInt(0xFFF5F5F5);
const _kGreyDark = PdfColor.fromInt(0xFF666666);
const _kGreen = PdfColor.fromInt(0xFF8BC34A);
const _kOrange = PdfColor.fromInt(0xFFFFCA28);
const _kRed = PdfColor.fromInt(0xFFEF5350);

bool _isStatusConformeOuOk(String status) {
  if (status.isEmpty) return true;
  final s = status.trim().toUpperCase();
  if (s == 'CONFORME' || s == 'OK' || s == 'SIM') return true;
  if (s == 'NÃO ANALISADO' || s == 'NAO ANALISADO' || s == 'NÃO APLICÁVEL' || s == 'NAO APLICAVEL') return true;
  if (s.contains('PADRÃO') || s.contains('PADRAO')) return true;
  if (s.contains('ORIGINAL')) return true;
  if (s.contains('GRAVADO') && !s.contains('SEM GRAVAÇÃO') && !s.contains('SEM GRAVACAO')) return true;
  if (s.contains('FUNCIONAMENTO') && !s.contains('NÃO') && !s.contains('NAO') && !s.contains('SEM')) return true;
  if (s.contains('CONFORME') && !s.contains('NÃO CONFORME') && !s.contains('NAO CONFORME')) return true;
  return false;
}

class PdfGeneratorService {
  Future<File> generateLaudoPdf({
    required Vistoria vistoria,
    required Veiculo veiculo,
    required Map<String, String> uploadedPhotos,
    required Map<String, String> ocrResults,
  }) async {
    final type = TipoVistoria.fromString(vistoria.tipoVistoria ?? '');
    if (type == TipoVistoria.checklistPesado ||
        type == TipoVistoria.checklistPasseio ||
        type == TipoVistoria.vistoriaEntrada) {
      final path = await generateChecklistPdf(
        vistoria: vistoria,
        veiculo: veiculo,
        // The wizardState is not passed here directly in generateLaudoPdf signature
        // but wait, generateLaudoCompleto does have wizardState. We can fetch it if needed or
        // we should route inside `generateLaudoCompleto` which receives wizardState.
      );
      if (path != null) return File(path);
      throw Exception('Falha ao gerar Checklist PDF');
    }

    return generateLaudoCompleto(
      vistoria: vistoria,
      veiculo: veiculo,
    ) as Future<File>;
  }

  Future<String?> _obterUfPorGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      Position? position = await Geolocator.getLastKnownPosition();

      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }

      final geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        return placemarks.first.administrativeArea;
      }
    } catch (e) {
      print('Erro ao obter GPS para UF: $e');
    }
    return null;
  }

  Future<String?> generateLaudoCompleto({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? wizardState,
  }) async {
    final type = TipoVistoria.fromString(vistoria.tipoVistoria ?? '');
    if (type == TipoVistoria.checklistPesado ||
        type == TipoVistoria.checklistPasseio ||
        type == TipoVistoria.vistoriaEntrada) {
      return generateChecklistPdf(
        vistoria: vistoria,
        veiculo: veiculo,
        wizardState: wizardState,
      );
    }

    // Se wizardState for nulo ou estiver sem checklistStatus, recarrega do banco de dados local (Drift)
    if (wizardState == null || wizardState.checklistStatus.isEmpty) {
      try {
        final vistoriaDao = sl<VistoriaDao>();
        wizardState ??= VistoriaWizardState(vistoriaId: vistoria.id);

        wizardState.numeroLaudo = vistoria.numeroLaudo;
        wizardState.clienteNome = vistoria.clienteNome ?? '';
        wizardState.clienteEmail = vistoria.clienteEmail ?? '';
        wizardState.clienteCpf = vistoria.clienteCpf ?? '';
        wizardState.clienteTelefone = vistoria.clienteTelefone ?? '';
        wizardState.vistoriadorNome = vistoria.vistoriadorNome ?? '';
        wizardState.vistoriadorCpf = vistoria.vistoriadorCpf ?? '';
        wizardState.unidade = vistoria.unidade ?? '';
        wizardState.assinaturaPath = vistoria.assinaturaPath;
        wizardState.assinaturaClientePath = vistoria.assinaturaClientePath;
        wizardState.observacoesVistoriador = vistoria.observacoesGerais ?? '';
        wizardState.parecerTecnico = vistoria.parecerTecnico ?? '';
        wizardState.resultadoFinal = vistoria.statusFinal ?? '';
        wizardState.status = vistoria.status;
        if (vistoria.tipoVistoria != null) {
          wizardState.tipoVistoria = vistoria.tipoVistoria!;
        }

        final itens = await vistoriaDao.listarItensPorVistoria(vistoria.id);
        for (final item in itens) {
          if (item.etapa == 'checklist_opcional') {
            wizardState.realizarChecklistOpcional = true;
            wizardState.checklistOpcional[item.nome] = item.status;
          } else {
            wizardState.checklistStatus[item.nome] = item.status;
            wizardState.checklistObs[item.nome] = item.observacao ?? '';
          }
        }

        final fotos = await vistoriaDao.listarFotosPorVistoria(vistoria.id);
        for (final foto in fotos) {
          if (foto.etapa == 'extra') {
            if (foto.pathLocal != null && foto.pathLocal!.isNotEmpty) {
              wizardState.fotosExtras.add({
                'pathLocal': foto.pathLocal ?? '',
                'url': foto.urlSupabase,
                'obs': foto.observacao ?? '',
                'titulo': 'Foto Extra',
                'categoria': 'Outro',
              });
            }
          } else {
            if (foto.pathLocal != null) {
              final itemId = foto.itemId ?? 'desconhecido';
              wizardState.fotosLocais
                  .putIfAbsent(itemId, () => [])
                  .add(foto.pathLocal!);
            }
          }
        }
      } catch (e) {
        print('Erro ao carregar dados da vistoria do banco para o PDF: $e');
      }
    }

    // Busca histórico radar (se houver)
    final dao = sl<AutocredDao>();
    var consulta = await dao.buscarConsultaPorVistoria(vistoria.id);
    if (consulta == null && veiculo.placa.trim().isNotEmpty) {
      consulta = await dao.buscarConsultaPorPlaca(veiculo.placa.trim());
    }
    if (consulta == null && (veiculo.chassiVeiculo ?? '').trim().isNotEmpty) {
      consulta = await dao.buscarConsultaPorChassi((veiculo.chassiVeiculo ?? '').trim());
    }
    RadarVeiculo? radarVeiculo;
    Map<String, dynamic>? dadosConsultaJson;
    if (consulta != null && consulta.dadosTratadosJson != null) {
      try {
        final decoded = json.decode(consulta.dadosTratadosJson!);
        if (decoded is Map<String, dynamic>) {
          dadosConsultaJson = decoded;
          radarVeiculo = RadarVeiculo.fromJson(decoded);
        }
      } catch (e) {
        print('Erro ao decodificar JSON do Radar: $e');
      }
    }

    final pdf = pw.Document(
      title: 'Laudo Cautelar - ${veiculo.placa}',
      author: vistoria.vistoriadorNome ?? 'UltraVisão',
    );

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final styles = _PdfStyles(regular: fontRegular, bold: fontBold);

    // Carregar logo se existir (senão usa placeholder)
    pw.ImageProvider? logoImage = await _loadAssetImage([
      'assets/images/topo.pdf.png',
      'assets/images/topo.pdf.PNG',
      'assets/images/topo.png',
      'assets/images/logo.pdf.png',
      'assets/images/logo.png',
    ]);
    pw.ImageProvider? marcaAguaBw = logoImage;

    pw.ImageProvider? carroEstruturaImage;
    pw.ImageProvider? caminhaoEstruturaImage;
    pw.ImageProvider? carroPinturaImage;
    try {
      final bytes = await rootBundle.load('assets/images/carro_estrutura.png');
      carroEstruturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final bytes =
          await rootBundle.load('assets/images/caminhao_estrutura.png');
      caminhaoEstruturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final bytes = await rootBundle.load('assets/images/carro_pintura.png');
      carroPinturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    _globalRodapeImage = await _loadAssetImage([
      'assets/images/logo.pdf.PNG',
      'assets/images/logo.pdf.png',
      'assets/images/logo.png',
    ]);

    pw.ImageProvider? assinaturaImage;
    if (wizardState?.assinaturaPath != null) {
      try {
        final file = File(wizardState!.assinaturaPath!);
        if (file.existsSync()) {
          assinaturaImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (_) {}
    }

    pw.ImageProvider? assinaturaClienteImage;
    if (wizardState?.assinaturaClientePath != null) {
      try {
        final file = File(wizardState!.assinaturaClientePath!);
        if (file.existsSync()) {
          assinaturaClienteImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (_) {}
    }

    // Página 1 — Dados Gerais (Histórico Radar)
    pdf.addPage(await _buildPage1Historico(
        vistoria: vistoria,
        veiculo: veiculo,
        state: wizardState,
        styles: styles,
        logo: logoImage,
        assinatura: assinaturaImage,
        assinaturaCliente: assinaturaClienteImage,
        marcaAgua: marcaAguaBw,
        radarVeiculo: radarVeiculo,
        dadosConsultaJson: dadosConsultaJson));

    // A página 2 antiga foi fundida com a página 1

    final tipoEnum = TipoVistoria.fromString(vistoria.tipoVistoria ?? '');
    final isCaminhao = tipoEnum == TipoVistoria.cautelarCaminhao;
    final temCroqui = tipoEnum != TipoVistoria.cautelarCaminhao;
    final temAvarias = tipoEnum == TipoVistoria.carroComCroqui;
    final bgImage = isCaminhao ? caminhaoEstruturaImage : carroEstruturaImage;

    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    final Map<String, List<String>> secoesFotos = {
      'FOTOS PRINCIPAIS': [
        'motor_gravacao',
        'chassi_gravacao',
        'frente_esquerda',
        'frente_direita',
        'traseira_esquerda',
        'traseira_direita',
      ],
      'IDENTIFICAÇÃO, DOCUMENTAÇÃO E VIDROS': [
        'foto_placa',
        'painel_hodometro',
        if (isCaminhao) 'plaqueta_da_cabine',
        if (isCaminhao) 'Plaqueta da cabine',
        'etiqueta_vis_motor',
        'etiqueta_vis_porta',
        'compartimento_motor',
        'cambio_gravacao',
        'vidro_frontal',
        if (wizardState?.getStatus('vidro_traseiro').toUpperCase() !=
            'INEXISTENTE')
          'vidro_traseiro',
        'vidro_dianteiro_direito',
        'vidro_dianteiro_esquerdo',
        'vidro_traseiro_direito',
        'vidro_traseiro_esquerdo',
        if (wizardState != null) ...wizardState.vidrosExtrasIds,
      ],
      if (temCroqui && !isCaminhao)
        'FOTOS - ESTRUTURAL': [
          'painel_frontal',
          'painel_corta_fogo',
          'torre_amortecedor_esquerda',
          'longarina_dianteira_esquerda',
          'caixa_roda_dianteira_esquerda',
          'coluna_dianteira_esquerda',
          'caixa_ar_esquerda',
          'assoalho_esquerdo',
          'coluna_central_esquerda',
          'longarina_centro_esquerda',
          'coluna_traseira_esquerda',
          'caixa_roda_traseira_esquerda',
          'longarina_traseira_esquerda',
          'painel_traseiro',
          'caixa_estepe',
          'longarina_traseira_direita',
          'caixa_roda_traseira_direita',
          'coluna_traseira_direita',
          'longarina_centro_direita',
          'coluna_central_direita',
          'assoalho_direito',
          'caixa_ar_direita',
          'coluna_dianteira_direita',
          'caixa_roda_dianteira_direita',
          'longarina_dianteira_direita',
          'torre_amortecedor_direita',
        ],
      if (!isCaminhao && (wizardState?.realizarAvaliacaoPintura ?? false))
        'FOTOS - PINTURA E LATARIA': [
          'peca_capo_dianteiro',
          'peca_paralama_dianteiro_esquerdo',
          'peca_porta_dianteira_esquerda',
          'peca_porta_traseira_esquerda',
          'peca_lateral_traseira_esquerda',
          'peca_tampa_traseira',
          'peca_teto',
          'peca_lateral_traseira_direita',
          'peca_porta_traseira_direita',
          'peca_porta_dianteira_direita',
          'peca_paralama_dianteiro_direito',
        ],
      if (isCaminhao && (wizardState?.realizarAvaliacaoPintura ?? false))
        'FOTOS - PINTURA E LATARIA (CAMINHÃO)': [
          'peca_cam_capo',
          'peca_cam_teto',
          'peca_cam_painel_tras',
          'peca_cam_parachoque_dian',
          'peca_cam_grade',
          'peca_cam_porta_esq',
          'peca_cam_paralama_esq',
          'peca_cam_coluna_a_esq',
          'peca_cam_coluna_b_esq',
          'peca_cam_lat_esq',
          'peca_cam_saia_esq',
          'peca_cam_paralama_tras_esq',
          'peca_cam_porta_dir',
          'peca_cam_paralama_dir',
          'peca_cam_coluna_a_dir',
          'peca_cam_coluna_b_dir',
          'peca_cam_lat_dir',
          'peca_cam_saia_dir',
          'peca_cam_paralama_tras_dir',
          'peca_cam_parachoque_tras',
        ],
    };

    bool hasAnyPhoto = false;

    if (wizardState != null) {
      final allSections = <Map<String, dynamic>>[];
      final additionalItemPhotos = <Map<String, dynamic>>[];

      for (final entry in secoesFotos.entries) {
        final tituloSecao = entry.key;
        final orderedFotoIds = entry.value;

        final fotosSecao = <Map<String, dynamic>>[];
        for (final id in orderedFotoIds) {
          final locals = wizardState.getFotosLocais(id);
          for (int i = 0; i < locals.length; i++) {
            final localPath = locals[i];
            final f = File(localPath);
            if (f.existsSync()) {
              var label = _cleanItemName(id);

              if (i == 0) {
                // Primeira foto do item (mantém a ordem padrão)
                fotosSecao.add({
                  'id': id,
                  'path': localPath,
                  'label': label,
                });
              } else {
                // Fotos adicionais do mesmo item vão para o final
                additionalItemPhotos.add({
                  'id': id,
                  'path': localPath,
                  'label': '$label (FOTO ${i + 1})',
                });
              }
            }
          }
        }
        if (fotosSecao.isNotEmpty) {
          allSections.add({
            'titulo': tituloSecao,
            'fotos': fotosSecao,
          });
          hasAnyPhoto = true;
        }
      }

      // Adicionar Fotos Extras e Adicionais por último (depois de toda a sequência padrão)
      final fotosExtrasList = <Map<String, dynamic>>[];
      fotosExtrasList.addAll(additionalItemPhotos);

      for (final extra in wizardState.fotosExtras) {
        final path = extra['pathLocal'] as String?;
        final titulo = extra['titulo'] as String? ?? 'FOTO EXTRA';
        final obs = extra['obs'] as String? ?? '';
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) {
            fotosExtrasList.add({
              'path': path,
              'label': titulo.toUpperCase(),
              'obs': obs,
            });
          }
        }
      }
      if (fotosExtrasList.isNotEmpty) {
        allSections.add({
          'titulo': 'FOTOS EXTRAS / ADICIONAIS',
          'fotos': fotosExtrasList,
        });
        hasAnyPhoto = true;
      }

      void addFotosMultiPage(List<Map<String, dynamic>> sectionsToPrint, {bool addResumoEParecer = false}) {
        if (sectionsToPrint.isEmpty && !addResumoEParecer) return;

        final limeGreen = PdfColor.fromHex('8CC63F');
        pdf.addPage(pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            footer: (ctx) => _buildPdfFooter(ctx, styles),
            header: (ctx) => pw.Column(children: [
                  _buildHeader(vistoria, styles, logoImage, state: wizardState),
                  pw.SizedBox(height: 8),
                ]),
            build: (ctx) {
              final widgets = <pw.Widget>[];

              pw.Widget buildPhotoItem(Map<String, dynamic> f,
                  {bool isLarge = false}) {
                final label = (f['label'] as String? ?? '').toUpperCase();
                pw.Widget imageWidget;

                try {
                  final pathStr = f['path'] as String? ?? '';
                  if (f['base64'] != null &&
                      (f['base64'] as String).isNotEmpty) {
                    final bytes = base64Decode(f['base64'] as String);
                    imageWidget =
                        pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
                  } else if (pathStr.isNotEmpty && File(pathStr).existsSync()) {
                    final bytes = File(pathStr).readAsBytesSync();
                    imageWidget =
                        pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
                  } else if (logoImage != null) {
                    imageWidget = pw.Center(
                      child: pw.Opacity(
                        opacity: 0.2,
                        child: pw.Container(
                            width: 120,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
                      ),
                    );
                  } else {
                    imageWidget = pw.Center(
                      child: pw.Text('Sem foto',
                          style: pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey500)),
                    );
                  }
                } catch (e) {
                  imageWidget = pw.Center(
                    child: pw.Text('Sem foto',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500)),
                  );
                }

                final id = f['id'] as String?;
                final statusAtual = (id != null && wizardState != null)
                    ? wizardState.checklistStatus[id] ?? ''
                    : '';
                String obsText = f['obs'] as String? ?? '';
                if (obsText.isEmpty && id != null && wizardState != null) {
                  obsText = wizardState.checklistObs[id] ?? '';
                }
                final s = statusAtual.toLowerCase();
                PdfColor labelColor = PdfColors.grey700;
                String statusIcon = '';

                if (s.isNotEmpty) {
                  if (s.contains('divergente') ||
                      s.contains('adulteração') ||
                      s.contains('reprovado') ||
                      s.contains('não original') ||
                      s.contains('substituído') ||
                      s.contains('ausente') ||
                      s.contains('danificad') ||
                      s.contains('colisão') ||
                      s.contains('ilegível') ||
                      s.contains('não localizad') ||
                      s.contains('não conforme') ||
                      s.contains('nao conforme')) {
                    labelColor = PdfColor.fromHex('EE4036');
                    statusIcon =
                        '<svg viewBox="0 0 24 24"><path fill="#EE4036" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
                  } else if (s.contains('reparo') ||
                      s.contains('amassad') ||
                      s.contains('risco') ||
                      s.contains('trincad') ||
                      s.contains('quebrad') ||
                      s.contains('apontamento') ||
                      s.contains('observaçã') ||
                      s.contains('observa') ||
                      s.contains('atenção') ||
                      s.contains('desgaste')) {
                    labelColor = PdfColor.fromHex('FBB03B');
                    statusIcon =
                        '<svg viewBox="0 0 24 24"><path fill="#FBB03B" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
                  } else {
                    labelColor = PdfColor.fromHex('8CC63F'); // Conforme
                    statusIcon =
                        '<svg viewBox="0 0 24 24"><path fill="#8CC63F" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
                  }
                }

                return pw.Container(
                  width: isLarge ? 240.0 : 170.0,
                  height: isLarge ? 160.0 : 113.0,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    color: PdfColors.white,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        child: imageWidget,
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        alignment: pw.Alignment.center,
                        child: pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              label,
                              style: pw.TextStyle(
                                  font: styles.bold,
                                  fontSize: 6,
                                  color: PdfColors.grey700),
                              textAlign: pw.TextAlign.center,
                            ),
                            if (s.isNotEmpty) ...[
                              pw.SizedBox(height: 1.5),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.SvgImage(
                                    svg: statusIcon,
                                    width: 6,
                                    height: 6,
                                  ),
                                  pw.SizedBox(width: 2.5),
                                  pw.Text(
                                    s.toUpperCase(),
                                    style: pw.TextStyle(
                                        font: styles.bold,
                                        fontSize: 5,
                                        color: labelColor),
                                  ),
                                ],
                              ),
                            ],
                            if (obsText.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                obsText,
                                style: pw.TextStyle(
                                  font: styles.regular,
                                  fontSize: 4.5,
                                  color: PdfColors.grey600,
                                ),
                                textAlign: pw.TextAlign.center,
                                maxLines: 2,
                                overflow: pw.TextOverflow.clip,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              pw.Widget buildSectionHeader(String title) {
                return pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(top: 8, bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('1F5E3D'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      font: styles.bold,
                      fontSize: 9,
                    ),
                  ),
                );
              }

              for (final section in sectionsToPrint) {
                final tituloSecao = section['titulo'] as String? ?? '';
                final fotos = section['fotos'] as List<Map<String, dynamic>>? ?? [];
                if (fotos.isEmpty) continue;

                widgets.add(buildSectionHeader(tituloSecao));

                final isPrimarySection = tituloSecao.contains('FOTOS PRINCIPAIS');

                if (isPrimarySection) {
                  for (int i = 0; i < fotos.length; i += 2) {
                    final rowFotos = fotos.skip(i).take(2).toList();
                    widgets.add(pw.Center(
                      child: pw.Wrap(
                        alignment: pw.WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: rowFotos
                            .map((f) => buildPhotoItem(f, isLarge: true))
                            .toList(),
                      ),
                    ));
                    widgets.add(pw.SizedBox(height: 8));
                  }
                } else {
                  for (int i = 0; i < fotos.length; i += 3) {
                    final rowFotos = fotos.skip(i).take(3).toList();
                    widgets.add(pw.Center(
                      child: pw.Wrap(
                        alignment: pw.WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: rowFotos
                            .map((f) => buildPhotoItem(f, isLarge: false))
                            .toList(),
                      ),
                    ));
                    widgets.add(pw.SizedBox(height: 8));
                  }
                }
              }

              if (addResumoEParecer) {
                final quadroApontamentos = _buildQuadroResumoApontamentos(wizardState, styles);
                if (quadroApontamentos != null) {
                  widgets.add(pw.SizedBox(height: 10));
                  widgets.add(quadroApontamentos);
                }

                final parecerStr = wizardState?.parecerTecnico ?? vistoria.parecerTecnico ?? '';
                if (parecerStr.trim().isNotEmpty) {
                  widgets.add(pw.SizedBox(height: 12));
                  widgets.add(_buildParecerTecnicoBox(parecerStr, styles));
                }
              }

              return widgets;
            }));
      }

      if (hasAnyPhoto || wizardState != null) {
        final sectionsPrincipais = allSections.where((s) {
          final t = (s['titulo'] as String).toUpperCase();
          return !t.contains('ESTRUTURAL') && !t.contains('PINTURA') && !t.contains('FOTOS EXTRAS');
        }).toList();

        final sectionsEstrutura = allSections.where((s) {
          final t = (s['titulo'] as String).toUpperCase();
          return t.contains('ESTRUTURAL');
        }).toList();

        final sectionsPintura = allSections.where((s) {
          final t = (s['titulo'] as String).toUpperCase();
          return t.contains('PINTURA');
        }).toList();

        final sectionsExtras = allSections.where((s) {
          final t = (s['titulo'] as String).toUpperCase();
          return t.contains('FOTOS EXTRAS');
        }).toList();

        // 1. Fotos Iniciais
        addFotosMultiPage(sectionsPrincipais);

        // 2. Fotos Estrutura
        addFotosMultiPage(sectionsEstrutura);

        // 3. Croqui Estrutural 2D
        if (temCroqui && !isCaminhao) {
          pdf.addPage(_buildPaginasEstruturaDetalhada(
            vistoria: vistoria,
            styles: styles,
            state: wizardState,
            logo: logoImage,
            rodape: _globalRodapeImage,
          ));
        }

        // 4. Análise Estrutural (Tabela)
        if (temCroqui && !isCaminhao) {
          pdf.addPage(_buildPageAnalise(
            titulo: 'ANÁLISE ESTRUTURAL',
            itens: const [
              'painel_frontal',
              'painel_corta_fogo',
              'torre_amortecedor_esquerda',
              'longarina_dianteira_esquerda',
              'caixa_roda_dianteira_esquerda',
              'coluna_dianteira_esquerda',
              'caixa_ar_esquerda',
              'assoalho_esquerdo',
              'coluna_central_esquerda',
              'longarina_centro_esquerda',
              'coluna_traseira_esquerda',
              'caixa_roda_traseira_esquerda',
              'longarina_traseira_esquerda',
              'painel_traseiro',
              'caixa_estepe',
              'longarina_traseira_direita',
              'caixa_roda_traseira_direita',
              'coluna_traseira_direita',
              'longarina_centro_direita',
              'coluna_central_direita',
              'assoalho_direito',
              'caixa_ar_direita',
              'coluna_dianteira_direita',
              'caixa_roda_dianteira_direita',
              'longarina_dianteira_direita',
              'torre_amortecedor_direita',
            ],
            labels: const {
              'longarina_dianteira_direita': 'Longarina Dianteira Direita',
              'longarina_dianteira_esquerda': 'Longarina Dianteira Esquerda',
              'longarina_centro_direita': 'Longarina Centro Direita',
              'longarina_centro_esquerda': 'Longarina Centro Esquerda',
              'longarina_traseira_direita': 'Longarina Traseira Direita',
              'longarina_traseira_esquerda': 'Longarina Traseira Esquerda',
              'painel_frontal': 'Painel Frontal',
              'painel_traseiro': 'Painel Traseiro',
              'assoalho_esquerdo': 'Assoalho Esquerdo',
              'assoalho_direito': 'Assoalho Direito',
              'caixa_ar_esquerda': 'Caixa de Ar Esquerda',
              'caixa_ar_direita': 'Caixa de Ar Direita',
              'caixa_estepe': 'Caixa do Estepe',
              'caixa_roda_dianteira_esquerda': 'Caixa de Roda Dianteira Esquerda',
              'caixa_roda_dianteira_direita': 'Caixa de Roda Dianteira Direita',
              'caixa_roda_traseira_esquerda': 'Caixa de Roda Traseira Esquerda',
              'caixa_roda_traseira_direita': 'Caixa de Roda Traseira Direita',
              'coluna_dianteira_esquerda': 'Coluna Dianteira Esquerda',
              'coluna_dianteira_direita': 'Coluna Dianteira Direita',
              'coluna_central_esquerda': 'Coluna Central Esquerda',
              'coluna_central_direita': 'Coluna Central Direita',
              'coluna_traseira_esquerda': 'Coluna Traseira Esquerda',
              'coluna_traseira_direita': 'Coluna Traseira Direita',
              'torre_amortecedor_esquerda': 'Torre de Amortecedor Esquerda',
              'torre_amortecedor_direita': 'Torre de Amortecedor Direita',
              'painel_corta_fogo': 'Painel Corta Fogo',
            },
            state: wizardState,
            vistoria: vistoria,
            styles: styles,
            logo: logoImage,
            backgroundImage: bgImage,
            assinatura: assinaturaImage,
            assinaturaCliente: assinaturaClienteImage,
            showSignatures: true,
          ));
        }

        // 5. Fotos de Funilaria e Pintura
        addFotosMultiPage(sectionsPintura);

        // 6. Análise Pintura (Croqui 3D + Tabela)
        if (!isCaminhao && (wizardState?.realizarAvaliacaoPintura ?? false)) {
          pw.ImageProvider? ai3dImage;
          if (veiculo.aiImage3dBase64 != null &&
              veiculo.aiImage3dBase64!.isNotEmpty) {
            try {
              final bytes = base64Decode(veiculo.aiImage3dBase64!);
              ai3dImage = pw.MemoryImage(bytes);
            } catch (_) {}
          }

          pdf.addPage(_buildPageAnalise(
            titulo: 'ANÁLISE DE PINTURA',
            itens: const [
              'peca_capo_dianteiro',
              'peca_paralama_dianteiro_direito',
              'peca_paralama_dianteiro_esquerdo',
              'peca_porta_dianteira_direita',
              'peca_porta_dianteira_esquerda',
              'peca_porta_traseira_direita',
              'peca_porta_traseira_esquerda',
              'peca_lateral_traseira_direita',
              'peca_lateral_traseira_esquerda',
              'peca_teto',
              'peca_tampa_traseira',
            ],
            labels: const {
              'peca_capo_dianteiro': 'Capô Dianteiro',
              'peca_paralama_dianteiro_direito': 'Para-lama Dianteiro Direito',
              'peca_paralama_dianteiro_esquerdo': 'Para-lama Dianteiro Esquerdo',
              'peca_porta_dianteira_direita': 'Porta Dianteira Direita',
              'peca_porta_dianteira_esquerda': 'Porta Dianteira Esquerda',
              'peca_porta_traseira_direita': 'Porta Traseira Direita',
              'peca_porta_traseira_esquerda': 'Porta Traseira Esquerda',
              'peca_lateral_traseira_direita': 'Lateral Traseira Direita',
              'peca_lateral_traseira_esquerda': 'Lateral Traseira Esquerda',
              'peca_teto': 'Teto',
              'peca_tampa_traseira': 'Tampa Traseira',
            },
            isPintura: true,
            is3d: ai3dImage != null,
            state: wizardState,
            vistoria: vistoria,
            styles: styles,
            logo: logoImage,
            backgroundImage: ai3dImage ?? carroPinturaImage ?? bgImage,
            assinatura: assinaturaImage,
            assinaturaCliente: assinaturaClienteImage,
            showSignatures: false,
          ));
        }

        // 7. Checklist Opcional (se existir, fica antes do resumo final)
        if (wizardState?.realizarChecklistOpcional == true) {
          pdf.addPage(_buildPageChecklistOpcional(
            state: wizardState!,
            vistoria: vistoria,
            styles: styles,
            logo: logoImage,
            backgroundImage: null,
          ));
        }

        // 8. Fotos Extras, Resumo e Parecer
        addFotosMultiPage(sectionsExtras, addResumoEParecer: true);
      }
    }

    if (!hasAnyPhoto) {
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildHeader(vistoria, styles, logoImage,
                        state: wizardState),
                    pw.SizedBox(height: 6),
                    pw.Expanded(
                        child: pw.Center(
                            child: pw.Text('Nenhuma foto capturada.',
                                style: pw.TextStyle(
                                    color: PdfColors.grey600, fontSize: 10)))),
                    if ((wizardState?.parecerTecnico ?? vistoria.parecerTecnico ?? '').trim().isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      _buildParecerTecnicoBox((wizardState?.parecerTecnico ?? vistoria.parecerTecnico!).trim(), styles),
                    ],
                  ])));
    }

    // ── Ficha Técnica Inteligente (Gemini) ──────────────────────────────────
    try {
      List<String> apontamentosList = [];
      final wState = wizardState;
      if (wState != null) {
        apontamentosList = wState.checklistStatus.entries
            .where((e) {
              final status = e.value;
              final obs = wState.checklistObs[e.key] ?? '';
              final isOk = _isStatusConformeOuOk(status);
              if (isOk && obs.trim().isEmpty) return false;
              if (isOk && obs.trim().isNotEmpty) {
                final obsUpper = obs.trim().toUpperCase();
                if (_isStatusConformeOuOk(obsUpper)) return false;
              }
              return true;
            })
            .map((e) {
              final nomeLimpo = _cleanItemName(e.key);
              final obs = wState.checklistObs[e.key] ?? '';
              final valUpper = e.value.toUpperCase();
              final obsUpper = obs.toUpperCase();
              final isSemAcesso = valUpper.contains('SEM ACESSO') ||
                  valUpper.contains('SEMA ACESSO') ||
                  valUpper.contains('NÃO LOCALIZADO') ||
                  valUpper.contains('NAO LOCALIZADO') ||
                  valUpper.contains('NÃO CONSTA') ||
                  valUpper.contains('NAO CONSTA') ||
                  obsUpper.contains('SEM ACESSO') ||
                  obsUpper.contains('SEMA ACESSO');

              if (isSemAcesso) {
                return '$nomeLimpo: ${e.value} [ATENÇÃO: ITEM SEM ACESSO / NÃO É AVARIA - VALOR PEÇA R\$ 0,00 E MÃO DE OBRA R\$ 0,00]${obs.isNotEmpty ? " (Obs: $obs)" : ""}';
              }
              return '$nomeLimpo: ${e.value}${obs.isNotEmpty ? " (Obs: $obs)" : ""}';
            }).toList();
      }

      String brandStr = (veiculo.marca ?? '').trim();
      String modelStr = (veiculo.modelo ?? '').trim();
      if (brandStr.isEmpty) brandStr = 'NÃO INFORMADA';
      if (modelStr.isEmpty) modelStr = 'NÃO INFORMADO';

      final resFicha = await Supabase.instance.client.functions.invoke(
        'gerar-ficha-veiculo',
        body: {
          'brand': brandStr,
          'model': modelStr,
          'year':
              veiculo.anoFabricacao ?? veiculo.anoModelo ?? DateTime.now().year,
          'version': veiculo.modelo ?? '',
          'fuel': veiculo.combustivel ?? '',
          'engine': veiculo.motorVeiculo ?? '',
          if (apontamentosList.isNotEmpty) 'apontamentos': apontamentosList,
          'uf': veiculo.uf ?? '',
        },
      ).timeout(const Duration(seconds: 45));

      if (resFicha.status == 200 && resFicha.data != null) {
        final data =
            resFicha.data is String ? jsonDecode(resFicha.data) : resFicha.data;
        if (data != null && data['data'] != null) {
          _buildFichaTecnicaPages(pdf, data['data'], vistoria, styles,
              logoImage, assinaturaImage, wizardState);
        }
      } else {
        print('Erro Gemini (Status ${resFicha.status}): ${resFicha.data}');
      }
    } catch (e) {
      print('Erro ao gerar ficha técnica inteligente: $e');
      // Continua gerando o PDF normalmente
    }

    // ── Página de Disclaimer ─────────────────────────────────────────────────
    pw.Widget _disclaimerText(String text, _PdfStyles styles, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: bold ? styles.bold : styles.regular,
            fontSize: 9,
            color: _kBlack,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      );
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logoImage, state: wizardState),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _disclaimerText('Este laudo trata-se da vistoria cautelar do veículo, possuindo caráter informativo da análise de itens, conforme padrões estabelecidos pelos fabricantes.', styles),
                  _disclaimerText('NÃO substituindo em nenhuma hipótese a Perícia Oficial do Instituto de Criminalística.', styles, bold: true),
                  _disclaimerText('Cabe destacar que a unidade não se responsabiliza por quaisquer modificações nos itens do veículo contemplados nesta vistoria, posteriores à realização deste laudo, cuja validade tem sua garantia certificada no momento da realização da vistoria.', styles),
                  _disclaimerText('O resultado do laudo técnico segue critérios de avaliação estabelecidos, podendo sofrer alterações necessárias em determinado momento, sem prévia comunicação.', styles),
                  _disclaimerText('As informações dos veículos, obtidas através de pesquisa via base de dados dos órgãos públicos e empresas privadas, são de responsabilidade da empresa fornecedora da pesquisa, cabendo apenas reiterar os dados cadastrados nas referidas bases de consulta.', styles),
                  _disclaimerText('Ao receber este laudo, o cliente fica ciente que as companhias de seguro possuem métodos e critérios próprios de avaliação do risco para aceitação ou não de veículos.', styles),
                  _disclaimerText('Não obstante, o critério de avaliação bem como o resultado final da vistoria, independe da aceitação ou não da seguradora.', styles),
                  _disclaimerText('Importante notar que NÃO são examinados itens de mecânica, elétrica, transmissão, suspensão e freios.', styles, bold: true),
                  _disclaimerText('A análise de pintura é realizada através de medidores digitais que informam a espessura da camada de tinta, apenas em caráter informativo de retoques ou reparos expressivos em sua lataria, que não afetam a estrutura do veículo, NÃO apontamos pequenos riscos nem desgastes na pintura.', styles),
                  _disclaimerText('NÃO nos responsabilizamos por defeitos ou fraudes em equipamentos de Air-Bag.', styles, bold: true),
                  _disclaimerText('A verificação da numeração da caixa de câmbio somente é realizada se tal item está aparente, sem a necessidade de desmontar partes do veículo que tornem a gravação obstruída.', styles),
                  _disclaimerText('A vistoria cautelar não afere a idoneidade da quilometragem constante no hodômetro do veículo, sendo apenas registrado em caráter informativo a quilometragem aparente em seu painel de instrumentos.', styles),
                  _disclaimerText('Alguns itens obrigatórios e acessórios como pneus, setas, cintos e outros acessórios, são apenas informados quanto à sua existência e funcionamento mínimo, não sendo atestada calibração ou cumprimento de normas técnicas específicas.', styles),
                  _disclaimerText('A análise proposta é particular, restrita exclusivamente aos itens analisados e não à vistoria regulamentada pelo CONTRAN ou à perícia realizada pelo Instituto de Criminalística.', styles),
                  if (vistoria.tipoVistoria.toLowerCase().contains('caminh'))
                    _disclaimerText('ATENÇÃO (VEÍCULO DE CARGA): As modificações nas dimensões do chassi (alongamento ou encurtamento) estão sujeitas à regulamentação específica (Resolução CONTRAN nº 292/2008 e atualizações como a Res. 916/2022). Este laudo aponta apenas as condições aparentes da estrutura para fins de vistoria cautelar, não suprindo a exigência legal do Certificado de Segurança Veicular (CSV) nem garantindo a regularização das modificações perante o DETRAN.', styles, bold: true),
                ],
              ),
            ),
            _buildFooter(vistoria, styles, ctx, assinaturaImage,
                assinaturaCliente: assinaturaClienteImage, showSignatures: true),
          ],
        );
      },
    ));


    Uint8List finalBytes = await pdf.save();

    // ── Anexar Pesquisa (Radar) se existir (Baixando PDF / Convertendo HTML) ───
    try {
      final autocredDao = sl<AutocredDao>();
      var consulta = await autocredDao.buscarConsultaPorVistoria(vistoria.id);
      if (consulta == null && veiculo.placa.trim().isNotEmpty) {
        consulta = await autocredDao.buscarConsultaPorPlaca(veiculo.placa.trim());
      }
      if (consulta == null && (veiculo.chassiVeiculo ?? '').trim().isNotEmpty) {
        consulta = await autocredDao.buscarConsultaPorChassi((veiculo.chassiVeiculo ?? '').trim());
      }

      if (consulta != null) {
        Uint8List? bytesRadar;
        final url = consulta.arquivoPesquisaUrl;

        if (url != null && url.trim().isNotEmpty && url.startsWith('http')) {
          try {
            final dio = Dio();
            final response = await dio.get<List<int>>(
              url,
              options: Options(
                responseType: ResponseType.bytes,
                sendTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

            if (response.statusCode == 200 && response.data != null) {
              final rawBytes = Uint8List.fromList(response.data!);

              // Checa se já é PDF binário (começa com '%PDF')
              final isPdf = rawBytes.length > 4 &&
                  rawBytes[0] == 0x25 && // %
                  rawBytes[1] == 0x50 && // P
                  rawBytes[2] == 0x44 && // D
                  rawBytes[3] == 0x46; // F

              if (isPdf) {
                bytesRadar = rawBytes;
              } else {
                // Conteúdo é página HTML -> Converte para PDF ajustando margens e escala
                final htmlContent = utf8.decode(rawBytes, allowMalformed: true);
                
                // Injeta regras de CSS para garantir que tabelas e bordas caibam no A4 sem cortes
                const cssPrintFix = '''
<style>
  @page {
    size: A4 portrait;
    margin: 0 !important;
  }
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    zoom: 1.0 !important;
    max-width: 100% !important;
    width: 100% !important;
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
    box-sizing: border-box !important;
  }
  table, .table, div, .container, .row, p, span {
    max-width: 100% !important;
    box-sizing: border-box !important;
  }
</style>
''';

                String adjustedHtml = htmlContent;
                if (adjustedHtml.contains('</head>')) {
                  adjustedHtml = adjustedHtml.replaceFirst('</head>', '$cssPrintFix</head>');
                } else if (adjustedHtml.contains('<body')) {
                  adjustedHtml = adjustedHtml.replaceFirst('<body', '$cssPrintFix<body');
                } else {
                  adjustedHtml = '$cssPrintFix$adjustedHtml';
                }

                final tempDir = await getTemporaryDirectory();
                final convertedFile = await FlutterHtmlToPdf.convertFromHtmlContent(
                  adjustedHtml,
                  tempDir.path,
                  'radar_temp_${DateTime.now().millisecondsSinceEpoch}',
                );
                if (await convertedFile.exists()) {
                  bytesRadar = await convertedFile.readAsBytes();
                  try {
                    await convertedFile.delete();
                  } catch (_) {}
                }
              }
            }
          } catch (err) {
            print('Aviso ao baixar/converter HTML do Radar para PDF: $err');
          }
        }

        if (bytesRadar != null && bytesRadar.isNotEmpty) {
          final sf.PdfDocument docPrincipal = sf.PdfDocument(inputBytes: finalBytes);
          final sf.PdfDocument docRadar = sf.PdfDocument(inputBytes: bytesRadar);

          for (int i = 0; i < docRadar.pages.count; i++) {
            final sf.PdfPage templatePage = docRadar.pages[i];
            final sf.PdfPage novaPagina = docPrincipal.pages.add();
            final ui.Size clientSize = novaPagina.getClientSize();

            // Preenche 100% da largura da página alinhando com as outras páginas do laudo
            final double scale = clientSize.width / templatePage.size.width;
            final double drawWidth = clientSize.width;
            final double drawHeight = templatePage.size.height * scale;

            novaPagina.graphics.drawPdfTemplate(
              templatePage.createTemplate(),
              const ui.Offset(0, 0),
              ui.Size(drawWidth, drawHeight),
            );
          }

          finalBytes = Uint8List.fromList(docPrincipal.saveSync());
          docPrincipal.dispose();
          docRadar.dispose();
        }
      }
    } catch (e, stackTrace) {
      print('Erro ao baixar e mesclar PDF/HTML da Radar: $e');
      print('Stack trace: $stackTrace');
    }

    final dir = await getApplicationDocumentsDirectory();
    final placaClean =
        veiculo.placa.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final nomeBase =
        placaClean.isNotEmpty ? placaClean : 'Laudo_${vistoria.numeroLaudo}';
    final fileName = '$nomeBase.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(finalBytes);

    try {
      final storagePath = '${vistoria.id}/$nomeBase.pdf';
      // Removido o 'await' para que o upload ocorra em segundo plano e não trave a geração local
      Supabase.instance.client.storage.from('laudos-pdf').uploadBinary(
            storagePath,
            finalBytes,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'application/pdf'),
          );
    } catch (e) {
      print('Erro ao fazer upload do PDF para o Supabase: $e');
    }

    return file.path;
  }



  // ── Seções Compartilhadas ────────────────────────────────────────────────

  pw.Widget _buildPdfFooter(pw.Context context, _PdfStyles styles) {
    return pw.Stack(
      alignment: pw.Alignment.centerRight,
      children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('EAEAEA'),
            border: pw.Border(
                top:
                    pw.BorderSide(color: PdfColor.fromHex('F39C12'), width: 3)),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 120,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('PÁGINA ${context.pageNumber}',
                    style: pw.TextStyle(
                        font: styles.bold,
                        fontSize: 7,
                        color: PdfColors.grey700)),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(((Supabase.instance.client.auth.currentUser?.userMetadata?['name'] as String?) ?? 'APP VISTORIA').toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: styles.bold,
                            fontSize: 7,
                            color: PdfColors.grey800)),
                    pw.SizedBox(height: 2),
                    pw.FittedBox(
                        fit: pw.BoxFit.scaleDown,
                        child: pw.Text(
                            ((Supabase.instance.client.auth.currentUser?.userMetadata?['name'] as String?)?.toUpperCase().contains('AUTO PROVE') ?? false)
                                ? '24.868.718.0001-62 - RUA SETE DE ABRIL 541 CENTRO COSMOPOLIS SP - CEP 13.150.610 - TEL 19 3872-1891'
                                : '11.977.969/0001-33 - AV REBOUÇAS 1989 - SUMARÉ - SP - CEP 13170-275 - TEL 19 3306.8604',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: styles.regular,
                                fontSize: 6,
                                color: PdfColors.grey800))),
                    pw.SizedBox(height: 2),
                    pw.FittedBox(
                        fit: pw.BoxFit.scaleDown,
                        child: pw.Text(
                            ((Supabase.instance.client.auth.currentUser?.userMetadata?['name'] as String?)?.toUpperCase().contains('AUTO PROVE') ?? false)
                                ? 'COSMOPOLIS@ULTRAVISAO.COM.BR'
                                : 'SUMARE@ULTRAVISAO.COM.BR - CREDENCIAMENTO 06/2025-3651- DETRAN SP',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: styles.regular,
                                fontSize: 6,
                                color: PdfColors.grey800))),
                  ],
                ),
              ),
              pw.SizedBox(width: 120),
            ],
          ),
        ),
        if (_globalRodapeImage != null)
          pw.Positioned(
            right: 16,
            top: 2,
            bottom: 2,
            child: pw.Container(
              width: 80,
              alignment: pw.Alignment.centerRight,
              child: pw.Image(_globalRodapeImage!, fit: pw.BoxFit.contain),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildQrCodeWithPlate(String qrData, String? placa, _PdfStyles styles) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kGreyDark, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (placa != null && placa.trim().isNotEmpty) ...[
            pw.Container(
              width: 55,
              height: 22,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
                borderRadius: pw.BorderRadius.circular(2),
                color: PdfColors.white,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    height: 5,
                    color: PdfColor.fromHex('0033A0'),
                  ),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        placa,
                        style: pw.TextStyle(
                          font: styles.bold,
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                width: 50,
                height: 50,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(
      Vistoria vistoria, _PdfStyles styles, pw.ImageProvider? logo,
      {VistoriaWizardState? state, String? placa, bool showQr = false}) {
    final placaStr = placa ?? state?.placa;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo on the left side, horizontally aligned with texts
          if (logo != null)
            pw.Container(
              width: 200,
              height: 100,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          // Numero do Laudo
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('LAUDO CAUTELAR',
                    style: pw.TextStyle(
                        font: styles.bold, fontSize: 14, color: _kBlack)),
                pw.SizedBox(height: 4),
                pw.Text('Número do Laudo: ${vistoria.numeroLaudo}',
                    style: pw.TextStyle(
                        font: styles.bold, fontSize: 10, color: _kGreyDark)),
              ],
            ),
          ),
          // QR Code Estilizado (Apenas se showQr for true)
          if (showQr)
            _buildQrCodeWithPlate(
                Supabase.instance.client.storage
                    .from('laudos-pdf')
                    .getPublicUrl('${vistoria.id}/${vistoria.numeroLaudo}.pdf'),
                placaStr,
                styles),
        ],
      ),
    );
  }

  pw.Widget _buildBlackBar(String text, _PdfStyles styles) {
    return pw.Container(
      width: double.infinity,
      color: _kBlack,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text,
          style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kWhite)),
    );
  }

  pw.Widget _buildFooter(Vistoria vistoria, _PdfStyles styles, pw.Context? ctx,
      pw.ImageProvider? assinatura,
      {pw.ImageProvider? assinaturaCliente, bool showSignatures = false}) {
    if (!showSignatures) return pw.SizedBox.shrink();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    height: 35,
                    child: pw.Stack(
                      alignment: pw.Alignment.bottomCenter,
                      children: [
                        pw.Positioned(
                          bottom: 0,
                          child: pw.Container(
                              width: 150, height: 1, color: _kBlack),
                        ),
                        if (assinatura != null)
                          pw.Positioned.fill(
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Center(
                                child: pw.Image(assinatura,
                                    fit: pw.BoxFit.contain,
                                    alignment: pw.Alignment.center),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      vistoria.vistoriadorNome?.toUpperCase() ?? 'VISTORIADOR',
                      style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('CPF: ${_maskCpf(vistoria.vistoriadorCpf)}',
                      style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('Vistoriador',
                      style: pw.TextStyle(font: styles.regular, fontSize: 7)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    height: 35,
                    child: pw.Stack(
                      alignment: pw.Alignment.bottomCenter,
                      children: [
                        pw.Positioned(
                          bottom: 0,
                          child: pw.Container(
                              width: 150, height: 1, color: _kBlack),
                        ),
                        if (assinaturaCliente != null)
                          pw.Positioned.fill(
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Center(
                                child: pw.Image(assinaturaCliente,
                                    fit: pw.BoxFit.contain,
                                    alignment: pw.Alignment.center),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      (vistoria.clienteNome != null &&
                              vistoria.clienteNome!.trim().isNotEmpty)
                          ? vistoria.clienteNome!.toUpperCase()
                          : 'CLIENTE',
                      style: pw.TextStyle(font: styles.bold, fontSize: 7)),
                  pw.Text('Cliente',
                      style: pw.TextStyle(font: styles.regular, fontSize: 6)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Página 1 ─────────────────────────────────────────────────────────────

  Future<pw.Page> _buildPage1Historico({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? state,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    pw.ImageProvider? marcaAgua,
    RadarVeiculo? radarVeiculo,
    Map<String, dynamic>? dadosConsultaJson,
  }) async {
    final bgColor =
        PdfColor.fromHex('0B3B24'); // Verde muito escuro (cabeçalho)
    final bannerColor = PdfColor.fromHex('1F5E3D');
    final iconBlockGreen = PdfColor.fromHex('1F5E3D');
    final iconBlockRed = PdfColor.fromHex('C62828');
    final iconBlockYellow = PdfColor.fromHex('D97706');
    final zebraGrey = PdfColor.fromHex('F5F5F5');
    final greyBorder = PdfColor.fromHex('E0E0E0');
    final textColor = PdfColor.fromHex('424242');
    final limeGreen = PdfColor.fromHex('8CC63F');
    final warningYellow = PdfColor.fromHex('FBB03B');
    final dangerRed = PdfColor.fromHex('EE4036');

    String computedStatus = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        computedStatus = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        computedStatus = state.statusSugerido;
      }
    }
    PdfColor statusColor = warningYellow;
    String statusIcon =
        '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    String upStatus = computedStatus.toUpperCase();
    if (upStatus.contains('NÃO CONFORME') ||
        upStatus.contains('REPROVADO') ||
        upStatus.contains('NAO CONFORME')) {
      statusColor = dangerRed;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    } else if (upStatus.contains('APONTAMENTOS') ||
        upStatus.contains('OBSERVA')) {
      statusColor = warningYellow;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    } else if (upStatus.contains('CONFORME') || upStatus == 'APROVADO') {
      statusColor = limeGreen;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    } else {
      statusColor = limeGreen;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    }

    int getStatusCategory(String rawStatus) {
      final s = rawStatus.toLowerCase().trim();
      if (s.isEmpty) return 0;
      if (s.contains('divergente') ||
          s.contains('adulteração') ||
          s.contains('reprovado') ||
          s.contains('não original') ||
          s.contains('substituído') ||
          s.contains('ausente') ||
          s.contains('danificad') ||
          s.contains('colisão') ||
          s.contains('ilegível') ||
          s.contains('não localizad') ||
          s.contains('não conforme')) return 2;
      if (s.contains('reparo') ||
          s.contains('repintura') ||
          s.contains('observação') ||
          s.contains('envelopado') ||
          s.contains('amassado') ||
          s.contains('riscado') ||
          s.contains('soldado') ||
          s.contains('avaria') ||
          s.contains('massa') ||
          s.contains('obstruído') ||
          s.contains('alongado') ||
          s.contains('consideração') ||
          s.contains('sem acesso') ||
          s.contains('inexistente') ||
          s.contains('remarcad')) return 1;
      return 0;
    }

    int countConforme = 0;
    int countObs = 0;
    int countNaoConforme = 0;
    final Map<String, List<Map<String, dynamic>>> grupos = {
      'IDENTIFICAÇÃO': [],
      'ESTRUTURA': [],
      'PINTURA E LATARIA': []
    };
    final bool avaliarPintura = state?.realizarAvaliacaoPintura ?? false;
    if (state != null) {
      for (final entry in state.checklistStatus.entries) {
        final id = entry.key;
        final rawStatus = entry.value;
        final nome = _cleanItemName(id);
        if (nome.contains('OPCIONAL')) continue;
        if (rawStatus.toUpperCase() == 'NÃO ANALISADO' || rawStatus.trim().isEmpty) continue;
        final isPintura = id.startsWith('peca_');
        if (isPintura && !avaliarPintura) continue;

        final cat = getStatusCategory(rawStatus);
        if (cat == 0)
          countConforme++;
        else if (cat == 1)
          countObs++;
        else
          countNaoConforme++;
        final itemMap = {'nome': nome, 'status': cat, 'id': id};
        if (id.startsWith('chassi') ||
            id.startsWith('motor') ||
            id.startsWith('cambio') ||
            id.startsWith('vidro') ||
            id.startsWith('etiqueta') ||
            id.startsWith('painel_hodometro') ||
            id.startsWith('foto_placa') ||
            id.startsWith('compartimento_motor')) {
          grupos['IDENTIFICAÇÃO']!.add(itemMap);
        } else if (id.startsWith('longarina') ||
            id.startsWith('caixa') ||
            id.startsWith('coluna') ||
            id.startsWith('painel') ||
            id.startsWith('torre') ||
            id.startsWith('assoalho')) {
          grupos['ESTRUTURA']!.add(itemMap);
        } else {
          if (avaliarPintura) {
            grupos['PINTURA E LATARIA']!.add(itemMap);
          }
        }
      }
    }
    final int totalItens = countConforme + countObs + countNaoConforme;

    // Material SVGs
    final String svgCarShield =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/></svg>';
    final String svgReceipt =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M18 17H6v-2h12v2zm0-4H6v-2h12v2zm0-4H6V7h12v2zM3 22l1.5-1.5L6 22l1.5-1.5L9 22l1.5-1.5L12 22l1.5-1.5L15 22l1.5-1.5L18 22l1.5-1.5L21 22V2l-1.5 1.5L18 2l-1.5 1.5L15 2l-1.5 1.5L12 2l-1.5 1.5L9 2 7.5 3.5 6 2 4.5 3.5 3 2v20z"/></svg>';
    final String svgHammer =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M21 16h-3v-2h-3l2.87-2.87c.39-.39.39-1.03 0-1.42l-5.58-5.58c-.39-.39-1.03-.39-1.42 0L5 10c-.39.39-.39 1.03 0 1.42l5.58 5.58c.39.39 1.03.39 1.42 0L14.87 14H16v2H13v3h8v-3z"/></svg>';
    final String svgShieldSearch =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm4.14 15.36l-1.92-1.92c-.67.48-1.5.76-2.39.76-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4c0 .89-.28 1.72-.76 2.39l1.92 1.92-1.43 1.43zM11.83 9c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>';
    final String svgCarWarning =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    final String svgSpeedometer =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm4.59-12.42L15.17 6.17c-.39-.39-1.02-.39-1.41 0l-5.66 5.66c-.39.39-.39 1.02 0 1.41l1.41 1.41c.39.39 1.02.39 1.41 0l5.66-5.66c.39-.39.39-1.02 0-1.41z"/></svg>';
    final String svgHandshake =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>';
    final String svgTaxi =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5H15V3H9v2H6.5c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/></svg>';
    final String svgCalendar =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11z"/></svg>';
    final String svgCarWrench =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M22.7 19l-9.1-9.1c.52-1.17.4-2.51-.54-3.46-1.1-1.1-2.69-1.4-4.09-.9l2.54 2.54-2.12 2.12-2.54-2.54c-.5 1.4-.2 2.99.9 4.09.95.95 2.29 1.07 3.46.54l9.1 9.1c.39.39 1.02.39 1.41 0l.98-.98c.39-.39.39-1.03 0-1.41z"/></svg>';
    final String svgWarningTriangle =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    final String svgBank =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M12 1L3 5v2h18V5l-9-4zm-2 15h4V9h-4v7zm-5 0h4V9H5v7zm10 0h4V9h-4v7zM2 19h20v2H2v-2z"/></svg>';
    final String svgLeilao =
        '<svg viewBox="0 0 512 512"><path fill="{color}" d="M222.716,311.307l-109.3-84.325c-8.698-6.709-21.195-5.09-27.898,3.602c-6.708,8.691-5.103,21.189,3.601,27.898l109.293,84.318c8.705,6.708,21.196,5.103,27.905-3.595C233.026,330.506,231.414,318.015,222.716,311.307z"/><path fill="{color}" d="M236.318,67.662l109.307,84.318c8.698,6.716,21.189,5.104,27.898-3.594c6.709-8.698,5.097-21.182-3.601-27.898l-109.3-84.324c-8.698-6.709-21.189-5.09-27.898,3.601C226.015,48.462,227.628,60.954,236.318,67.662z"/><polygon fill="{color}" points="226.824,78.068 122.491,213.304 233.65,299.048 337.977,163.812"/><path fill="{color}" d="M501.529,363.144l-185.626-143.2l-32.864,42.598l185.633,143.2c11.764,9.075,28.652,6.901,37.72-4.864C515.474,389.107,513.293,372.219,501.529,363.144z"/><path fill="{color}" d="M186.936,409.748c0-14.274-11.565-25.847-25.84-25.847H39.689c-14.274,0-25.84,11.572-25.84,25.847v19.166h173.087V409.748z"/><rect fill="{color}" x="0" y="445.143" width="200.786" height="34.833"/></svg>';
    final String svgLock =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/></svg>';
    final String svgChassis =
        '<svg viewBox="0 0 24 24"><path fill="{color}" d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/></svg>';

    pw.Widget buildBlock(String title, String bgType, String svgRaw) {
      PdfColor blockBgColor = PdfColors.white;
      PdfColor blockTextColor = textColor;
      PdfColor blockIconColor = textColor;
      pw.BoxBorder? border;

      if (bgType == 'green') {
        blockBgColor = iconBlockGreen;
        blockTextColor = PdfColors.white;
      } else if (bgType == 'red') {
        blockBgColor = iconBlockRed;
        blockTextColor = PdfColors.white;
      } else if (bgType == 'yellow') {
        blockBgColor = iconBlockYellow;
        blockTextColor = PdfColors.white;
      } else if (bgType == 'white') {
        blockBgColor = PdfColors.white;
        blockTextColor = textColor;
        border = pw.Border.all(color: greyBorder, width: 1);
      }

      final String finalSvg = svgRaw.replaceAll(
          '{color}', bgType == 'white' ? '#424242' : '#ffffff');

      // Calculate block width for 3 items per row: (A4 width 595 - 40px margins - 2*6px spacing) / 3 = 181
      return pw.Container(
        width: 181,
        height: 62,
        decoration: pw.BoxDecoration(
          color: blockBgColor,
          border: border,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SvgImage(svg: finalSvg, height: 26),
            pw.SizedBox(height: 6),
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  color: blockTextColor, font: styles.bold, fontSize: 8),
            ),
          ],
        ),
      );
    }

    pw.Widget buildRow(String label1, String value1, String label2,
        String value2, bool isZebra) {
      return pw.Container(
        color: isZebra ? zebraGrey : PdfColors.white,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(label1,
                  style: pw.TextStyle(
                      font: styles.bold, fontSize: 9, color: textColor)),
            ),
            pw.Expanded(
              flex: 4,
              child: pw.Text(value1,
                  style: pw.TextStyle(
                      font: styles.bold, fontSize: 9, color: textColor)),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(label2,
                  style: pw.TextStyle(
                      font: styles.bold, fontSize: 9, color: textColor)),
            ),
            pw.Expanded(
              flex: 4,
              child: pw.Text(value2,
                  style: pw.TextStyle(
                      font: styles.bold, fontSize: 9, color: textColor)),
            ),
          ],
        ),
      );
    }

    pw.Widget buildBanner(String text) {
      return pw.Container(
        width: double.infinity,
        color: bannerColor,
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
              color: PdfColors.white, font: styles.bold, fontSize: 10),
        ),
      );
    }

    final qrCodeUrl = Supabase.instance.client.storage
        .from('laudos-pdf')
        .getPublicUrl('${vistoria.id}/${vistoria.numeroLaudo}.pdf');

    // Radar Logic
    final Map<String, dynamic> res = {
      if (dadosConsultaJson != null) ...dadosConsultaJson,
      ...?radarVeiculo?.resultadoCompleto,
    };

    final String? Function(List<dynamic>) getFirstValid = (List<dynamic> list) {
      for (final item in list) {
        if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty &&
              str.toUpperCase() != 'NÃO INFORMADO' &&
              str.toUpperCase() != 'NÃO INFORMADA' &&
              str != '-' &&
              str.toLowerCase() != 'null') {
            return str;
          }
        }
      }
      return null;
    };

    final valPlaca = getFirstValid([veiculo.placa, state?.placa, res['placa']])
            ?.toUpperCase() ??
        'NÃO INFORMADA';

    final rawAnoFab = getFirstValid([
      veiculo.anoFabricacao,
      state?.anoFabricacao,
      res['ano_fabricacao'],
      res['anofabricacao'],
      res['ano_fab'],
      res['anoFab']
    ]);
    final rawAnoMod = getFirstValid([
      veiculo.anoModelo,
      state?.anoModelo,
      res['ano_modelo'],
      res['anomodelo'],
      res['ano_mod'],
      res['anoModelo']
    ]);
    final valAno = (rawAnoFab != null && rawAnoMod != null)
        ? '$rawAnoFab/$rawAnoMod'
        : (rawAnoFab ?? rawAnoMod ?? 'NÃO INFORMADO');

    final valRenavam =
        getFirstValid([veiculo.renavam, state?.renavam, res['renavam']])
                ?.toUpperCase() ??
            'NÃO INFORMADO';

    final rawMarcaModelo =
        getFirstValid([res['marca_modelo'], res['marcamodelo']]);
    final parsedMM = VeiculoParser.extrairMarcaModelo(rawMarcaModelo);
    final fallbackMarca = parsedMM.marca.isNotEmpty ? parsedMM.marca : null;
    final fallbackModelo = parsedMM.modelo.isNotEmpty ? parsedMM.modelo : null;

    final valMarca = getFirstValid(
                [veiculo.marca, state?.marca, res['marca'], fallbackMarca])
            ?.toUpperCase() ??
        'NÃO INFORMADA';
    final valModelo = getFirstValid(
                [veiculo.modelo, state?.modelo, res['modelo'], fallbackModelo])
            ?.toUpperCase() ??
        'NÃO INFORMADO';

    final valChassi = getFirstValid([
          veiculo.chassiVeiculo,
          veiculo.chassiBin,
          state?.chassiVeiculo,
          state?.chassiBin,
          res['chassi'],
          res['chassi_bin'],
          res['chassiremark']
        ])?.toUpperCase() ??
        'NÃO INFORMADO';
    final valMotor = getFirstValid([
          veiculo.motorVeiculo,
          veiculo.motorBin,
          state?.motorVeiculo,
          state?.motorBin,
          res['motor'],
          res['motor_bin']
        ])?.toUpperCase() ??
        'NÃO INFORMADO';
    final valCor =
        getFirstValid([veiculo.cor, state?.cor, res['cor'], res['cor_veiculo']])
                ?.toUpperCase() ??
            'NÃO INFORMADA';
    final valCombustivel = getFirstValid(
                [veiculo.combustivel, state?.combustivel, res['combustivel']])
            ?.toUpperCase() ??
        'NÃO INFORMADO';
    final valCategoria =
        getFirstValid([res['categoria'], veiculo.tipo])?.toUpperCase() ??
            'PARTICULAR';

    bool isPositiveValue(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val > 0;
      if (val is List) {
        if (val.isEmpty) return false;
        for (final elem in val) {
          if (isPositiveValue(elem)) return true;
        }
        return false;
      }
      if (val is Map) {
        if (val.isEmpty) return false;
        if (val.containsKey('quantidadeRestricoesAtivas') &&
            val['quantidadeRestricoesAtivas'] is num &&
            val['quantidadeRestricoesAtivas'] > 0) {
          return true;
        }
        if (val.containsKey('restricoesJudiciais') &&
            isPositiveValue(val['restricoesJudiciais'])) {
          return true;
        }
        for (final elem in val.values) {
          if (isPositiveValue(elem)) return true;
        }
        return false;
      }
      final str = val.toString().trim().toUpperCase();
      if (str.isEmpty) return false;
      if (str == 'NÃO' ||
          str == 'NAO' ||
          str == 'FALSE' ||
          str == '0' ||
          str == 'NADA CONSTA' ||
          str == 'NÃO CONSTA' ||
          str == 'NAO CONSTA' ||
          str == 'NÃO POSSUI' ||
          str == 'NAO POSSUI' ||
          str == 'SEM RESTRICAO' ||
          str == 'SEM RESTRIÇÃO' ||
          str == 'NENHUMA' ||
          str == 'NENHUM' ||
          str == 'NENHUM REGISTRO ENCONTRADO.' ||
          str == 'NENHUM REGISTRO ENCONTRADO' ||
          str == '-' ||
          str.contains('SEM OCORRENCIA') ||
          str.contains('SEM OCORRÊNCIA') ||
          str.contains('NÃO POSSUI RESTRIÇÃO') ||
          str.contains('NAO POSSUI RESTRICAO') ||
          str.contains('NÃO FOI ENCONTRADO') ||
          str.contains('NAO FOI ENCONTRADO') ||
          str.contains('NÃO POSSUÍ INDÍCIO DE SINISTRO') ||
          str.contains('NAO POSSUI INDICIO DE SINISTRO') ||
          str.contains('QUANTIDADE DE PESQUISAS') ||
          str.contains('FORNECEDOR INDISPONÍVEL') ||
          str.contains('FORNECEDOR INDISPONIVEL')) {
        return false;
      }
      return true;
    }

    dynamic findVal(dynamic node, List<String> targetKeys) {
      if (node == null) return null;
      if (node is Map) {
        for (final key in targetKeys) {
          final kLower = key.toLowerCase();
          for (final entry in node.entries) {
            if (entry.key.toString().toLowerCase() == kLower) {
              if (entry.value != null) return entry.value;
            }
          }
        }
        for (final val in node.values) {
          final found = findVal(val, targetKeys);
          if (found != null) return found;
        }
      } else if (node is List) {
        for (final elem in node) {
          final found = findVal(elem, targetKeys);
          if (found != null) return found;
        }
      }
      return null;
    }

    bool checkAnyKey(List<String> keys) {
      final val = findVal(res, keys);
      return isPositiveValue(val);
    }

    bool detectLeilao(dynamic node) {
      if (node == null) return false;
      if (node is Map) {
        for (final entry in node.entries) {
          final k = entry.key.toString().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
          final v = entry.value;

          if (k == 'possuileilao' ||
              k == 'leilao' ||
              k == 'leilao1' ||
              k == 'leilao2' ||
              k == 'ofertasleilao1' ||
              k == 'ofertasleilao2' ||
              k == 'ofertasleilao' ||
              k == 'pesquisasleilao' ||
              k == 'indicadorleilao' ||
              k == 'constaleilao' ||
              k == 'historicoleilao' ||
              k == 'leiloes' ||
              k == 'leiloeiro' ||
              k == 'comitente' ||
              k == 'comitenteleilao' ||
              k == 'dataleilao' ||
              k == 'remarketing') {
            if (isPositiveValue(v)) return true;
          }

          if (k == 'title' || k == 'titulo' || k == 'nome') {
            final titleStr = v.toString().toLowerCase();
            if (titleStr.contains('leilao') || titleStr.contains('leilão') || titleStr.contains('remarketing')) {
              final retorno = node['retorno'] ?? node['resultado'] ?? node['dados'] ?? node['data'] ?? node['valor'];
              if (isPositiveValue(retorno)) return true;
            }
          }
        }
        for (final val in node.values) {
          if (detectLeilao(val)) return true;
        }
      } else if (node is List) {
        for (final elem in node) {
          if (detectLeilao(elem)) return true;
        }
      } else if (node is String) {
        final s = node.toUpperCase();
        if ((s.contains('CONSTA LEILÃO') ||
             s.contains('CONSTA LEILAO') ||
             s.contains('RECUPERADO DE LEILÃO') ||
             s.contains('RECUPERADO DE LEILAO') ||
             s.contains('VEÍCULO DE LEILÃO') ||
             s.contains('VEICULO DE LEILAO') ||
             s.contains('HISTÓRICO DE LEILÃO: SIM') ||
             s.contains('HISTORICO DE LEILAO: SIM') ||
             s.contains('COM OCORRÊNCIA DE LEILÃO') ||
             s.contains('COM OCORRENCIA DE LEILAO') ||
             s.contains('POSSUI LEILÃO') ||
             s.contains('POSSUI LEILAO')) &&
            !s.contains('NÃO FOI ENCONTRADO') &&
            !s.contains('NAO FOI ENCONTRADO') &&
            !s.contains('NÃO POSSUI') &&
            !s.contains('NAO POSSUI') &&
            !s.contains('NADA CONSTA') &&
            !s.contains('QUANTIDADE DE PESQUISAS')) {
          return true;
        }
      }
      return false;
    }

    bool detectSinistro(dynamic node) {
      if (node == null) return false;
      if (node is Map) {
        for (final entry in node.entries) {
          final k = entry.key.toString().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
          final v = entry.value;

          if (k == 'sinistro' ||
              k == 'sinistrobase' ||
              k == 'indiciosinistro' ||
              k == 'analisetecnica' ||
              k == 'constasinistro' ||
              k == 'historicosinistro' ||
              k == 'sinistros' ||
              k == 'perdatotal' ||
              k == 'indenizacaointegral' ||
              k == 'mediamonta' ||
              k == 'grandemonta' ||
              k == 'pequenamonta') {
            if (isPositiveValue(v)) return true;
          }

          if (k == 'title' || k == 'titulo' || k == 'nome') {
            final titleStr = v.toString().toLowerCase();
            if (titleStr.contains('sinistro') || titleStr.contains('indício de sinistro') || titleStr.contains('indicio de sinistro')) {
              final retorno = node['retorno'] ?? node['resultado'] ?? node['dados'] ?? node['data'] ?? node['valor'];
              if (isPositiveValue(retorno)) return true;
            }
          }
        }
        for (final val in node.values) {
          if (detectSinistro(val)) return true;
        }
      } else if (node is List) {
        for (final elem in node) {
          if (detectSinistro(elem)) return true;
        }
      } else if (node is String) {
        final s = node.toUpperCase();
        if ((s.contains('INDÍCIO DE SINISTRO') ||
             s.contains('INDICIO DE SINISTRO') ||
             s.contains('CONSTA SINISTRO') ||
             s.contains('COM REGISTRO DE SINISTRO') ||
             s.contains('INDENIZAÇÃO INTEGRAL') ||
             s.contains('INDENIZACAO INTEGRAL') ||
             s.contains('MÉDIA MONTA') ||
             s.contains('MEDIA MONTA') ||
             s.contains('GRANDE MONTA')) &&
            !s.contains('NÃO POSSUÍ INDÍCIO DE SINISTRO') &&
            !s.contains('NAO POSSUI INDICIO DE SINISTRO') &&
            !s.contains('NÃO FOI ENCONTRADO') &&
            !s.contains('NAO FOI ENCONTRADO') &&
            !s.contains('NÃO POSSUI') &&
            !s.contains('NAO POSSUI') &&
            !s.contains('NADA CONSTA') &&
            !s.contains('FORNECEDOR INDISPONÍVEL') &&
            !s.contains('FORNECEDOR INDISPONIVEL')) {
          return true;
        }
      }
      return false;
    }

    bool normalizerHasLeilao = false;
    bool normalizerHasSinistro = false;
    try {
      final jsonStr = jsonEncode(res);
      final norm = RadarNormalizer.parse(jsonStr);
      normalizerHasLeilao = norm.leiloes.hasData || (norm.leiloes.dados != null && norm.leiloes.dados!.isNotEmpty);
      normalizerHasSinistro = norm.sinistros.hasData || (norm.sinistros.dados != null && norm.sinistros.dados!.isNotEmpty);
    } catch (_) {}

    // Evaluate blocks
    final bool hasRenajud = checkAnyKey([
      'renajud',
      'restricaorenajud',
      'restricoesrenajud',
      'possuirestricaorenajud',
      'restricao_renajud',
      'indicadorrestricaorenajud'
    ]);

    final bool hasOutrasRestricoes = checkAnyKey([
      'ind_restricoes',
      'indrestricoes',
      'restricaotributaria',
      'restricaojudicial',
      'restricaoambiental',
      'restricaoadministrativa',
      'restricaorfb',
      'restricoesbloqueioguincho',
      'restricoesfurto',
      'restricao1',
      'restricao2',
      'restricao3',
      'restricao4',
      'restricao1_br',
      'restricao2_br',
      'restricao3_br',
      'restricao4_br'
    ]);

    final bool hasFinanciamento = checkAnyKey([
      'restricaofinanceira',
      'restricoesfinanceiras',
      'alienacao',
      'indica_alienacao',
      'gravame',
      'tipoarrendatario',
      'nomearrendatario',
      'financiamento'
    ]);

    final bool hasLeilao = checkAnyKey([
      'possuileilao',
      'leilao',
      'leilao1',
      'leilao2',
      'ofertasleilao1',
      'ofertasleilao2',
      'remarketing',
      'indicadorleilao'
    ]) || detectLeilao(res) || normalizerHasLeilao;

    final bool hasSinistro = checkAnyKey([
      'sinistro',
      'sinistro_base',
      'indicio_sinistro',
      'analisetecnica'
    ]) || detectSinistro(res) || normalizerHasSinistro;

    final bool hasRoubo = checkAnyKey([
      'roubofurto',
      'roubo_furto',
      'queixaderoubo',
      'queixa_roubo',
      'historico_roubo_furto'
    ]);

    final bool hasDebitos = checkAnyKey([
      'debitos',
      'multas',
      'debitos_multas',
      'debitomultas',
      'debitosipva',
      'debitolicenciamento',
      'debitosmultas',
      'indica_debitos_multas',
      'indica_debitos_ipva'
    ]);

    final bool hasComunicacao = checkAnyKey([
      'comunicacaovenda',
      'comunicadovenda'
    ]);

    final bool hasRecall = checkAnyKey(['recall']);
    final bool hasHistoricoKm = res['historico_km'] != null &&
        res['historico_km'] != 'NADA CONSTA' &&
        res['historico_km'] != 'NÃO CONSTA';
    final bool hasTaxiLocadora = res['taxi_locadora'] != null &&
        res['taxi_locadora'] != 'NÃO CONSTA' &&
        res['taxi_locadora'] != 'NADA CONSTA';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0), // Full bleed for header
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            if (marcaAgua != null)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.10,
                    child: pw.Image(marcaAgua),
                  ),
                ),
              ),
            pw.Column(
              children: [
                // Top Green Header
                pw.Container(
                  color: bgColor,
                  padding: const pw.EdgeInsets.only(
                      top: 15, left: 20, right: 20, bottom: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo and Title
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logo != null) pw.Image(logo, height: 85),
                          if (logo == null)
                            pw.Text(((Supabase.instance.client.auth.currentUser?.userMetadata?['name'] as String?) ?? 'APP VISTORIA').toUpperCase(),
                                style: pw.TextStyle(
                                    color: PdfColors.white,
                                    font: styles.bold,
                                    fontSize: 24)),
                        ],
                      ),
                      // Parecer Final in Header
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('F9F9F9'),
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(
                                color: PdfColors.grey300, width: 1),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 40,
                                height: 40,
                                decoration: pw.BoxDecoration(
                                    color: statusColor,
                                    shape: pw.BoxShape.circle),
                                child: pw.Center(
                                    child: pw.SvgImage(
                                        svg: statusIcon,
                                        width: 20,
                                        height: 20)),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text('PARECER FINAL DA VISTORIA',
                                        style: pw.TextStyle(
                                            font: styles.bold,
                                            fontSize: 9,
                                            color: PdfColors.grey600)),
                                    pw.SizedBox(height: 2),
                                    pw.Text(computedStatus.toUpperCase(),
                                        style: pw.TextStyle(
                                            font: styles.bold,
                                            fontSize: 14,
                                            color: PdfColors.black)),
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                        (state?.parecerTecnico != null && state!.parecerTecnico!.isNotEmpty)
                                            ? state!.parecerTecnico!.trim()
                                            : 'Conclusão baseada na análise dos itens',
                                        style: pw.TextStyle(
                                            font: styles.regular,
                                            fontSize: 7,
                                            color: PdfColors.grey700),
                                        maxLines: 4,
                                        overflow: pw.TextOverflow.clip),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Auto Score Card and CNPJ
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            padding: const pw.EdgeInsets.all(6),
                            width: 190,
                            child: pw.Row(
                                children: [
                                  _buildQrCodeWithPlate(qrCodeUrl, radarVeiculo?.placa ?? veiculo.placa, styles),
                                  pw.SizedBox(width: 8),
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.center,
                                      children: [
                                        pw.Text(
                                          (() {
                                            final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
                                            final metaUnidade = (meta?['unidade'] as String?) ??
                                                (meta?['empresa'] as String?) ??
                                                (meta?['name'] as String?);
                                            if (metaUnidade != null && metaUnidade.trim().isNotEmpty) {
                                              return metaUnidade.trim().toUpperCase();
                                            }
                                            if (state?.unidade != null && state!.unidade.trim().isNotEmpty) {
                                              return state.unidade.trim().toUpperCase();
                                            }
                                            if (vistoria.unidade != null && vistoria.unidade!.trim().isNotEmpty) {
                                              return vistoria.unidade!.trim().toUpperCase();
                                            }
                                            return 'SUMARÉ VISTORIAS';
                                          })(),
                                          style: pw.TextStyle(
                                              font: styles.bold,
                                              fontSize: 10,
                                              color: bannerColor),
                                          maxLines: 1),
                                      pw.Divider(color: greyBorder),
                                      pw.Text('CÓDIGO: ${vistoria.numeroLaudo}',
                                          style: pw.TextStyle(
                                              fontSize: 8, font: styles.bold)),
                                      pw.Text(
                                          'DATA: ${vistoria.dataHora.day.toString().padLeft(2, '0')}/${vistoria.dataHora.month.toString().padLeft(2, '0')}/${vistoria.dataHora.year}',
                                          style: pw.TextStyle(
                                              fontSize: 8, font: styles.bold)),
                                      pw.Text(
                                          'PERITO: ${vistoria.vistoriadorNome?.split(' ').first ?? ''}',
                                          style: pw.TextStyle(
                                              fontSize: 8, font: styles.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content below header with normal margins
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: pw.Column(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: _buildClientAndVehicleData(vistoria, state,
                                veiculo, radarVeiculo, styles, limeGreen)),
                        buildBanner(
                            'INFORMAÇÕES BASEADAS NA CONSULTA AO VEÍCULO'),

                        // Grid of 8 Blocks
                        pw.Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: pw.WrapAlignment.start,
                          children: [

                            buildBlock(
                                'LEILÃO /\nSINISTRO',
                                (hasLeilao || hasSinistro) ? 'red' : 'green',
                                svgLeilao),
                            buildBlock('HISTÓRICO\nDE FURTO',
                                hasRoubo ? 'red' : 'green', svgShieldSearch),
                            buildBlock('ROUBO /\nFURTO',
                                hasRoubo ? 'red' : 'green', svgCarWarning),
                            buildBlock('RENAJUD',
                                hasRenajud ? 'red' : 'green', svgLock),

                            buildBlock('ALERTA DE\nINDÍCIO', 'green',
                                svgWarningTriangle),
                            (() {
                              String color = 'green';
                              if (grupos['ESTRUTURA']!.any((item) => item['status'] == 2)) {
                                color = 'red';
                              } else if (grupos['ESTRUTURA']!.any((item) => item['status'] == 1)) {
                                color = 'yellow';
                              }
                              return buildBlock('ESTRUTURA', color, svgChassis);
                            })(),
                          ],
                        ),

                        pw.SizedBox(height: 6),
                        _buildSituacaoGeralRow(
                            countConforme,
                            countObs,
                            countNaoConforme,
                            styles,
                            limeGreen,
                            warningYellow,
                            dangerRed),
                        pw.SizedBox(height: 6),
                        _buildBanner('ITENS ANALISADOS', styles),
                        pw.SizedBox(height: 6),
                        pw.Expanded(
                            child: (grupos['IDENTIFICAÇÃO']!.isEmpty &&
                                    grupos['ESTRUTURA']!.isEmpty &&
                                    grupos['PINTURA E LATARIA']!.isEmpty)
                                ? pw.SizedBox()
                                : pw.FittedBox(
                                    fit: pw.BoxFit.scaleDown,
                                    alignment: pw.Alignment.topCenter,
                                    child: pw.Container(
                                        width: PdfPageFormat.a4.width - 32,
                                        child: pw.Row(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              if (grupos['IDENTIFICAÇÃO']!
                                                  .isNotEmpty)
                                                _buildCategoryColumn(
                                                    'IDENTIFICAÇÃO',
                                                    grupos['IDENTIFICAÇÃO']!,
                                                    styles,
                                                    limeGreen,
                                                    warningYellow,
                                                    dangerRed),
                                              if (grupos['IDENTIFICAÇÃO']!
                                                      .isNotEmpty &&
                                                  (grupos['ESTRUTURA']!
                                                          .isNotEmpty ||
                                                      grupos['PINTURA E LATARIA']!
                                                          .isNotEmpty))
                                                pw.Container(
                                                    width: 0.5,
                                                    height: 80,
                                                    color: PdfColors.grey200),
                                              if (grupos['ESTRUTURA']!
                                                  .isNotEmpty)
                                                _buildCategoryColumn(
                                                    'ESTRUTURA',
                                                    grupos['ESTRUTURA']!,
                                                    styles,
                                                    limeGreen,
                                                    warningYellow,
                                                    dangerRed,
                                                    numColumns: 2,
                                                    flex: 2),
                                              if (grupos['ESTRUTURA']!
                                                      .isNotEmpty &&
                                                  grupos['PINTURA E LATARIA']!
                                                      .isNotEmpty)
                                                pw.Container(
                                                    width: 0.5,
                                                    height: 80,
                                                    color: PdfColors.grey200),
                                              if (grupos['PINTURA E LATARIA']!
                                                  .isNotEmpty)
                                                _buildCategoryColumn(
                                                    'PINTURA E LATARIA',
                                                    grupos[
                                                        'PINTURA E LATARIA']!,
                                                    styles,
                                                    limeGreen,
                                                    warningYellow,
                                                    dangerRed),
                                            ])))),

                        // Removed disclaimer as per user request
                      ],
                    ),
                  ),
                ),
                _buildPdfFooter(context, styles),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<pw.Page> _buildPage1Modern({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? state,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    pw.ImageProvider? marcaAgua,
  }) async {
    String computedStatus = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        computedStatus = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        computedStatus = state.statusSugerido;
      }
    }
    final limeGreen = PdfColor.fromHex('8CC63F');
    final warningYellow = PdfColor.fromHex('FBB03B');
    final dangerRed = PdfColor.fromHex('EE4036');

    PdfColor statusColor = warningYellow;
    String statusIcon =
        '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    String upStatus = computedStatus.toUpperCase();
    if (upStatus.contains('NÃO CONFORME') ||
        upStatus.contains('REPROVADO') ||
        upStatus.contains('NAO CONFORME')) {
      statusColor = dangerRed;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    } else if (upStatus.contains('APONTAMENTOS') ||
        upStatus.contains('OBSERVA')) {
      statusColor = warningYellow;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    } else if (upStatus.contains('CONFORME') || upStatus == 'APROVADO') {
      statusColor = limeGreen;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    } else {
      statusColor = limeGreen;
      statusIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    }

    int getStatusCategory(String rawStatus) {
      final s = rawStatus.toLowerCase().trim();
      if (s.isEmpty) return 0;

      if (s.contains('divergente') ||
          s.contains('adulteração') ||
          s.contains('reprovado') ||
          s.contains('não original') ||
          s.contains('substituído') ||
          s.contains('ausente') ||
          s.contains('danificad') ||
          s.contains('colisão') ||
          s.contains('ilegível') ||
          s.contains('não localizad') ||
          s.contains('não conforme')) {
        return 2;
      }

      if (s.contains('reparo') ||
          s.contains('repintura') ||
          s.contains('observação') ||
          s.contains('envelopado') ||
          s.contains('amassado') ||
          s.contains('riscado') ||
          s.contains('soldado') ||
          s.contains('avaria') ||
          s.contains('massa') ||
          s.contains('obstruído') ||
          s.contains('alongado') ||
          s.contains('consideração') ||
          s.contains('sem acesso') ||
          s.contains('inexistente') ||
          s.contains('remarcad')) {
        return 1;
      }

      return 0;
    }

    int countConforme = 0;
    int countObs = 0;
    int countNaoConforme = 0;

    final Map<String, List<Map<String, dynamic>>> grupos = {
      'IDENTIFICAÇÃO': [],
      'ESTRUTURA': [],
      'PINTURA E LATARIA': []
    };

    if (state != null) {
      for (final entry in state.checklistStatus.entries) {
        final id = entry.key;
        final rawStatus = entry.value;
        final nome = _cleanItemName(id);

        if (nome.contains('OPCIONAL')) continue;
        if (rawStatus.toUpperCase() == 'NÃO ANALISADO') continue;

        final cat = getStatusCategory(rawStatus);
        if (cat == 0)
          countConforme++;
        else if (cat == 1)
          countObs++;
        else
          countNaoConforme++;

        final itemMap = {'nome': nome, 'status': cat, 'id': id};

        if (id.startsWith('chassi') ||
            id.startsWith('motor') ||
            id.startsWith('cambio') ||
            id.startsWith('vidro') ||
            id.startsWith('etiqueta') ||
            id.startsWith('painel_hodometro') ||
            id.startsWith('foto_placa') ||
            id.startsWith('compartimento_motor')) {
          grupos['IDENTIFICAÇÃO']!.add(itemMap);
        } else if (id.startsWith('longarina') ||
            id.startsWith('caixa') ||
            id.startsWith('coluna') ||
            id.startsWith('painel') ||
            id.startsWith('torre') ||
            id.startsWith('assoalho')) {
          grupos['ESTRUTURA']!.add(itemMap);
        } else {
          grupos['PINTURA E LATARIA']!.add(itemMap);
        }
      }
    }

    final int totalItens = countConforme + countObs + countNaoConforme;
    final nowStr =
        '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';

    return pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) {
          return pw.Stack(children: [
            if (marcaAgua != null)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.10,
                    child: pw.Container(
                      width: 380,
                      child: pw.Image(marcaAgua, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logo != null)
                        pw.Container(
                            width: 300,
                            height: 160,
                            child: pw.Image(logo, fit: pw.BoxFit.contain))
                      else
                        pw.SizedBox(width: 300),
                      pw.Column(children: [
                        pw.Text('LAUDO CAUTELAR',
                            style: pw.TextStyle(
                                font: styles.bold,
                                fontSize: 16,
                                color: PdfColors.black)),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey700,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Text('LAUDO DE VISTORIA VEICULAR',
                              style: pw.TextStyle(
                                  font: styles.bold,
                                  fontSize: 8,
                                  color: PdfColors.white)),
                        ),
                      ]),
                      _buildQrCodeWithPlate(
                          Supabase.instance.client.storage
                              .from('laudos-pdf')
                              .getPublicUrl(
                                  '${vistoria.id}/${vistoria.numeroLaudo}.pdf'),
                          state?.placa ?? veiculo.placa,
                          styles),
                    ]),
                pw.SizedBox(height: 4),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'DATA REALIZAÇÃO: $nowStr    DATA IMPRESSÃO: $nowStr',
                          style: pw.TextStyle(
                              font: styles.bold,
                              fontSize: 6.5,
                              color: PdfColors.grey600)),
                      pw.Text('Nº LAUDO: ${vistoria.numeroLaudo}',
                          style: pw.TextStyle(
                              font: styles.bold,
                              fontSize: 6.5,
                              color: PdfColors.grey600)),
                    ]),
                pw.SizedBox(height: 4),
                pw.Container(height: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('F9F9F9'),
                          borderRadius: pw.BorderRadius.circular(8),
                          border:
                              pw.Border.all(color: PdfColors.grey300, width: 1),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 44,
                              height: 44,
                              decoration: pw.BoxDecoration(
                                  color: statusColor,
                                  shape: pw.BoxShape.circle),
                              child: pw.Center(
                                  child: pw.SvgImage(
                                      svg: statusIcon, width: 24, height: 24)),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text('PARECER FINAL DA VISTORIA',
                                      style: pw.TextStyle(
                                          font: styles.bold,
                                          fontSize: 9,
                                          color: PdfColors.grey600)),
                                  pw.SizedBox(height: 2),
                                  pw.Text(computedStatus.toUpperCase(),
                                      style: pw.TextStyle(
                                          font: styles.bold,
                                          fontSize: 14,
                                          color: PdfColors.black)),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                      'Conclusão baseada na análise dos itens verificados',
                                      style: pw.TextStyle(
                                          font: styles.regular,
                                          fontSize: 7,
                                          color: PdfColors.grey500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      flex: 6,
                      child: _buildClientAndVehicleData(
                          vistoria, state, veiculo, null, styles, limeGreen),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                _buildSituacaoGeralRow(
                    countConforme,
                    countObs,
                    countNaoConforme,
                    styles,
                    limeGreen,
                    warningYellow,
                    dangerRed),
                pw.SizedBox(height: 6),
                _buildBanner('ITENS ANALISADOS', styles),
                pw.SizedBox(height: 12),
                pw.Expanded(
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                      if (grupos['IDENTIFICAÇÃO']!.isNotEmpty)
                        _buildCategoryColumn(
                            'IDENTIFICAÇÃO',
                            grupos['IDENTIFICAÇÃO']!,
                            styles,
                            limeGreen,
                            warningYellow,
                            dangerRed),
                      if (grupos['IDENTIFICAÇÃO']!.isNotEmpty &&
                          (grupos['ESTRUTURA']!.isNotEmpty ||
                              grupos['PINTURA E LATARIA']!.isNotEmpty))
                        pw.Container(
                            width: 0.5, height: 80, color: PdfColors.grey200),
                      if (grupos['ESTRUTURA']!.isNotEmpty)
                        _buildCategoryColumn('ESTRUTURA', grupos['ESTRUTURA']!,
                            styles, limeGreen, warningYellow, dangerRed, numColumns: 2, flex: 2),
                      if (grupos['ESTRUTURA']!.isNotEmpty &&
                          grupos['PINTURA E LATARIA']!.isNotEmpty)
                        pw.Container(
                            width: 0.5, height: 80, color: PdfColors.grey200),
                      if (grupos['PINTURA E LATARIA']!.isNotEmpty)
                        _buildCategoryColumn(
                            'PINTURA E LATARIA',
                            grupos['PINTURA E LATARIA']!,
                            styles,
                            limeGreen,
                            warningYellow,
                            dangerRed),
                    ])),
                pw.Container(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(children: [
                            pw.Container(
                                width: 160, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 3),
                            pw.Text('CPF: Não informado',
                                style: pw.TextStyle(
                                    font: styles.bold, fontSize: 8)),
                            pw.Text('Vistoriador',
                                style: pw.TextStyle(
                                    font: styles.regular,
                                    fontSize: 7,
                                    color: PdfColors.grey700)),
                          ]),
                          pw.Column(children: [
                            pw.Container(
                                width: 160, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 3),
                            pw.Text('CLIENTE',
                                style: pw.TextStyle(
                                    font: styles.bold, fontSize: 8)),
                            pw.Text('Cliente',
                                style: pw.TextStyle(
                                    font: styles.regular,
                                    fontSize: 7,
                                    color: PdfColors.grey700)),
                          ])
                        ]))
              ],
            )
          ]);
        });
  }

  pw.Widget _buildKv(String k, String? v, _PdfStyles styles) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 70,
              child: pw.Text(k,
                  style: pw.TextStyle(
                      font: styles.bold,
                      fontSize: 7.5,
                      color: PdfColors.black))),
          pw.Expanded(
              child: pw.Text(v ?? '-',
                  style: pw.TextStyle(
                      font: styles.regular,
                      fontSize: 7.5,
                      color: PdfColors.grey800))),
        ]));
  }

  pw.Widget _buildLegendRow(
      String title, int count, PdfColor color, _PdfStyles styles,
      {bool isCheck = false, bool isWarning = false, bool isCross = false}) {
    String svgIcon;
    if (isCheck) {
      svgIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    } else if (isWarning) {
      svgIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    } else {
      svgIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    }

    return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Container(
                width: 16,
                height: 16,
                decoration:
                    pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
                child: pw.Center(
                    child: pw.SvgImage(svg: svgIcon, width: 10, height: 10))),
            pw.SizedBox(width: 8),
            pw.Text(title,
                style: pw.TextStyle(
                    font: styles.bold, fontSize: 9.5, color: PdfColors.black)),
          ]),
          pw.Text('$count ITENS',
              style: pw.TextStyle(
                  font: styles.bold, fontSize: 9.5, color: PdfColors.grey700)),
        ]);
  }

  pw.Widget _buildCategoryColumn(
    String title,
    List<Map<String, dynamic>> itens,
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed, {
    int numColumns = 1,
    int flex = 1,
  }) {
    int greens = itens.where((e) => e['status'] == 0).length;
    int yellows = itens.where((e) => e['status'] == 1).length;
    int reds = itens.where((e) => e['status'] == 2).length;
    int total = itens.length;
    final double itemFontSize = total > 18 ? 7.0 : 8.5;
    final double itemBottomPadding = total > 18 ? 2.5 : 4.0;

    return pw.Expanded(
        flex: flex,
        child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 1),
            child: pw.Column(children: [
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      decoration: pw.BoxDecoration(
                          color: limeGreen, shape: pw.BoxShape.circle),
                      child: pw.Center(
                          child: pw.Text('$total',
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  font: styles.bold,
                                  fontSize: 10))),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(title,
                        style: pw.TextStyle(
                            font: styles.bold,
                            fontSize: 9,
                            color: PdfColors.grey900)),
                    pw.SizedBox(width: 4),
                    pw.Text('($total ITENS)',
                        style: pw.TextStyle(
                            font: styles.regular,
                            fontSize: 6,
                            color: PdfColors.grey700)),
                  ]),
              pw.SizedBox(height: 8),
              pw.Container(
                  alignment: pw.Alignment.topCenter,
                  child: (() {
                    List<pw.Widget> getItems(List<Map<String, dynamic>> list) {
                      return list.map((e) {
                        final statusVal = e['status'] as int;
                        String statusSvg;
                        if (statusVal == 1) {
                          statusSvg =
                              '<svg viewBox="0 0 24 24"><path fill="#FBB03B" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
                        } else if (statusVal == 2) {
                          statusSvg =
                              '<svg viewBox="0 0 24 24"><path fill="#EE4036" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
                        } else {
                          statusSvg =
                              '<svg viewBox="0 0 24 24"><path fill="#8CC63F" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
                        }

                        return pw.Padding(
                            padding: pw.EdgeInsets.only(
                                bottom: itemBottomPadding),
                            child: pw.Row(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  pw.SvgImage(
                                      svg: statusSvg,
                                      width: 7.5,
                                      height: 7.5),
                                  pw.SizedBox(width: 5),
                                  pw.Expanded(
                                      child: pw.Text(e['nome'] as String,
                                          style: pw.TextStyle(
                                              font: (statusVal != 0)
                                                  ? styles.bold
                                                  : styles.regular,
                                              fontSize: itemFontSize,
                                              color: (statusVal != 0)
                                                  ? PdfColors.black
                                                  : PdfColors.grey800))),
                                ]));
                      }).toList();
                    }

                    if (numColumns == 1) {
                      return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: getItems(itens));
                    } else {
                      final int half = (itens.length / 2).ceil();
                      final col1 = itens.sublist(0, half);
                      final col2 = itens.sublist(half);
                      return pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                              child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: getItems(col1))),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                              child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: getItems(col2))),
                        ],
                      );
                    }
                  })())
            ])));
  }

  static pw.Widget _buildDonutChart(
    int total,
    int green,
    int yellow,
    int red,
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed,
  ) {
    return pw.SizedBox(
        width: 80,
        height: 80,
        child: pw.Stack(alignment: pw.Alignment.center, children: [
          pw.CustomPaint(
              size: const PdfPoint(80, 80),
              painter: (PdfGraphics canvas, PdfPoint size) {
                final center = PdfPoint(size.x / 2, size.y / 2);
                final radius = 32.0;
                final stroke = 11.0;

                if (total == 0) {
                  canvas.setStrokeColor(PdfColors.grey300);
                  canvas.setLineWidth(stroke);
                  canvas.drawEllipse(center.x, center.y, radius, radius);
                  canvas.strokePath();
                  return;
                }

                double currentAngle = -1.5708; // Top

                void drawArcSegment(int count, PdfColor color) {
                  if (count == 0) return;
                  final sweepAngle = (count / total) * 6.283185307179586;

                  canvas.saveContext();
                  final int steps = 30;
                  canvas.moveTo(center.x + radius * math.cos(currentAngle),
                      center.y + radius * math.sin(currentAngle));
                  for (int i = 1; i <= steps; i++) {
                    final a = currentAngle + (sweepAngle * i / steps);
                    canvas.lineTo(center.x + radius * math.cos(a),
                        center.y + radius * math.sin(a));
                  }
                  canvas.setStrokeColor(color);
                  canvas.setLineWidth(stroke);
                  canvas.strokePath();
                  canvas.restoreContext();

                  currentAngle += sweepAngle;
                }

                drawArcSegment(green, limeGreen);
                drawArcSegment(yellow, warningYellow);
                drawArcSegment(red, dangerRed);
              }),
          pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text('$total',
                style: pw.TextStyle(
                    font: styles.bold, fontSize: 16, color: PdfColors.black)),
            pw.Text('ITENS',
                style: pw.TextStyle(
                    font: styles.bold,
                    fontSize: 6.5,
                    color: PdfColors.grey600)),
          ])
        ]));
  }

  Future<pw.Page> _buildPage1({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? state,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    pw.ImageProvider? marcaAgua,
  }) async {
    String computedStatus = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        computedStatus = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        computedStatus = state.statusSugerido;
      }
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Stack(
          children: [
            if (marcaAgua != null)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.10,
                    child: pw.Container(
                      width: 350,
                      child: pw.Image(marcaAgua, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(vistoria, styles, logo,
                    state: state, showQr: true),
                _buildBlackBar(
                    'VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),

                // Dados Gerais
                _buildBlackBar('DADOS GERAIS:', styles),
                pw.Table(
                    border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: _kGreyLight),
                        children: [
                          _th('DATA:', styles),
                          _td(_formatDate(vistoria.dataHora), styles),
                          _th('STATUS:', styles),
                          _td(computedStatus.toUpperCase(), styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('CLIENTE:', styles),
                          _td(vistoria.clienteNome ?? 'NÃO INFORMADO', styles),
                          _th('Nº DO LAUDO:', styles),
                          _td(vistoria.numeroLaudo, styles),
                        ],
                      ),
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: _kGreyLight),
                        children: [
                          _th('UNIDADE:', styles),
                          _td(vistoria.unidade ?? 'NÃO INFORMADA', styles),
                          _th('VISTORIADOR:', styles),
                          _td(vistoria.vistoriadorNome ?? 'NÃO INFORMADO',
                              styles),
                        ],
                      ),
                    ]),
                pw.SizedBox(height: 4),

                // Dados do Veículo
                _buildBlackBar('DADOS DO VEÍCULO:', styles),
                pw.Table(
                    border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                    children: [
                      pw.TableRow(
                        children: [
                          _th('FABRICANTE/MARCA:', styles, dark: true),
                          _td(veiculo.marca ?? 'NÃO INFORMADO', styles),
                          _th('MODELO/VERSÃO:', styles, dark: true),
                          _td(veiculo.modelo ?? 'NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('ANO FAB/MODELO:', styles, dark: true),
                          _td('${veiculo.anoFabricacao ?? ""}/${veiculo.anoModelo ?? ""}',
                              styles),
                          _th('COR:', styles, dark: true),
                          _td(veiculo.cor ?? 'NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('PLACA:', styles, dark: true),
                          _td(veiculo.placa, styles),
                          _th('CIDADE/UF:', styles, dark: true),
                          _td(veiculo.municipio ?? 'NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('Nº DO CHASSI NO VEÍC.:', styles, dark: true),
                          _td(veiculo.chassiVeiculo ?? 'NÃO INFORMADO', styles),
                          _th('Nº DO MOTOR NO VEÍC.:', styles, dark: true),
                          _td(veiculo.motorVeiculo ?? 'NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('Nº DO CHASSI NA BIN:', styles, dark: true),
                          _td(veiculo.chassiBin ?? 'NÃO INFORMADO', styles),
                          _th('Nº DO MOTOR NA BIN:', styles, dark: true),
                          _td(veiculo.motorBin ?? 'NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('Nº DO RENAVAM:', styles, dark: true),
                          _td(veiculo.renavam ?? 'NÃO INFORMADO', styles),
                          _th('Nº DO CRV:', styles, dark: true),
                          _td('NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('Nº DO CÂMBIO NO VEÍC.:', styles, dark: true),
                          _td(veiculo.cambioVeiculo ?? 'NÃO INFORMADO', styles),
                          _th('COMBUSTÍVEL:', styles, dark: true),
                          _td('NÃO INFORMADO', styles),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _th('Nº DO CÂMBIO NA BIN:', styles, dark: true),
                          _td('NÃO INFORMADO', styles),
                          _th('KM:', styles, dark: true),
                          _td(veiculo.km?.toString() ?? 'NÃO INFORMADO',
                              styles),
                        ],
                      ),
                    ]),
                pw.SizedBox(height: 4),

                // Itens Analisados (2 colunas)
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: _buildChecklistCol(state, styles, 1)),
                      pw.SizedBox(width: 8),
                      pw.Expanded(child: _buildChecklistCol(state, styles, 2)),
                    ],
                  ),
                ),

                // Observações
                _buildBlackBar('OBSERVAÇÕES DO VEÍCULO:', styles),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _kBlack, width: 0.5)),
                  child: pw.Text(
                      state?.observacoesVeiculo.isEmpty == true
                          ? 'NENHUMA OBSERVAÇÃO'
                          : (state?.observacoesVeiculo ?? 'NENHUMA OBSERVAÇÃO'),
                      style: pw.TextStyle(font: styles.regular, fontSize: 8)),
                ),
                pw.SizedBox(height: 4),

                _buildBlackBar('DESCRIÇÃO DO TIPO DE VISTORIA:', styles),
                pw.Text('VISTORIA CAUTELAR AUTOMOTIVA',
                    style: pw.TextStyle(font: styles.bold, fontSize: 7)),
                pw.SizedBox(height: 6),

                _buildFooter(vistoria, styles, ctx, assinatura,
                    assinaturaCliente: assinaturaCliente, showSignatures: true),
                _buildPdfFooter(ctx, styles),
              ],
            ),
          ],
        );
      },
    );
  }

  pw.Widget _th(String text, _PdfStyles styles, {bool dark = false}) {
    return pw.Container(
      color: dark ? _kGreyDark : null,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: styles.bold, fontSize: 7, color: dark ? _kWhite : _kBlack)),
    );
  }

  pw.Widget _td(String text, _PdfStyles styles) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style:
              pw.TextStyle(font: styles.regular, fontSize: 7, color: _kBlack)),
    );
  }

  pw.Widget _buildChecklistCol(
      VistoriaWizardState? state, _PdfStyles styles, int colIndex) {
    var itens = [
      'compartimento_motor',
      'etiqueta_vis_motor',
      'etiqueta_vis_porta',
      'frente_direita',
      'frente_esquerda',
      'chassi_gravacao',
      'motor_gravacao',
      'vidro_dianteiro_direito',
      'vidro_dianteiro_esquerdo',
      'vidro_frontal',
      'vidro_traseiro',
      'vidro_traseiro_direito',
      'vidro_traseiro_esquerdo',
      'painel_hodometro',
      'foto_placa',
      'traseira_direita',
      'traseira_esquerda'
    ];

    final isCaminhao =
        state?.tipoVistoria.toLowerCase().contains('caminh') ?? false;

    if (isCaminhao) {
      itens.remove('compartimento_motor');
      itens.remove('etiqueta_vis_motor');
      itens.remove('etiqueta_vis_porta');
      itens.remove('vidro_traseiro_direito');
      itens.remove('vidro_traseiro_esquerdo');
    }

    itens = itens.where((id) {
      final status = state?.getStatus(id).toUpperCase() ?? '';
      return status != 'INEXISTENTE';
    }).toList();

    final labels = {
      'compartimento_motor': 'COMPARTIMENTO DO MOTOR',
      'etiqueta_vis_motor': 'ETIQUETA VIS COMPARTIMENTO MOTOR',
      'etiqueta_vis_porta': 'ETIQUETA VIS PORTA',
      'foto_chassi': 'GRAVAÇÃO DO CHASSI',
      'foto_motor': 'GRAVAÇÃO DO MOTOR',
      'frente_direita': 'FRENTE DIREITA',
      'frente_esquerda': 'FRENTE ESQUERDA',
      'chassi_gravacao': 'GRAVAÇÃO DO CHASSI',
      'motor_gravacao': 'GRAVAÇÃO DO MOTOR',
      'vidro_dianteiro_direito': 'GRAVAÇÃO Nº VIDRO DIANTEIRO DIREITO',
      'vidro_dianteiro_esquerdo': 'GRAVAÇÃO Nº VIDRO DIANTEIRO ESQUERDO',
      'vidro_frontal': 'GRAVAÇÃO Nº VIDRO FRONTAL',
      'vidro_traseiro': 'GRAVAÇÃO Nº VIDRO TRASEIRO',
      'vidro_traseiro_direito': 'GRAVAÇÃO Nº VIDRO TRASEIRO DIREITO',
      'vidro_traseiro_esquerdo': 'GRAVAÇÃO Nº VIDRO TRASEIRO ESQUERDO',
      'painel_hodometro': 'PAINEL E HODÔMETRO',
      'traseira_direita': 'TRASEIRA DIREITA',
      'traseira_esquerda': 'TRASEIRA ESQUERDA'
    };

    final half = (itens.length / 2).ceil();
    final colItems =
        colIndex == 1 ? itens.sublist(0, half) : itens.sublist(half);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(colItems.length, (i) {
        final id = colItems[i];
        final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
        final isConforme = status.toUpperCase().contains('CONFORME') ||
            status.toUpperCase().contains('ORIGINAL') ||
            status.toUpperCase().contains('PADRÃO DO FABRICANTE') ||
            status.toUpperCase().contains('PADRÕES');
        final color = isConforme
            ? _kGreen
            : (status == 'NÃO ANALISADO' ? _kGreyDark : _kRed);

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.only(bottom: 2),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: _kGreyLight, width: 1))),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                  child: pw.Text(labels[id]!,
                      style: pw.TextStyle(
                          font: styles.bold, fontSize: 8, color: _kBlack))),
              pw.Text(status.toUpperCase(),
                  style: pw.TextStyle(
                      font: styles.bold, fontSize: 8, color: _kBlack)),
            ],
          ),
        );
      }),
    );
  }

  pw.Widget _buildClientAndVehicleData(
      Vistoria vistoria,
      VistoriaWizardState? wizardState,
      Veiculo veiculo,
      RadarVeiculo? radarVeiculo,
      _PdfStyles styles,
      PdfColor limeGreen) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
            flex: 4,
            child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DADOS DO CLIENTE',
                          style: pw.TextStyle(
                              font: styles.bold,
                              fontSize: 7,
                              color: limeGreen)),
                      pw.SizedBox(height: 4),
                      _buildKvSmall(
                          'CLIENTE:',
                          (vistoria.clienteNome?.trim().isNotEmpty == true)
                              ? vistoria.clienteNome!
                              : '-',
                          styles),
                      _buildKvSmall(
                          'E-MAIL:',
                          (vistoria.clienteEmail?.trim().isNotEmpty == true)
                              ? vistoria.clienteEmail!
                              : '-',
                          styles),
                      _buildKvSmall(
                          'CPF/CNPJ:',
                          (vistoria.clienteCpf?.trim().isNotEmpty == true)
                              ? vistoria.clienteCpf!
                              : '-',
                          styles),
                      _buildKvSmall(
                          'TELEFONE:',
                          (vistoria.clienteTelefone?.trim().isNotEmpty == true)
                              ? vistoria.clienteTelefone!
                              : '-',
                          styles),
                    ]))),
        pw.SizedBox(width: 8),
        pw.Expanded(
            flex: 6,
            child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DADOS DO VEICULO (DENATRAN)',
                          style: pw.TextStyle(
                              font: styles.bold,
                              fontSize: 7,
                              color: limeGreen)),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                              _buildKvSmall(
                                  'Nº CHASSI:',
                                  (wizardState?.chassiVeiculo.isNotEmpty ==
                                              true &&
                                          wizardState!.chassiVeiculo !=
                                              'NÃO INFORMADO')
                                      ? wizardState.chassiVeiculo
                                      : (veiculo.chassiVeiculo?.isNotEmpty ==
                                                  true &&
                                              veiculo.chassiVeiculo !=
                                                  'NÃO INFORMADO')
                                          ? veiculo.chassiVeiculo!
                                          : (veiculo.chassiBin?.isNotEmpty ==
                                                  true)
                                              ? veiculo.chassiBin!
                                              : (radarVeiculo
                                                          ?.resultadoCompleto[
                                                              'chassi']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                  ? radarVeiculo!
                                                      .resultadoCompleto[
                                                          'chassi']
                                                      .toString()
                                                  : '-',
                                  styles),
                              _buildKvSmall(
                                  'Nº MOTOR:',
                                  (wizardState?.motorVeiculo.isNotEmpty ==
                                              true &&
                                          wizardState!.motorVeiculo !=
                                              'NÃO INFORMADO')
                                      ? wizardState.motorVeiculo
                                      : (veiculo.motorVeiculo?.isNotEmpty ==
                                                  true &&
                                              veiculo.motorVeiculo !=
                                                  'NÃO INFORMADO')
                                          ? veiculo.motorVeiculo!
                                          : (veiculo.motorBin?.isNotEmpty ==
                                                  true)
                                              ? veiculo.motorBin!
                                              : (radarVeiculo
                                                          ?.resultadoCompleto[
                                                              'motor']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                  ? radarVeiculo!
                                                      .resultadoCompleto[
                                                          'motor']
                                                      .toString()
                                                  : '-',
                                  styles),
                              _buildKvSmall(
                                  'PLACA:',
                                  wizardState?.placa.isNotEmpty == true
                                      ? wizardState!.placa
                                      : veiculo.placa ?? '-',
                                  styles),
                              _buildKvSmall(
                                  'MARCA:',
                                  wizardState?.marca.isNotEmpty == true
                                      ? wizardState!.marca
                                      : (veiculo.marca?.isNotEmpty == true)
                                          ? veiculo.marca!
                                          : (VeiculoParser.extrairMarcaModelo(radarVeiculo?.marcaModelo ?? radarVeiculo?.resultadoCompleto['marcamodelo']?.toString()).marca.isNotEmpty
                                              ? VeiculoParser.extrairMarcaModelo(radarVeiculo?.marcaModelo ?? radarVeiculo?.resultadoCompleto['marcamodelo']?.toString()).marca
                                              : (radarVeiculo?.resultadoCompleto['marca']?.toString() ?? '-')),
                                  styles),
                              _buildKvSmall(
                                  'MODELO:',
                                  wizardState?.modelo.isNotEmpty == true
                                      ? wizardState!.modelo
                                      : (veiculo.modelo?.isNotEmpty == true)
                                          ? veiculo.modelo!
                                          : (VeiculoParser.extrairMarcaModelo(radarVeiculo?.marcaModelo ?? radarVeiculo?.resultadoCompleto['marcamodelo']?.toString()).modelo.isNotEmpty
                                              ? VeiculoParser.extrairMarcaModelo(radarVeiculo?.marcaModelo ?? radarVeiculo?.resultadoCompleto['marcamodelo']?.toString()).modelo
                                              : (radarVeiculo?.resultadoCompleto['modelo']?.toString() ?? '-')),
                                  styles),
                            ])),
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                              _buildKvSmall(
                                  'COR:',
                                  wizardState?.cor.isNotEmpty == true
                                      ? wizardState!.cor
                                      : (veiculo.cor?.isNotEmpty == true)
                                          ? veiculo.cor!
                                          : (radarVeiculo
                                                  ?.resultadoCompleto['cor']
                                                  ?.toString() ??
                                              '-'),
                                  styles),
                              _buildKvSmall(
                                  'COMBUSTÍVEL:',
                                  wizardState?.combustivel.isNotEmpty == true
                                      ? wizardState!.combustivel
                                      : (veiculo.combustivel?.isNotEmpty ==
                                              true)
                                          ? veiculo.combustivel!
                                          : (radarVeiculo?.resultadoCompleto[
                                                      'combustivel']
                                                  ?.toString() ??
                                              '-'),
                                  styles),
                              _buildKvSmall(
                                  'ANO FABRICAÇÃO:',
                                  wizardState?.anoFabricacao.isNotEmpty == true
                                      ? wizardState!.anoFabricacao
                                      : (veiculo.anoFabricacao?.toString() ??
                                          radarVeiculo?.resultadoCompleto[
                                                  'ano_fabricacao']
                                              ?.toString() ??
                                          '-'),
                                  styles),
                              _buildKvSmall(
                                  'ANO MODELO:',
                                  wizardState?.anoModelo.isNotEmpty == true
                                      ? wizardState!.anoModelo
                                      : (veiculo.anoModelo?.toString() ??
                                          radarVeiculo
                                              ?.resultadoCompleto['ano_modelo']
                                              ?.toString() ??
                                          '-'),
                                  styles),
                              _buildKvSmall(
                                  'SITUAÇÃO CHASSI:', 'CIRCULAÇÃO', styles),
                            ])),
                      ])
                    ]))),
      ],
    );
  }

  pw.Widget _buildKvSmall(String k, String v, _PdfStyles styles) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(k,
                style: pw.TextStyle(
                    font: styles.bold, fontSize: 7.5, color: PdfColors.black)),
            pw.SizedBox(width: 4),
            pw.Expanded(
                child: pw.Text(v,
                    style: pw.TextStyle(
                        font: styles.regular,
                        fontSize: 7.5,
                        color: PdfColors.grey700))),
          ],
        ));
  }

  pw.Page _buildPageChecklistOpcional({
    required VistoriaWizardState state,
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? backgroundImage,
  }) {
    final bannerColor = PdfColor.fromHex('D9D9D9');

    final leftCategories = [
      'PNEUS/RODAS',
      'PARTE DIANTEIRA',
      'LATERAL ESQUERDA',
      'LATERAL DIREITA',
      'TRASEIRA'
    ];
    final rightCategories = [
      'EQUIPAMENTOS',
      'BANCOS E REVESTIMENTOS',
      'EQUIPAMENTOS OBRIGATÓRIOS (SEGURANÇA)',
      'ACIONAMENTO DO MOTOR'
    ];

    pw.Widget buildCategoryBlock(String cat) {
      final map = {
        'PNEUS/RODAS': [
          'PNEU DIANTEIRO ESQUERDO',
          'RODA DIANTEIRA ESQUERDA',
          'CALOTA DIANTEIRA ESQUERDA',
          'PNEU TRASEIRO ESQUERDO',
          'RODA TRASEIRA ESQUERDA',
          'CALOTA TRASEIRA ESQUERDA',
          'PNEU ESTEPE',
          'RODA ESTEPE',
          'PNEU TRASEIRO DIREITO',
          'RODA TRASEIRA DIREITA',
          'CALOTA TRASEIRA DIREITA',
          'PNEU DIANTEIRO DIREITO',
          'RODA DIANTEIRA DIREITA',
          'CALOTA DIANTEIRA DIREITA'
        ],
        'PARTE DIANTEIRA': [
          'CAPÔ',
          'FAROL DIREITO',
          'LANTERNA DIREITA',
          'FAROL DE MILHA DIR.',
          'PARA-CHOQUE',
          'GRADE',
          'PARA-BRISA',
          'FAROL ESQUERDO',
          'LANTERNA ESQUERDA',
          'FAROL DE MILHA ESQUERDO'
        ],
        'LATERAL ESQUERDA': [
          'LATERAL',
          'VIDRO VIGIA',
          'VIDRO TRASEIRO',
          'PORTA TRASEIRA',
          'VIDRO DIANTEIRO',
          'PORTA DIANTEIRA',
          'ESPELHO RETROVISOR',
          'PARA-LAMA'
        ],
        'LATERAL DIREITA': [
          'LATERAL',
          'VIDRO VIGIA',
          'VIDRO TRASEIRO',
          'PORTA TRASEIRA',
          'VIDRO DIANTEIRO',
          'PORTA DIANTEIRA',
          'ESPELHO RETROVISOR',
          'PARA-LAMA'
        ],
        'TRASEIRA': [
          'LANTERNA DE NEBLINA ESQ.',
          'LANTERNA DE NEBLINA DIR.',
          'CAPÔ TRASEIRO/TAMPA',
          'LUZ DA PLACA',
          'VIDRO VIGIA',
          'LIMPADOR TRASEIRO',
          'LANTERNA ESQUERDA',
          'LANTERNA DIREITA',
          'PARA-CHOQUE',
          'TETO'
        ],
        'EQUIPAMENTOS': [
          'AR CONDICIONADO',
          'VIDROS ELÉTRICOS',
          'TRAVAS ELÉTRICAS',
          'ALARME',
          'PAINEL DE INSTRUMENTOS',
          'PRESENÇA DE ODOR ?',
          'VOLANTE',
          'ANTENA',
          'ALTO-FALANTES',
          'RÁDIO CD PLAYER',
          'RÁDIO DVD',
          'TELAS AUXILIARES ?'
        ],
        'BANCOS E REVESTIMENTOS': [
          'BANCO TRASEIRO',
          'BANCO D.D.',
          'BANCO D.E.',
          'TAPETES',
          'REVESTIMENTO DO TETO',
          'REVESTIMENTO PORTA D.D.',
          'REVESTIMENTO PORTA T.D.',
          'REVESTIMENTO PORTA T.E.',
          'REVESTIMENTO PORTA D.E.'
        ],
        'EQUIPAMENTOS OBRIGATÓRIOS (SEGURANÇA)': [
          'LAVADOR',
          'LIMPADOR PARA-BRISA',
          'FAROL DE NEBLINA',
          'LUZ DE RÉ',
          'LUZ DE FREIO',
          'LANTERNA',
          'FAROL',
          'MANUAL DO PROPRIETÁRIO',
          'CHAVE RESERVA',
          'BLINDAGEM',
          'TRIÂNGULO',
          'MACACO',
          'CHAVE DE RODA',
          'ESTEPE',
          'EXTINTOR'
        ],
        'ACIONAMENTO DO MOTOR': [
          'BATERIA',
          'NÍVEL DO ÓLEO',
          'PARTIDA / ACIONAMENTO DO MOTOR'
        ]
      };

      final items = map[cat] ?? [];
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: bannerColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: pw.Text(cat,
                style: pw.TextStyle(
                    font: styles.bold, fontSize: 7, color: PdfColors.black)),
          ),
          ...items.map((item) {
            final val = state.checklistOpcional[item] ?? 'OK';
            final obs = state.checklistOpcionalMotivos[item];
            final hasObs = obs != null && obs.isNotEmpty;
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(item,
                            style: pw.TextStyle(
                                font: styles.regular, fontSize: 6.5)),
                      ),
                      pw.Text(val,
                          style: pw.TextStyle(
                              font: styles.regular, fontSize: 6.5)),
                    ],
                  ),
                  if (hasObs)
                    pw.Text('Obs: $obs',
                        style: pw.TextStyle(
                            font: styles.regular,
                            fontSize: 5.5,
                            color: PdfColors.grey700)),
                ],
              ),
            );
          }).toList(),
          pw.SizedBox(height: 4),
        ],
      );
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state, showQr: false),
            _buildBlackBar(
                'VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            _buildBlackBar('CHECKLIST', styles),
            pw.SizedBox(height: 8),
            pw.Expanded(
              child: pw.Stack(
                children: [
                  if (backgroundImage != null)
                    pw.Positioned.fill(
                      child: pw.Opacity(
                        opacity: 0.1,
                        child:
                            pw.Image(backgroundImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children:
                              leftCategories.map(buildCategoryBlock).toList(),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children:
                              rightCategories.map(buildCategoryBlock).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            _buildPdfFooter(ctx, styles),
          ],
        );
      },
    );
  }

  pw.MultiPage _buildPaginasEstruturaDetalhada({
    required Vistoria vistoria,
    required _PdfStyles styles,
    required VistoriaWizardState? state,
    pw.ImageProvider? logo,
    pw.ImageProvider? rodape,
  }) {
    final Map<String, List<String>> grupos = {
      'ESTRUTURA - PARTE DIANTEIRA': [
        'painel_frontal',
        'torre_amortecedor_direita',
        'torre_amortecedor_esquerda',
        'longarina_dianteira_direita',
        'caixa_roda_dianteira_direita',
        'longarina_dianteira_esquerda',
        'caixa_roda_dianteira_esquerda',
        'painel_corta_fogo',
      ],
      'ESTRUTURA DO LADO ESQUERDO': [
        'coluna_dianteira_esquerda',
        'coluna_central_esquerda',
        'coluna_traseira_esquerda',
        'caixa_ar_esquerda',
        'longarina_centro_esquerda',
      ],
      'ESTRUTURA - PARTE TRASEIRA': [
        'painel_traseiro',
        'caixa_estepe',
        'longarina_traseira_esquerda',
        'caixa_roda_traseira_esquerda',
        'longarina_traseira_direita',
        'caixa_roda_traseira_direita',
      ],
      'ESTRUTURA DO LADO DIREITO': [
        'coluna_dianteira_direita',
        'coluna_central_direita',
        'coluna_traseira_direita',
        'caixa_ar_direita',
        'longarina_centro_direita',
      ],
      'ASSOALHO': [
        'assoalho_esquerdo',
        'assoalho_direito',
      ]
    };

    final Map<String, String> labels = {
      'painel_frontal': 'PAINEL DIANTEIRO',
      'torre_amortecedor_direita': 'TORRE DO AMORTECEDOR DIREITA',
      'torre_amortecedor_esquerda': 'TORRE DO AMORTECEDOR ESQUERDA',
      'longarina_dianteira_direita': 'LONGARINA DIREITA',
      'caixa_roda_dianteira_direita': 'CAIXA DE RODA DIANTEIRA DIREITA',
      'longarina_dianteira_esquerda': 'LONGARINA ESQUERDA',
      'caixa_roda_dianteira_esquerda': 'CAIXA DE RODA DIANTEIRA ESQUERDA',
      'painel_corta_fogo': 'PAINEL CORTA-FOGO',
      'coluna_dianteira_esquerda': 'COLUNA DIANTEIRA',
      'coluna_central_esquerda': 'COLUNA CENTRAL',
      'coluna_traseira_esquerda': 'COLUNA TRASEIRA',
      'caixa_ar_esquerda': 'CAIXA DE AR',
      'longarina_centro_esquerda': 'LONGARINA CENTRAL',
      'painel_traseiro': 'PAINEL TRASEIRO',
      'caixa_estepe': 'CAIXA DO ESTEPE',
      'longarina_traseira_esquerda': 'LONGARINA TRASEIRA ESQUERDA',
      'caixa_roda_traseira_esquerda': 'CAIXA DE RODA TRASEIRA ESQUERDA',
      'longarina_traseira_direita': 'LONGARINA TRASEIRA DIREITA',
      'caixa_roda_traseira_direita': 'CAIXA DE RODA TRASEIRA DIREITA',
      'coluna_dianteira_direita': 'COLUNA DIANTEIRA',
      'coluna_central_direita': 'COLUNA CENTRAL',
      'coluna_traseira_direita': 'COLUNA TRASEIRA',
      'caixa_ar_direita': 'CAIXA DE AR',
      'longarina_centro_direita': 'LONGARINA CENTRAL',
      'assoalho_esquerdo': 'ASSOALHO LADO ESQUERDO',
      'assoalho_direito': 'ASSOALHO LADO DIREITO',
    };

    String getGlobalStatus() {
      if (state == null) return 'NADA CONSTA';
      bool temNaoConforme = false;
      bool temObs = false;
      for (final list in grupos.values) {
        for (final id in list) {
          final s = state.getStatus(id).toUpperCase();
          if (s.contains('COLISÃO') ||
              s.contains('SOLDADO') ||
              s.contains('SUBSTITUÍDO') ||
              s.contains('DANIFICADO') ||
              s.contains('OBSTRUÍDO')) {
            temNaoConforme = true;
          } else if (s.contains('REPARO') ||
              s.contains('OBSERVAÇÃO') ||
              s.contains('ALONGADO') ||
              s.contains('CONSIDERAÇÃO')) {
            temObs = true;
          }
        }
      }
      if (temNaoConforme) return 'NÃO CONFORME / REPROVADO';
      if (temObs) return 'APONTAMENTOS / OBSERVAÇÕES';
      return 'NADA CONSTA';
    }

    final globalStatus = getGlobalStatus();
    PdfColor globalStatusColor = PdfColors.green;
    String globalIcon =
        '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    if (globalStatus.contains('NÃO CONFORME')) {
      globalStatusColor = PdfColor.fromHex('EE4036'); // Red
      globalIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    } else if (globalStatus.contains('APONTAMENTOS')) {
      globalStatusColor = PdfColor.fromHex('FBB03B'); // Yellow
      globalIcon =
          '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    }

    return pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        header: (ctx) => _buildHeader(vistoria, styles, logo, state: state),
        footer: (ctx) => _buildPdfFooter(ctx, styles),
        build: (ctx) {
          List<pw.Widget> widgets = [];
          widgets.add(_buildBlackBar('MODULO - ESTRUTURA', styles));

          // Status Geral
          widgets.add(pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(children: [
                pw.Container(
                    width: 150,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                          right: pw.BorderSide(color: PdfColors.grey300)),
                    ),
                    child: pw.Row(children: [
                      pw.Container(
                          width: 14,
                          height: 14,
                          decoration: pw.BoxDecoration(
                              color: globalStatusColor,
                              shape: pw.BoxShape.circle),
                          child: pw.Center(
                              child: pw.SvgImage(
                                  svg: globalIcon, width: 8, height: 8))),
                      pw.SizedBox(width: 8),
                      pw.Text('ESTRUTURA',
                          style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                    ])),
                pw.Expanded(
                    child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        child: pw.Text(globalStatus,
                            style:
                                pw.TextStyle(font: styles.bold, fontSize: 8))))
              ])));

          // Subtabelas
          for (final entry in grupos.entries) {
            final title = entry.key;
            final ids = entry.value;

            widgets.add(pw.Container(
                width: double.infinity,
                color: PdfColors.grey300,
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: pw.Text(title,
                    style: pw.TextStyle(
                        font: styles.bold,
                        fontSize: 8,
                        color: PdfColors.grey800))));

            widgets.add(pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.grey300),
                  right: pw.BorderSide(color: PdfColors.grey300),
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                )),
                child: pw.Column(
                    children: ids.asMap().entries.map((itemEntry) {
                  final idx = itemEntry.key;
                  final id = itemEntry.value;
                  final label = labels[id] ?? id.toUpperCase();
                  final rawStatus = state?.getStatus(id) ?? '';
                  final status =
                      rawStatus.isEmpty ? 'OK' : rawStatus.toUpperCase();

                  PdfColor itemStatusColor = PdfColors.green;
                  String itemIcon =
                      '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';

                  if (status.contains('COLISÃO') ||
                      status.contains('SOLDADO') ||
                      status.contains('SUBSTITUÍDO') ||
                      status.contains('DANIFICADO') ||
                      status.contains('OBSTRUÍDO') ||
                      status.contains('NÃO CONFORME')) {
                    itemStatusColor = PdfColor.fromHex('EE4036'); // Red
                    itemIcon =
                        '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
                  } else if (status.contains('REPARO') ||
                      status.contains('OBSERVAÇÃO') ||
                      status.contains('ALONGADO') ||
                      status.contains('CONSIDERAÇÃO')) {
                    itemStatusColor = PdfColor.fromHex('FBB03B'); // Yellow
                    itemIcon =
                        '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
                  }

                  return pw.Container(
                      color: idx % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(label,
                                style: pw.TextStyle(
                                    font: styles.regular,
                                    fontSize: 7,
                                    color: PdfColors.grey800)),
                            pw.Row(children: [
                              pw.Text(status,
                                  style: pw.TextStyle(
                                      font: styles.bold,
                                      fontSize: 7,
                                      color: itemStatusColor)),
                              pw.SizedBox(width: 4),
                              pw.Container(
                                  width: 10,
                                  height: 10,
                                  decoration: pw.BoxDecoration(
                                      color: itemStatusColor,
                                      shape: pw.BoxShape.circle),
                                  child: pw.Center(
                                      child: pw.SvgImage(
                                          svg: itemIcon, width: 6, height: 6))),
                            ]),
                          ]));
                }).toList())));

            final List<String> obsDoGrupo = [];
            for (final id in ids) {
              final obs = state?.getObs(id) ?? '';
              final label = labels[id] ?? id.toUpperCase();
              if (obs.trim().isNotEmpty) {
                obsDoGrupo.add('$label: $obs');
              }
            }

            if (obsDoGrupo.isNotEmpty) {
              widgets.add(pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.grey300),
                    right: pw.BorderSide(color: PdfColors.grey300),
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  )),
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('OBSERVAÇÕES:',
                            style: pw.TextStyle(
                                font: styles.bold,
                                fontSize: 7,
                                color: PdfColors.grey800)),
                        ...obsDoGrupo.map((o) => pw.Text(o,
                            style: pw.TextStyle(
                                font: styles.regular,
                                fontSize: 7,
                                color: PdfColors.grey800)))
                      ])));
            }

            widgets.add(pw.SizedBox(height: 8));
          }

          return widgets;
        });
  }

  pw.Page _buildPageAnalise({
    required String titulo,
    required List<String> itens,
    required Map<String, String> labels,
    required VistoriaWizardState? state,
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? backgroundImage,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    bool isPintura = false,
    bool showSignatures = false,
    bool is3d = false,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            _buildBlackBar(
                'VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            _buildBlackBar(titulo, styles),
            pw.SizedBox(height: 8),
            if (!isPintura && backgroundImage != null)
              pw.Expanded(
                child: _buildDiagramaEstrutural(backgroundImage, state, styles),
              )
            else if (isPintura && is3d && backgroundImage != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 20),
                        child: pw.Center(
                          child:
                              pw.Image(backgroundImage, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildBlackBar('OBSERVAÇÕES DA PINTURA', styles),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: itens.map((id) {
                          final status =
                              state?.getStatus(id) ?? 'NÃO ANALISADO';
                          final obs = state?.getObs(id) ?? '';
                          final color = _getPinturaColor(status);
                          return pw.Container(
                              width: 170,
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('F9F9F9'),
                                border: pw.Border.all(
                                    color: PdfColors.grey300, width: 0.5),
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                        width: 10,
                                        height: 10,
                                        margin: const pw.EdgeInsets.only(
                                            top: 1, right: 6),
                                        decoration: pw.BoxDecoration(
                                            color: color,
                                            border: pw.Border.all(
                                                color: PdfColors.grey400,
                                                width: 0.5),
                                            borderRadius:
                                                const pw.BorderRadius.all(
                                                    pw.Radius.circular(2)))),
                                    pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                          pw.Text(labels[id] ?? id,
                                              style: pw.TextStyle(
                                                  font: styles.bold,
                                                  fontSize: 8,
                                                  color: PdfColors.grey900)),
                                          pw.SizedBox(height: 2),
                                          pw.Text(status.toUpperCase(),
                                              style: pw.TextStyle(
                                                  font: styles.regular,
                                                  fontSize: 7,
                                                  color: PdfColors.grey700)),
                                          if (obs.isNotEmpty) ...[
                                            pw.SizedBox(height: 2),
                                            pw.Text('Obs: $obs',
                                                style: pw.TextStyle(
                                                    font: styles.bold,
                                                    fontSize: 7,
                                                    color: PdfColors.red700)),
                                          ]
                                        ]))
                                  ]));
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else if (isPintura && backgroundImage != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child:
                          _buildDiagramaPintura(backgroundImage, state, styles),
                    ),
                    pw.SizedBox(height: 8),
                    _buildBlackBar('OBSERVAÇÕES DA PINTURA', styles),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: itens.map((id) {
                          final status =
                              state?.getStatus(id) ?? 'NÃO ANALISADO';
                          final obs = state?.getObs(id) ?? '';
                          final color = _getPinturaColor(status);
                          return pw.Container(
                              width: 170,
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('F9F9F9'),
                                border: pw.Border.all(
                                    color: PdfColors.grey300, width: 0.5),
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                        width: 10,
                                        height: 10,
                                        margin: const pw.EdgeInsets.only(
                                            top: 1, right: 6),
                                        decoration: pw.BoxDecoration(
                                            color: color,
                                            border: pw.Border.all(
                                                color: PdfColors.grey400,
                                                width: 0.5),
                                            borderRadius:
                                                const pw.BorderRadius.all(
                                                    pw.Radius.circular(2)))),
                                    pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                          pw.Text(labels[id] ?? id,
                                              style: pw.TextStyle(
                                                  font: styles.bold,
                                                  fontSize: 8,
                                                  color: PdfColors.grey900)),
                                          pw.SizedBox(height: 2),
                                          pw.Text(status.toUpperCase(),
                                              style: pw.TextStyle(
                                                  font: styles.regular,
                                                  fontSize: 7,
                                                  color: PdfColors.grey700)),
                                          if (obs.isNotEmpty) ...[
                                            pw.SizedBox(height: 2),
                                            pw.Text('Obs: $obs',
                                                style: pw.TextStyle(
                                                    font: styles.bold,
                                                    fontSize: 7,
                                                    color: PdfColors.red700)),
                                          ]
                                        ]))
                                  ]));
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Tabela provisória
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _kGreyLight),
                      children: [
                        _th('ITEM', styles),
                        _th('STATUS', styles),
                        _th('OBSERVAÇÃO', styles),
                      ],
                    ),
                    ...itens.map((id) {
                      final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                      final obs = state?.getObs(id) ?? '';
                      return pw.TableRow(
                        children: [
                          _td(labels[id] ?? id, styles),
                          _td(status.toUpperCase(), styles),
                          _td(obs, styles),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            _buildFooter(vistoria, styles, ctx, assinatura,
                assinaturaCliente: assinaturaCliente,
                showSignatures: showSignatures),
            _buildPdfFooter(ctx, styles),
          ],
        );
      },
    );
  }

  pw.Widget _buildDiagramaPintura(pw.ImageProvider backgroundImage,
      VistoriaWizardState? state, _PdfStyles styles) {
    const double boxWidth = 95;

    return pw.Center(
      child: pw.Stack(
        children: [
          // Base invisível para forçar a largura total e evitar que os itens se espremam
          pw.Container(width: 520),

          pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: pw.Image(backgroundImage, fit: pw.BoxFit.contain),
          ),

          // MEIO (Extremidades, não cortadas)
          pw.Positioned(
            left: 5,
            top: 110,
            child: _buildPinturaStatus(
                'CAPÔ DIANTEIRO',
                state?.getStatus('peca_capo_dianteiro') ?? 'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: true),
          ),
          pw.Positioned(
            right: 5, top: 160, // Desceu 50px
            child: _buildPinturaStatus(
                'TAMPA TRASEIRA',
                state?.getStatus('peca_tampa_traseira') ?? 'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: true),
          ),

          // TOPO (5 caixas)
          pw.Positioned(
            left: 35, top: 30, // Desceu 30px, 30px direita
            child: _buildPinturaStatus(
                'PARA-LAMA DIAN. DIR.',
                state?.getStatus('peca_paralama_dianteiro_direito') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: false),
          ),
          pw.Positioned(
            left: 135, top: 20, // 30px pra direita e desceu 20px
            child: _buildPinturaStatus(
                'PORTA DIAN. DIR.',
                state?.getStatus('peca_porta_dianteira_direita') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: false),
          ),
          pw.Positioned(
            left: 247.5, top: 0, // 30px pra direita
            child: _buildPinturaStatus('TETO',
                state?.getStatus('peca_teto') ?? 'NÃO ANALISADO', styles,
                width: 85, tagOnTop: false),
          ),
          pw.Positioned(
            right: 135, top: 20, // 30px pra esquerda, desceu 20px
            child: _buildPinturaStatus(
                'PORTA TRAS. DIR.',
                state?.getStatus('peca_porta_traseira_direita') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: false),
          ),
          pw.Positioned(
            right: 45, top: 20, // 40px pra esquerda, desceu 20px
            child: _buildPinturaStatus(
                'LATERAL TRAS. DIR.',
                state?.getStatus('peca_lateral_traseira_direita') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: false),
          ),

          // BASE (4 caixas)
          pw.Positioned(
            left: 25, bottom: 100, // Subiu 50px
            child: _buildPinturaStatus(
                'PARA-LAMA DIAN. ESQ.',
                state?.getStatus('peca_paralama_dianteiro_esquerdo') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: true),
          ),
          pw.Positioned(
            left: 165, bottom: 110, // Subiu 50px, 10px pra esquerda
            child: _buildPinturaStatus(
                'PORTA DIAN. ESQ.',
                state?.getStatus('peca_porta_dianteira_esquerda') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: true),
          ),
          pw.Positioned(
            right: 145, bottom: 110, // Subiu 50px, 20px pra direita
            child: _buildPinturaStatus(
                'PORTA TRAS. ESQ.',
                state?.getStatus('peca_porta_traseira_esquerda') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: true),
          ),
          pw.Positioned(
            right: 45, bottom: 120, // Subiu 50px, 10px pra direita
            child: _buildPinturaStatus(
                'LATERAL TRAS. ESQ.',
                state?.getStatus('peca_lateral_traseira_esquerda') ??
                    'NÃO ANALISADO',
                styles,
                width: 85,
                tagOnTop: true),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDiagramaEstrutural(pw.ImageProvider backgroundImage,
      VistoriaWizardState? state, _PdfStyles styles) {
    return pw.Center(
      child: pw.Container(
        width: 520,
        height: 380,
        child: pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 30, horizontal: 15),
                child: pw.Image(backgroundImage, fit: pw.BoxFit.contain),
              ),
            ),
            pw.Positioned(
              top: 10,
              left: 10,
              child: _buildCaixaStatus(
                  'LONGARINA DIANTEIRA DIREITA',
                  state?.getStatus('longarina_dianteira_direita') ??
                      'NÃO ANALISADO',
                  styles,
                  width: 95,
                  tagOnTop: true),
            ),
            pw.Positioned(
              top: 10,
              left: 215,
              child: _buildCaixaStatus(
                  'LONGARINA CENTRO DIREITA',
                  state?.getStatus('longarina_centro_direita') ??
                      'NÃO ANALISADO',
                  styles,
                  width: 95,
                  tagOnTop: true),
            ),
            pw.Positioned(
              top: 10,
              right: 15,
              child: _buildCaixaStatus(
                  'LONGARINA TRASEIRA DIREITA',
                  state?.getStatus('longarina_traseira_direita') ??
                      'NÃO ANALISADO',
                  styles,
                  width: 95,
                  tagOnTop: true),
            ),
            pw.Positioned(
              bottom: 10,
              left: 10,
              child: _buildCaixaStatus(
                  'LONGARINA DIANTEIRA ESQUERDA',
                  state?.getStatus('longarina_dianteira_esquerda') ??
                      'NÃO ANALISADO',
                  styles,
                  width: 95,
                  tagOnTop: false),
            ),
            pw.Positioned(
              bottom: 10,
              left: 215,
              child: _buildCaixaStatus(
                  'LONGARINA CENTRO ESQUERDA',
                  state?.getStatus('longarina_centro_esquerda') ??
                      'NÃO ANALISADO',
                  styles,
                  width: 95,
                  tagOnTop: false),
            ),
            pw.Positioned(
              bottom: 10,
              right: 15,
              child: _buildCaixaStatus(
                  'LONGARINA TRASEIRA ESQUERDA',
                  state?.getStatus('longarina_traseira_esquerda') ??
                      'NÃO ANALISADO',
                  styles,
                  width: 95,
                  tagOnTop: false),
            ),
          ],
        ),
      ),
    );
  }

  PdfColor _getPinturaColor(String status) {
    status = status.toUpperCase();
    if (status.contains('ORIGINAL') ||
        status.contains('CONFORME') ||
        status.contains('PADRÃO DO FABRICANTE')) {
      return _kGreen;
    } else if (status.contains('REPINTURA E/OU MASSA') ||
        status.contains('SUBSTITUÍDO') ||
        status.contains('DANIFICADO') ||
        status.contains('REPROVADO') ||
        status.contains('NÃO CONFORME')) {
      return _kRed;
    } else if (status.contains('REPINTURA') ||
        status.contains('ENVELOPADO') ||
        status.contains('RISCADO') ||
        status.contains('REPARO')) {
      return _kOrange;
    }
    return _kGreyDark;
  }

  pw.Widget _buildPinturaStatus(String titulo, String status, _PdfStyles styles,
      {double width = 90, bool tagOnTop = true}) {
    status = status.toUpperCase();
    PdfColor color = _getPinturaColor(status);

    final titleWidget = pw.Text(
      titulo,
      style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kBlack),
      textAlign: pw.TextAlign.center,
    );

    String icon = color == _kGreen ? '✓' : (color == _kRed ? '✗' : '!');

    final tagWidget = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            icon,
            style:
                pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            status,
            style:
                pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: tagOnTop
            ? [tagWidget, pw.SizedBox(height: 2), titleWidget]
            : [titleWidget, pw.SizedBox(height: 2), tagWidget],
      ),
    );
  }

  pw.Widget _buildCaixaStatus(String titulo, String status, _PdfStyles styles,
      {double width = 95, bool tagOnTop = true}) {
    status = status.toUpperCase();
    PdfColor color = _kGreyDark;

    // Verificação de status estrutural
    if (status.contains('NÃO CONFORME') ||
        status.contains('SUBSTITUÍDO') ||
        status.contains('SOLDADO') ||
        status.contains('REPROVADO') ||
        status.contains('TRINCADO') ||
        status.contains('CORTADO') ||
        status.contains('DANIFICADO')) {
      color = _kRed;
    } else if (status.contains('CONFORME') ||
        status.contains('SEM REPARO') ||
        status.contains('ORIGINAL') ||
        status.contains('PADRÃO DO FABRICANTE') ||
        status.contains('PADRÕES') ||
        status == 'APROVADO') {
      color = _kGreen;
    } else if (status.contains('REPARO') ||
        status.contains('OBSERVAÇÕES') ||
        status.contains('AMASSADO') ||
        status.contains('APONTAMENTOS') ||
        status.contains('ALONGADO') ||
        status.contains('CONSIDERAÇÃO') ||
        status.contains('OBSTRUÍDO')) {
      color = _kOrange;
    }

    final titleWidget = pw.Text(
      titulo,
      style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kBlack),
      textAlign: pw.TextAlign.center,
    );

    String icon = color == _kGreen ? '✓' : (color == _kRed ? '✗' : '!');

    final tagWidget = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            icon,
            style:
                pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            status,
            style:
                pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: tagOnTop
            ? [tagWidget, pw.SizedBox(height: 2), titleWidget]
            : [titleWidget, pw.SizedBox(height: 2), tagWidget],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _maskCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return 'Não informado';
    final raw = cpf.replaceAll(RegExp(r'\D'), '');
    if (raw.length != 11) return cpf;
    return '***.${raw.substring(3, 6)}.${raw.substring(6, 9)}-**';
  }

  void _buildFichaTecnicaPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    Vistoria vistoria,
    _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    VistoriaWizardState? state,
  ) {
    final themeRed = PdfColor.fromHex(
        '#1F5E3D'); // Verde principal (mantendo o nome da variavel para nao quebrar)
    final lightRed = PdfColor.fromHex('#F1F8E9'); // Fundo verde clarinho
    final borderRed = PdfColor.fromHex('#C5E1A5'); // Borda verde suave
    final textDark = PdfColor.fromHex('#333333');
    final textMuted = PdfColor.fromHex('#666666');

    pw.Widget buildRedBar(String text) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
        decoration: pw.BoxDecoration(
          color: themeRed,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(text,
            style: pw.TextStyle(
                font: styles.bold, fontSize: 9, color: PdfColors.white)),
      );
    }

    pw.Widget buildSoftTh(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        color: lightRed,
        child: pw.Text(text,
            style:
                pw.TextStyle(font: styles.bold, fontSize: 8, color: themeRed)),
      );
    }

    pw.Widget buildSoftTd(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                font: styles.regular, fontSize: 8, color: textDark)),
      );
    }

    String formatCurrency(dynamic val) {
      if (val == null) return '-';
      final str = val.toString();
      if (str.toUpperCase().startsWith('R\$')) return str;

      final clean = str.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (clean.isEmpty) return str;

      try {
        final parsed = double.parse(clean.replaceAll(',', '.'));
        return 'R\$ ' + parsed.toStringAsFixed(2).replaceAll('.', ',');
      } catch (_) {
        return str;
      }
    }

    // Especificações e Manutenção
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    color: lightRed,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: themeRed, width: 1)),
                child: pw.Center(
                  child: pw.Text('FICHA TÉCNICA INTELIGENTE DO VEÍCULO',
                      style: pw.TextStyle(
                          font: styles.bold, fontSize: 12, color: themeRed)),
                )),
            pw.SizedBox(height: 8),
            buildRedBar('ESPECIFICAÇÕES TÉCNICAS'),
            if (data['especificacoes_tecnicas'] != null)
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: borderRed, width: 1),
                ),
                child: pw.Table(
                  border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: borderRed, width: 0.5)),
                  children:
                      (data['especificacoes_tecnicas'] as Map<String, dynamic>)
                          .entries
                          .map((e) {
                    return pw.TableRow(children: [
                      buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                      buildSoftTd(e.value.toString()),
                    ]);
                  }).toList(),
                ),
              ),
            pw.SizedBox(height: 8),
            buildRedBar('MANUTENÇÃO RECOMENDADA'),
            if (data['manutencao'] != null)
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: borderRed, width: 1),
                ),
                child: pw.Table(
                  border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: borderRed, width: 0.5)),
                  children: (data['manutencao'] as Map<String, dynamic>)
                      .entries
                      .map((e) {
                    return pw.TableRow(children: [
                      buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                      buildSoftTd(e.value.toString()),
                    ]);
                  }).toList(),
                ),
              ),
            pw.Spacer(),
            _buildFooter(vistoria, styles, ctx, assinatura,
                showSignatures: false),
            _buildPdfFooter(ctx, styles),
          ],
        );
      },
    ));

    // Problemas e Peças
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        final apontamentosOriginais = data['apontamentos_veiculo'] is List
            ? (data['apontamentos_veiculo'] as List)
            : [];
        bool isZeroCurrency(dynamic val) {
          if (val == null) return true;
          final str = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
          return str.isEmpty || int.tryParse(str) == 0;
        }

        final validApontamentos = apontamentosOriginais.where((item) {
          final pecaUpper =
              (item['peca_ou_problema']?.toString() ?? '').toUpperCase();
          final obsUpper =
              (item['observacao_indicada']?.toString() ?? '').toUpperCase();
          final isNoAvaria = pecaUpper.contains('SEM ACESSO') ||
              pecaUpper.contains('SEMA ACESSO') ||
              obsUpper.contains('SEM ACESSO') ||
              obsUpper.contains('SEMA ACESSO') ||
              obsUpper.contains('NÃO É AVARIA') ||
              obsUpper.contains('NAO E AVARIA') ||
              obsUpper.contains('NÃO REPRESENTA AVARIA') ||
              obsUpper.contains('OBSTRUÍDO') ||
              obsUpper.contains('OBSTRUIDO') ||
              obsUpper.contains('DENTRO DOS PADRÕES') ||
              obsUpper.contains('DENTRO DOS PADROES') ||
              obsUpper.contains('PADRÃO DE FÁBRICA') ||
              obsUpper.contains('PADRAO DE FABRICA') ||
              obsUpper.contains('PADRÃO DO FABRICANTE') ||
              obsUpper.contains('SEM AVARIA');

          if (isNoAvaria) return false;

          final valPecaZero = isZeroCurrency(item['valor_peca_estimado']);
          final valMaoObraZero = isZeroCurrency(item['valor_mao_de_obra_estimado']);

          if (valPecaZero && valMaoObraZero) {
            return false;
          }

          return true;
        }).toList();

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            buildRedBar('PONTOS DE ATENÇÃO (HISTÓRICO DO MODELO)'),
            if (data['problemas_comuns'] != null &&
                data['problemas_comuns'] is List)
              ...((data['problemas_comuns'] as List).map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: borderRed, width: 1)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.SvgImage(
                            svg:
                                '<svg viewBox="0 0 24 24"><path fill="#0288d1" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>',
                            width: 10,
                            height: 10),
                        pw.SizedBox(width: 4),
                        pw.Text('${item['item']}',
                            style: pw.TextStyle(
                                font: styles.bold,
                                fontSize: 9,
                                color: themeRed)),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Text('${item['sintomas']}',
                          style: pw.TextStyle(
                              font: styles.regular,
                              fontSize: 8,
                              color: textDark)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          'Ponto de Atenção: ${item['observacao_vistoria']}',
                          style: pw.TextStyle(
                              font: styles.bold,
                              fontSize: 8,
                              color: textMuted)),
                    ],
                  ),
                );
              }).toList()),
            pw.SizedBox(height: 8),
            buildRedBar('PEÇAS DE DESGASTE'),
            if (data['pecas_desgaste'] != null &&
                data['pecas_desgaste'] is List)
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: borderRed, width: 1),
                ),
                child: pw.Table(
                  border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: borderRed, width: 0.5)),
                  children: [
                    pw.TableRow(
                        decoration: pw.BoxDecoration(color: lightRed),
                        children: [
                          buildSoftTh('PEÇA'),
                          buildSoftTh('VIDA ÚTIL'),
                          buildSoftTh('VALOR PEÇA'),
                          buildSoftTh('MÃO DE OBRA')
                        ]),
                    ...((data['pecas_desgaste'] as List).map((item) {
                      return pw.TableRow(children: [
                        buildSoftTd(item['peca']?.toString() ?? ''),
                        buildSoftTd(item['vida_util_media']?.toString() ?? ''),
                        buildSoftTd(
                            formatCurrency(item['valor_peca_estimado'])),
                        buildSoftTd(
                            '${formatCurrency(item['valor_mao_de_obra_estimado'])} (${item['tempo_mao_de_obra_estimado']})'),
                      ]);
                    }).toList()),
                  ],
                ),
              ),
            if (validApontamentos.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF57F17),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text('APONTAMENTOS DA VISTORIA (VALORES ESTIMADOS)',
                    style: pw.TextStyle(
                        font: styles.bold,
                        fontSize: 9,
                        color: PdfColors.white)),
              ),
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFFFE082), width: 1),
                ),
                child: pw.Table(
                  border: pw.TableBorder.symmetric(
                      inside: const pw.BorderSide(
                          color: PdfColor.fromInt(0xFFFFE082), width: 0.5)),
                  children: [
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFFFF9C4)),
                        children: [
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('PEÇA / PROBLEMA',
                                  style: pw.TextStyle(
                                      font: styles.bold,
                                      fontSize: 8,
                                      color:
                                          const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('OBSERVAÇÃO',
                                  style: pw.TextStyle(
                                      font: styles.bold,
                                      fontSize: 8,
                                      color:
                                          const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('VALOR PEÇA',
                                  style: pw.TextStyle(
                                      font: styles.bold,
                                      fontSize: 8,
                                      color:
                                          const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('MÃO DE OBRA',
                                  style: pw.TextStyle(
                                      font: styles.bold,
                                      fontSize: 8,
                                      color:
                                          const PdfColor.fromInt(0xFFF57F17)))),
                        ]),
                    ...(validApontamentos.map((item) {
                      final peca = item['peca_ou_problema']?.toString() ?? '';
                      final obs = item['observacao_indicada']?.toString() ?? '';
                      final valPeca =
                          formatCurrency(item['valor_peca_estimado']);
                      final valMaoObra =
                          formatCurrency(item['valor_mao_de_obra_estimado']);

                      return pw.TableRow(children: [
                        buildSoftTd(peca),
                        buildSoftTd(obs),
                        buildSoftTd(valPeca),
                        buildSoftTd(valMaoObra),
                      ]);
                    }).toList()),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'OBSERVAÇÃO: Os valores de peças e mão de obra apresentados neste relatório são estimativas geradas de forma automatizada por Inteligência Artificial. Eles não representam um orçamento exato ou valor de mercado definitivo, podendo sofrer variações conforme a região, oficina ou fornecedor.',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ],
            pw.Spacer(),
            _buildFooter(vistoria, styles, ctx, assinatura,
                showSignatures: false),
            _buildPdfFooter(ctx, styles),
          ],
        );
      },
    ));

    // Dicas
    if (data['dicas_vistoria'] != null &&
        (data['dicas_vistoria'] as List).isNotEmpty) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(vistoria, styles, logo, state: state),
              buildRedBar('RECOMENDAÇÕES DE REVISÃO (HISTÓRICO DO MODELO)'),
              ...((data['dicas_vistoria'] as List).map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: borderRed, width: 1)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Área: ${item['area']}',
                          style: pw.TextStyle(
                              font: styles.bold, fontSize: 9, color: themeRed)),
                      pw.SizedBox(height: 2),
                      pw.Text('Verificar: ${item['o_que_verificar']}',
                          style: pw.TextStyle(
                              font: styles.regular,
                              fontSize: 8,
                              color: textDark)),
                      pw.SizedBox(height: 2),
                      pw.Text('Recomendação: ${item['sinal_de_alerta']}',
                          style: pw.TextStyle(
                              font: styles.bold,
                              fontSize: 8,
                              color: textMuted)),
                    ],
                  ),
                );
              }).toList()),
              pw.SizedBox(height: 8),
              if (data['observacoes'] != null &&
                  data['observacoes'] is List &&
                  (data['observacoes'] as List).isNotEmpty) ...[
                buildRedBar('OBSERVAÇÕES ADICIONAIS'),
                pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                        color: lightRed,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: borderRed, width: 1)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: ((data['observacoes'] as List).map((obs) {
                        return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(
                                    margin: const pw.EdgeInsets.only(
                                        top: 3, right: 6),
                                    width: 3,
                                    height: 3,
                                    decoration: pw.BoxDecoration(
                                        color: themeRed,
                                        shape: pw.BoxShape.circle),
                                  ),
                                  pw.Expanded(
                                      child: pw.Text('$obs',
                                          style: pw.TextStyle(
                                              font: styles.regular,
                                              fontSize: 8,
                                              color: textDark))),
                                ]));
                      }).toList()),
                    ))
              ],
              pw.SizedBox(height: 8),
              (() {
                if (data['analise_final'] == null) {
                  return pw.SizedBox.shrink();
                }

                final analise = data['analise_final'];
                final resumo =
                    analise['resumo_estado_veiculo']?.toString() ?? '';
                String valorMercado =
                    analise['valor_venda_mercado_local']?.toString() ??
                        'R\$ 0,00';
                String desconto =
                    analise['desconto_total_avarias']?.toString() ?? 'R\$ 0,00';
                String valorSugerido =
                    analise['valor_venda_sugerido_final']?.toString() ??
                        'R\$ 0,00';
                final justificativa =
                    analise['justificativa']?.toString() ?? '';

                String guaranteeBrl(String val) {
                  if (!val.toUpperCase().contains('R\$') &&
                      !val.contains(r'\$')) {
                    return 'R\$ ' + val;
                  }
                  if (val.contains(r'\$') && !val.toUpperCase().contains('R')) {
                    return val.replaceFirst(r'\$', 'R\$ ');
                  }
                  return val;
                }

                valorMercado = guaranteeBrl(valorMercado);
                desconto = guaranteeBrl(desconto);
                valorSugerido = guaranteeBrl(valorSugerido);

                final mainGreen = PdfColor.fromHex('8CC63F');
                final blueColor = const PdfColor.fromInt(0xFF1976D2);

                return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        decoration: pw.BoxDecoration(
                          color: mainGreen,
                          borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(4),
                              topRight: pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                            'ANÁLISE FINAL E AVALIAÇÃO DE MERCADO (IA)',
                            style: pw.TextStyle(
                                font: styles.bold,
                                fontSize: 9,
                                color: PdfColors.white)),
                      ),
                      pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            borderRadius: const pw.BorderRadius.only(
                                bottomLeft: pw.Radius.circular(4),
                                bottomRight: pw.Radius.circular(4)),
                            border: pw.Border.all(color: mainGreen, width: 1),
                          ),
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Resumo do Estado:',
                                    style: pw.TextStyle(
                                        font: styles.bold,
                                        fontSize: 8,
                                        color: textDark)),
                                pw.SizedBox(height: 2),
                                pw.Text(resumo,
                                    style: pw.TextStyle(
                                        font: styles.regular,
                                        fontSize: 8,
                                        color: textDark)),
                                pw.SizedBox(height: 6),
                                pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Text('Valor Médio Local:',
                                                  style: pw.TextStyle(
                                                      font: styles.bold,
                                                      fontSize: 8,
                                                      color: textDark)),
                                              pw.Text(valorMercado,
                                                  style: pw.TextStyle(
                                                      font: styles.bold,
                                                      fontSize: 11,
                                                      color: textDark)),
                                            ]),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.center,
                                            children: [
                                              pw.Text(
                                                  'Desconto (Avarias/Reparos):',
                                                  style: pw.TextStyle(
                                                      font: styles.bold,
                                                      fontSize: 8,
                                                      color: blueColor)),
                                              pw.Text(desconto,
                                                  style: pw.TextStyle(
                                                      font: styles.bold,
                                                      fontSize: 11,
                                                      color: blueColor)),
                                            ]),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.end,
                                            children: [
                                              pw.Text('Valor Sugerido Final:',
                                                  style: pw.TextStyle(
                                                      font: styles.bold,
                                                      fontSize: 8,
                                                      color: mainGreen)),
                                              pw.Text(valorSugerido,
                                                  style: pw.TextStyle(
                                                      font: styles.bold,
                                                      fontSize: 12,
                                                      color: mainGreen)),
                                            ]),
                                      ),
                                    ]),
                                pw.SizedBox(height: 6),
                                pw.Text('Justificativa:',
                                    style: pw.TextStyle(
                                        font: styles.bold,
                                        fontSize: 8,
                                        color: textDark)),
                                pw.SizedBox(height: 2),
                                pw.Text(justificativa,
                                    style: pw.TextStyle(
                                        font: styles.regular,
                                        fontSize: 8,
                                        color: textDark)),
                              ]))
                    ]);
              })(),
              pw.Spacer(),
              _buildFooter(vistoria, styles, ctx, assinatura,
                  showSignatures: false),
              _buildPdfFooter(ctx, styles),
            ],
          );
        },
      ));
    }
  }

  static pw.Widget _buildSituacaoGeralRow(
    int countConforme,
    int countObs,
    int countNaoConforme,
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed,
  ) {
    int total = countConforme + countObs + countNaoConforme;

    return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.SizedBox(width: 8),
          pw.Container(
            width: 70,
            child: pw.Text('SITUAÇÃO\nGERAL',
                style: pw.TextStyle(
                    font: styles.bold, fontSize: 11, color: PdfColors.black)),
          ),
          pw.Container(width: 0.5, height: 40, color: PdfColors.grey300),
          pw.SizedBox(width: 4),

          // CONFORME
          pw.Expanded(
            child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                            width: 14,
                            height: 14,
                            decoration: pw.BoxDecoration(
                                color: limeGreen, shape: pw.BoxShape.circle),
                            child: pw.Center(
                                child: pw.SvgImage(
                                    svg:
                                        '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>'))),
                        pw.SizedBox(width: 4),
                        pw.Text('CONFORME',
                            style:
                                pw.TextStyle(font: styles.bold, fontSize: 7)),
                      ]),
                  pw.SizedBox(height: 4),
                  pw.Text('$countConforme',
                      style: pw.TextStyle(font: styles.bold, fontSize: 18)),
                  pw.Text('ITENS',
                      style: pw.TextStyle(font: styles.bold, fontSize: 6)),
                ]),
          ),
          pw.SizedBox(width: 4),
          pw.Container(width: 0.5, height: 40, color: PdfColors.grey300),
          pw.SizedBox(width: 4),

          // OBSERVAÇÃO
          pw.Expanded(
            child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                            width: 14,
                            height: 14,
                            decoration: pw.BoxDecoration(
                                color: warningYellow,
                                shape: pw.BoxShape.circle),
                            child: pw.Center(
                                child: pw.SvgImage(
                                    svg:
                                        '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>'))),
                        pw.SizedBox(width: 4),
                        pw.Text('CONFORME\n(COM OBSERVAÇÃO)',
                            style: pw.TextStyle(font: styles.bold, fontSize: 6),
                            textAlign: pw.TextAlign.center),
                      ]),
                  pw.SizedBox(height: 4),
                  pw.Text('$countObs',
                      style: pw.TextStyle(font: styles.bold, fontSize: 18)),
                  pw.Text('ITENS',
                      style: pw.TextStyle(font: styles.bold, fontSize: 6)),
                ]),
          ),
          pw.SizedBox(width: 4),
          pw.Container(width: 0.5, height: 40, color: PdfColors.grey300),
          pw.SizedBox(width: 4),

          // NÃO CONFORME
          pw.Expanded(
            child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                            width: 14,
                            height: 14,
                            decoration: pw.BoxDecoration(
                                color: dangerRed, shape: pw.BoxShape.circle),
                            child: pw.Center(
                                child: pw.SvgImage(
                                    svg:
                                        '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>'))),
                        pw.SizedBox(width: 4),
                        pw.Text('NÃO CONFORME',
                            style:
                                pw.TextStyle(font: styles.bold, fontSize: 7)),
                      ]),
                  pw.SizedBox(height: 4),
                  pw.Text('$countNaoConforme',
                      style: pw.TextStyle(font: styles.bold, fontSize: 18)),
                  pw.Text(countNaoConforme == 1 ? 'ITEM' : 'ITENS',
                      style: pw.TextStyle(font: styles.bold, fontSize: 6)),
                ]),
          ),
          pw.SizedBox(width: 4),
          pw.Container(width: 0.5, height: 40, color: PdfColors.grey300),
          pw.SizedBox(width: 4),

          // Chart and legend
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Transform.scale(
              scale: 0.7,
              child: _buildDonutChart(
                  total,
                  countConforme,
                  countObs,
                  countNaoConforme,
                  styles,
                  limeGreen,
                  warningYellow,
                  dangerRed),
            ),
            pw.SizedBox(width: 6),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(children: [
                    pw.SvgImage(
                        svg:
                            '<svg viewBox="0 0 24 24"><path fill="#8CC63F" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>',
                        width: 6,
                        height: 6),
                    pw.SizedBox(width: 4),
                    pw.Text('CONFORME: $countConforme',
                        style: pw.TextStyle(font: styles.bold, fontSize: 6))
                  ]),
                  pw.SizedBox(height: 2),
                  pw.Row(children: [
                    pw.SvgImage(
                        svg:
                            '<svg viewBox="0 0 24 24"><path fill="#FBB03B" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>',
                        width: 6,
                        height: 6),
                    pw.SizedBox(width: 4),
                    pw.Text('OBSERVAÇÃO: $countObs',
                        style: pw.TextStyle(font: styles.bold, fontSize: 6))
                  ]),
                  pw.SizedBox(height: 2),
                  pw.Row(children: [
                    pw.SvgImage(
                        svg:
                            '<svg viewBox="0 0 24 24"><path fill="#EE4036" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>',
                        width: 6,
                        height: 6),
                    pw.SizedBox(width: 4),
                    pw.Text('NÃO CONFORME: $countNaoConforme',
                        style: pw.TextStyle(font: styles.bold, fontSize: 6))
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Text('TOTAL: $total ITENS',
                      style: pw.TextStyle(font: styles.bold, fontSize: 7)),
                ]),
            pw.SizedBox(width: 4),
          ])
        ]));
  }

  static pw.Widget? _buildQuadroResumoApontamentos(
    VistoriaWizardState? wizardState,
    _PdfStyles styles,
  ) {
    if (wizardState == null) return null;

    final apontamentos = <Map<String, String>>[];
    final avaliarPintura = wizardState.realizarAvaliacaoPintura;

    int getCat(String raw) {
      final s = raw.toLowerCase().trim();
      if (s.isEmpty) return 0;
      if (s.contains('divergente') ||
          s.contains('adulteração') ||
          s.contains('reprovado') ||
          s.contains('não original') ||
          s.contains('substituído') ||
          s.contains('ausente') ||
          s.contains('danificad') ||
          s.contains('colisão') ||
          s.contains('ilegível') ||
          s.contains('não localizad') ||
          s.contains('não conforme') ||
          s.contains('nao conforme')) return 2;
      if (s.contains('reparo') ||
          s.contains('repintura') ||
          s.contains('observação') ||
          s.contains('observa') ||
          s.contains('envelopado') ||
          s.contains('amassado') ||
          s.contains('riscado') ||
          s.contains('soldado') ||
          s.contains('avaria') ||
          s.contains('massa') ||
          s.contains('obstruído') ||
          s.contains('alongado') ||
          s.contains('consideração') ||
          s.contains('sem acesso') ||
          s.contains('trinca') ||
          s.contains('quebrad') ||
          s.contains('desgaste') ||
          s.contains('inexistente') ||
          s.contains('remarcad')) return 1;
      return 0;
    }

    // Itens de checklist padrão
    const itensEstrutura = {
      'painel_frontal',
      'painel_corta_fogo',
      'torre_amortecedor_esquerda',
      'longarina_dianteira_esquerda',
      'caixa_roda_dianteira_esquerda',
      'coluna_dianteira_esquerda',
      'caixa_ar_esquerda',
      'assoalho_esquerdo',
      'coluna_central_esquerda',
      'longarina_centro_esquerda',
      'coluna_traseira_esquerda',
      'caixa_roda_traseira_esquerda',
      'longarina_traseira_esquerda',
      'painel_traseiro',
      'caixa_estepe',
      'longarina_traseira_direita',
      'caixa_roda_traseira_direita',
      'coluna_traseira_direita',
      'longarina_centro_direita',
      'coluna_central_direita',
      'assoalho_direito',
      'caixa_ar_direita',
      'coluna_dianteira_direita',
      'caixa_roda_dianteira_direita',
      'longarina_dianteira_direita',
      'torre_amortecedor_direita',
    };

    wizardState.checklistStatus.forEach((id, status) {
      if (status.toUpperCase() == 'NÃO ANALISADO') return;
      
      // Remove itens de pintura do quadro resumo geral
      if (id.startsWith('peca_')) return; 
      
      // Remove itens estruturais do quadro resumo geral
      if (itensEstrutura.contains(id)) return; 


      final obs = wizardState.checklistObs[id] ?? '';
      final cat = getCat(status);

      if (cat > 0 || obs.trim().isNotEmpty) {
        apontamentos.add({
          'item': _cleanItemName(id),
          'status': status.isNotEmpty ? status : (cat > 0 ? 'APONTAMENTO' : 'COM OBSERVAÇÃO'),
          'obs': obs.trim().isNotEmpty ? obs.trim() : 'Apontamento registrado na inspeção visual.',
          'severidade': cat == 2 ? 'critico' : 'alerta',
        });
      }
    });

    // Divergências de Chassi / Motor
    if (wizardState.chassiBin.isNotEmpty &&
        wizardState.chassiVeiculo.isNotEmpty &&
        wizardState.chassiBin != wizardState.chassiVeiculo) {
      apontamentos.add({
        'item': 'Gravação do Chassi',
        'status': 'DIVERGENTE',
        'obs': 'Número físico no veículo (${wizardState.chassiVeiculo}) diverge da base BIN (${wizardState.chassiBin}).',
        'severidade': 'critico',
      });
    }
    if (wizardState.motorBin.isNotEmpty &&
        wizardState.motorVeiculo.isNotEmpty &&
        wizardState.motorBin != wizardState.motorVeiculo) {
      apontamentos.add({
        'item': 'Gravação do Motor',
        'status': 'DIVERGENTE',
        'obs': 'Número físico no veículo (${wizardState.motorVeiculo}) diverge da base BIN (${wizardState.motorBin}).',
        'severidade': 'critico',
      });
    }

    // Checklist Opcional se preenchido com problemas
    if (wizardState.realizarChecklistOpcional) {
      wizardState.checklistOpcional.forEach((key, status) {
        final obs = wizardState.checklistOpcionalMotivos[key] ?? '';
        final cat = getCat(status);
        if (cat > 0 || obs.trim().isNotEmpty) {
          apontamentos.add({
            'item': _cleanItemName(key),
            'status': status,
            'obs': obs.trim().isNotEmpty ? obs.trim() : 'Item com apontamento no checklist.',
            'severidade': cat == 2 ? 'critico' : 'alerta',
          });
        }
      });
    }

    if (apontamentos.isEmpty) return null;

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromHex('1F5E3D'), width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header do Quadro
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('1F5E3D'),
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'QUADRO RESUMO DE APONTAMENTOS E OBSERVAÇÕES',
                  style: pw.TextStyle(
                    font: styles.bold,
                    fontSize: 9.5,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          // Cabeçalho da Tabela
          pw.Container(
            color: PdfColor.fromHex('F0FDF4'),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'ITEM / COMPONENTE',
                    style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColor.fromHex('1F5E3D')),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'STATUS / CLASSIFICAÇÃO',
                    style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColor.fromHex('1F5E3D')),
                  ),
                ),
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    'OBSERVAÇÃO / MOTIVO',
                    style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColor.fromHex('1F5E3D')),
                  ),
                ),
              ],
            ),
          ),
          pw.Divider(height: 1, color: PdfColors.grey300),
          // Linhas da Tabela
          ...apontamentos.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isEven = idx % 2 == 0;
            final isCritico = item['severidade'] == 'critico';
            final statusBadgeColor = isCritico ? PdfColor.fromHex('EE4036') : PdfColor.fromHex('D97706');

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : PdfColor.fromHex('F9FAFB'),
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item['item'] ?? '',
                      style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColors.black),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: pw.BoxDecoration(
                          color: statusBadgeColor,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          (item['status'] ?? '').toUpperCase(),
                          style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.white),
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      item['obs'] ?? '',
                      style: pw.TextStyle(font: styles.regular, fontSize: 7.5, color: PdfColors.grey800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildParecerTecnicoBox(String parecerText, _PdfStyles styles) {
    final bgColor = const PdfColor.fromInt(0xFFFFC107); // Amarelo Escuro (Amber)
    final borderColor = const PdfColor.fromInt(0xFFF57F17); // Laranja escuro para contraste
    
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 4,
                height: 12,
                color: PdfColors.black,
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                'PARECER TÉCNICO',
                style: pw.TextStyle(
                  font: styles.bold,
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            parecerText,
            style: pw.TextStyle(
              font: styles.bold,
              fontSize: 10,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBanner(String text, _PdfStyles styles) {
    return pw.Container(
      width: double.infinity,
      color: PdfColor.fromHex('1F5E3D'), // The green banner color
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
            color: PdfColors.white, font: styles.bold, fontSize: 10),
      ),
    );
  }
}

class _PdfStyles {
  final pw.Font regular;
  final pw.Font bold;
  const _PdfStyles({required this.regular, required this.bold});
}
