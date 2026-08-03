import 'vistoria_type.dart';

Map<String, Map<String, String>> getChecklistCategories(TipoVistoria tipo) {
  if (tipo == TipoVistoria.checklistOnibus) {
    return _getChecklistOnibus();
  } else if (tipo == TipoVistoria.checklistMicroOnibus) {
    return _getChecklistMicroOnibus();
  } else if (tipo == TipoVistoria.checklistPesado) {
    // Caminhão
    return _getChecklistCaminhao();
  }
  return {}; // Retorna vazio se não for nenhum dos esperados
}

Map<String, Map<String, String>> _getChecklistCaminhao() {
  return {
    'PNEUS / RODAS': {
      'pneu_diant_esq': 'Pneu Dianteiro Esquerdo',
      'roda_diant_esq': 'Roda Dianteira Esquerda',
      'calota_diant_esq': 'Calota Dianteira Esquerda',
      'pneu_diant_dir': 'Pneu Dianteiro Direito',
      'roda_diant_dir': 'Roda Dianteira Direita',
      'calota_diant_dir': 'Calota Dianteira Direita',
      'pneu_tracao_esq': 'Pneu Tração Esquerdo',
      'roda_tracao_esq': 'Roda Tração Esquerda',
      'pneu_tracao_dir': 'Pneu Tração Direito',
      'roda_tracao_dir': 'Roda Tração Direito',
      'pneu_eixo_aux': 'Pneu Eixo Auxiliar (quando houver)',
      'roda_eixo_aux': 'Roda Eixo Auxiliar',
      'pneu_estepe': 'Pneu Estepe',
      'roda_estepe': 'Roda Estepe',
    },
    'PARTE DIANTEIRA': {
      'capo': 'Capô',
      'grade': 'Grade',
      'para_choque_diant': 'Para-choque',
      'farol_esq': 'Farol Esquerdo',
      'farol_dir': 'Farol Direito',
      'farol_neblina': 'Farol de Neblina',
      'para_brisa': 'Para-brisa',
      'limpador': 'Limpador',
      'retrovisor_esq': 'Retrovisor Esquerdo',
      'retrovisor_dir': 'Retrovisor Direito',
    },
    'LATERAL ESQUERDA': {
      'porta_mot': 'Porta Motorista',
      'vidro_esq': 'Vidro',
      'estribo_esq': 'Estribo',
      'tanque_combustivel': 'Tanque de Combustível',
      'caixa_ferramentas': 'Caixa de Ferramentas',
      'para_lama_diant_esq': 'Para-lama Dianteiro',
      'para_lama_tras_esq': 'Para-lama Traseiro',
    },
    'LATERAL DIREITA': {
      'porta_pass': 'Porta Passageiro',
      'vidro_dir': 'Vidro',
      'estribo_dir': 'Estribo',
      'compartimentos_lat': 'Compartimentos Laterais',
      'para_lama_diant_dir': 'Para-lama Dianteiro',
      'para_lama_tras_dir': 'Para-lama Traseiro',
    },
    'IMPLEMENTO / CARGA': {
      'bau': 'Baú',
      'carroceria': 'Carroceria',
      'cacamba': 'Caçamba',
      'sider': 'Sider',
      'porta_tras': 'Porta Traseira',
      'travas': 'Travas',
      'assoalho': 'Assoalho',
      'teto': 'Teto',
      'engate': 'Engate',
      'quinta_roda': 'Quinta Roda (Cavalo Mecânico)',
    },
    'TRASEIRA': {
      'lanterna_esq': 'Lanterna Esquerda',
      'lanterna_dir': 'Lanterna Direita',
      'luz_freio': 'Luz de Freio',
      'luz_re': 'Luz de Ré',
      'luz_placa': 'Luz de Placa',
      'para_choque_tras': 'Para-choque',
      'para_barro': 'Para-barro',
    },
    'CABINE': {
      'banco_mot': 'Banco Motorista',
      'banco_pass': 'Banco Passageiro',
      'painel': 'Painel',
      'volante': 'Volante',
      'tacografo': 'Tacógrafo',
      'ar_condicionado': 'Ar Condicionado',
      'radio': 'Rádio',
    },
    'EQUIPAMENTOS OBRIGATÓRIOS': {
      'crlv': 'CRLV',
      'manual': 'Manual',
      'chave_reserva': 'Chave Reserva',
      'triangulo': 'Triângulo',
      'macaco': 'Macaco',
      'chave_roda': 'Chave de Roda',
      'estepe_equip': 'Estepe',
      'extintor': 'Extintor (quando exigido)',
      'calco_roda': 'Calço de Roda',
    },
    'MOTOR': {
      'bateria': 'Bateria',
      'nivel_oleo': 'Nível do Óleo',
      'fluido_arrefecimento': 'Fluido de Arrefecimento',
      'func_motor': 'Funcionamento do Motor',
      'vazamentos': 'Vazamentos',
    }
  };
}

