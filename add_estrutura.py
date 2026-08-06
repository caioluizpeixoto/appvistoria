import sys
with open('lib/core/services/pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

fn_code = '''
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
          if (s.contains('COLISÃO') || s.contains('SOLDADO') || s.contains('SUBSTITUÍDO') || s.contains('DANIFICADO') || s.contains('OBSTRUÍDO')) {
            temNaoConforme = true;
          } else if (s.contains('REPARO') || s.contains('OBSERVAÇÃO') || s.contains('ALONGADO') || s.contains('CONSIDERAÇÃO')) {
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
    String globalIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    if (globalStatus.contains('NÃO CONFORME')) {
      globalStatusColor = PdfColor.fromHex('EE4036'); // Red
      globalIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    } else if (globalStatus.contains('APONTAMENTOS')) {
      globalStatusColor = PdfColor.fromHex('FBB03B'); // Yellow
      globalIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    }

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      header: (ctx) => _buildHeader(vistoria, styles, logo, state: state),
      footer: (ctx) => _buildFooter(vistoria, styles, rodape, ctx),
      build: (ctx) {
        List<pw.Widget> widgets = [];
        widgets.add(_buildBlackBar('MODULO - ESTRUTURA', styles));
        
        // Status Geral
        widgets.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 150,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 14, height: 14,
                      decoration: pw.BoxDecoration(color: globalStatusColor, shape: pw.BoxShape.circle),
                      child: pw.Center(child: pw.SvgImage(svg: globalIcon, width: 8, height: 8))
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('ESTRUTURA', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  ]
                )
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: pw.Text(globalStatus, style: pw.TextStyle(font: styles.bold, fontSize: 8))
                )
              )
            ]
          )
        ));

        // Subtabelas
        for (final entry in grupos.entries) {
          final title = entry.key;
          final ids = entry.value;

          widgets.add(pw.Container(
            width: double.infinity,
            color: PdfColors.grey300,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.grey800))
          ));

          widgets.add(pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.grey300),
                right: pw.BorderSide(color: PdfColors.grey300),
                bottom: pw.BorderSide(color: PdfColors.grey300),
              )
            ),
            child: pw.Column(
              children: ids.asMap().entries.map((itemEntry) {
                final idx = itemEntry.key;
                final id = itemEntry.value;
                final label = labels[id] ?? id.toUpperCase();
                final rawStatus = state?.getStatus(id) ?? '';
                final status = rawStatus.isEmpty ? 'OK' : rawStatus;
                
                return pw.Container(
                  color: idx % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(label, style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey800)),
                      pw.Text(status.toUpperCase(), style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey800)),
                    ]
                  )
                );
              }).toList()
            )
          ));
          
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
                )
              ),
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('OBSERVAÇÕES:', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.grey800)),
                  ...obsDoGrupo.map((o) => pw.Text(o, style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey800)))
                ]
              )
            ));
          }
          
          widgets.add(pw.SizedBox(height: 8));
        }

        return widgets;
      }
    );
  }
'''

target = "  pw.Page _buildPageAnalise({"
if target in content:
    content = content.replace(target, fn_code + '\n' + target)
    
    call_target = "if (temCroqui && !isCaminhao) {"
    call_replacement = """if (temCroqui && !isCaminhao) {
      pdf.addPage(_buildPaginasEstruturaDetalhada(
        vistoria: vistoria,
        styles: styles,
        state: wizardState,
        logo: logoImage,
        rodape: _globalRodapeImage,
      ));

"""
    content = content.replace(call_target, call_replacement + "    " + call_target, 1)

    with open('lib/core/services/pdf_generator_service.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print('pdf_generator_service.dart modificado com sucesso')
else:
    print('Não encontrou o target')