Map<String, Map<String, String>> _getChecklistOnibus() {
  return {
    'PNEUS / RODAS': {
      'pneu_diant_esq': 'Pneu Dianteiro Esquerdo',
      'roda_diant_esq': 'Roda Dianteira Esquerda',
      'pneu_diant_dir': 'Pneu Dianteiro Direito',
      'roda_diant_dir': 'Roda Dianteira Direita',
      'pneu_tras_esq': 'Pneu Traseiro Esquerdo',
      'roda_tras_esq': 'Roda Traseira Esquerda',
      'pneu_tras_dir': 'Pneu Traseiro Direito',
      'roda_tras_dir': 'Roda Traseira Direita',
      'estepe_pneu': 'Estepe',
    },
    'PARTE DIANTEIRA': {
      'para_brisa': 'Para-brisa',
      'limpador': 'Limpador',
      'farol_esq': 'Farol Esquerdo',
      'farol_dir': 'Farol Direito',
      'farol_neblina': 'Farol de Neblina',
      'grade': 'Grade',
      'para_choque': 'Para-choque',
      'retrovisores': 'Retrovisores',
    },
    'LATERAL ESQUERDA': {
      'janelas_esq': 'Janelas',
      'vidros_esq': 'Vidros',
      'lataria_esq': 'Lataria',
      'compart_bagagem_esq': 'Compartimento de Bagagem',
      'para_lamas_esq': 'Para-lamas',
    },
    'LATERAL DIREITA': {
      'porta_diant': 'Porta Dianteira',
      'porta_central': 'Porta Central',
      'porta_tras': 'Porta Traseira (quando houver)',
      'sist_abertura': 'Sistema de Abertura',
      'janelas_dir': 'Janelas',
      'compart_bagagem_dir': 'Compartimento de Bagagem',
    },
    'INTERIOR': {
      'banco_mot': 'Banco Motorista',
      'bancos_pass': 'Bancos Passageiros',
      'cintos': 'Cintos',
      'corrimaos': 'Corrimãos',
      'piso': 'Piso',
      'ilum_interna': 'Iluminação Interna',
      'campainha': 'Campainha',
      'letreiro': 'Letreiro',
      'painel': 'Painel',
      'tacografo': 'Tacógrafo',
      'ar_condicionado': 'Ar Condicionado',
      'cortinas': 'Cortinas',
    },
    'TRASEIRA': {
      'tampa_motor': 'Tampa do Motor',
      'lanternas': 'Lanternas',
      'luz_freio': 'Luz de Freio',
      'luz_re': 'Luz de Ré',
      'luz_placa': 'Luz de Placa',
      'para_choque_tras': 'Para-choque',
    },
    'EQUIPAMENTOS OBRIGATÓRIOS': {
      'crlv': 'CRLV',
      'manual': 'Manual',
      'chave_reserva': 'Chave Reserva',
      'triangulo': 'Triângulo',
      'macaco': 'Macaco',
      'chave_roda': 'Chave de Roda',
      'estepe_equip': 'Estepe',
      'extintor': 'Extintor (quando exigido)',
      'martelos': 'Martelos de Emergência',
      'saidas_emerg': 'Saídas de Emergência',
    },
    'MOTOR': {
      'bateria': 'Bateria',
      'oleo': 'Óleo',
      'arrefecimento': 'Arrefecimento',
      'funcionamento': 'Funcionamento',
      'vazamentos': 'Vazamentos',
    }
  };
}

Map<String, Map<String, String>> _getChecklistMicroOnibus() {
  return {
    'PNEUS / RODAS': {
      'pneu_diant_esq': 'Pneu Dianteiro Esquerdo',
      'roda_diant_esq': 'Roda Dianteira Esquerda',
      'pneu_diant_dir': 'Pneu Dianteiro Direito',
      'roda_diant_dir': 'Roda Dianteira Direita',
      'pneu_tras_esq': 'Pneu Traseiro Esquerdo',
      'roda_tras_esq': 'Roda Traseira Esquerda',
      'pneu_tras_dir': 'Pneu Traseiro Direito',
      'roda_tras_dir': 'Roda Traseira Direita',
      'estepe_pneu': 'Estepe',
    },
    'PARTE DIANTEIRA': {
      'capo': 'Capô',
      'grade': 'Grade',
      'para_choque': 'Para-choque',
      'farois': 'Faróis',
      'farois_neblina': 'Faróis de Neblina',
      'para_brisa': 'Para-brisa',
      'limpador': 'Limpador',
      'retrovisores': 'Retrovisores',
    },
    'LATERAL ESQUERDA': {
      'porta_mot': 'Porta do Motorista',
      'janelas_esq': 'Janelas',
      'vidros_esq': 'Vidros',
      'lataria_esq': 'Lataria',
      'para_lama_esq': 'Para-lama',
    },
    'LATERAL DIREITA': {
      'porta_pass': 'Porta dos Passageiros',
      'sist_abertura': 'Sistema de Abertura',
      'janelas_dir': 'Janelas',
      'vidros_dir': 'Vidros',
      'para_lama_dir': 'Para-lama',
    },
    'INTERIOR': {
      'banco_mot': 'Banco Motorista',
      'bancos_pass': 'Bancos Passageiros',
      'cintos': 'Cintos',
      'corrimaos': 'Corrimãos',
      'piso': 'Piso',
      'painel': 'Painel',
      'ar_condicionado': 'Ar Condicionado',
      'radio': 'Rádio',
      'campainha': 'Campainha',
    },
    'TRASEIRA': {
      'porta_tras': 'Porta Traseira (quando houver)',
      'lanternas': 'Lanternas',
      'luz_freio': 'Luz de Freio',
      'luz_re': 'Luz de Ré',
      'luz_placa': 'Luz de Placa',
      'para_choque_tras': 'Para-choque',
    },
    'EQUIPAMENTOS OBRIGATÓRIOS': {
      'crlv': 'CRLV',
      'manual': 'Manual',
      'chave_reserva': 'Chave Reserva',
      'triangulo': 'Triângulo',
      'macaco': 'Macaco',
      'chave_roda': 'Chave de Roda',
      'estepe_equip': 'Estepe',
      'extintor': 'Extintor (quando exigido)',
      'martelos': 'Martelos de Emergência',
    },
    'MOTOR': {
      'bateria': 'Bateria',
      'oleo': 'Óleo',
      'arrefecimento': 'Arrefecimento',
      'funcionamento': 'Funcionamento',
      'vazamentos': 'Vazamentos',
    }
  };
}
