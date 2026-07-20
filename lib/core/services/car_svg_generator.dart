import 'package:pdf/pdf.dart';

class CarSvgGenerator {
  /// Retorna o SVG do veículo (vista superior e lateral combinadas de forma esquemática)
  /// As cores são injetadas baseadas no status de cada peça.
  static String getCarSvgPintura({required Map<String, PdfColor> colors}) {
    // Helper para extrair a cor hex
    String getHex(String key) {
      final color = colors[key] ?? PdfColor.fromHex('#e0e0e0');
      return color.toHex().substring(0, 7); // Remove alpha se houver, garantindo formato #RRGGBB
    }

    return '''
<svg viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .stroke { stroke: #333333; stroke-width: 3; stroke-linejoin: round; }
      .text { font-family: Helvetica, sans-serif; font-size: 14px; fill: #333333; font-weight: bold; }
      .shadow { filter: drop-shadow(3px 3px 5px rgba(0,0,0,0.2)); }
    </style>
  </defs>

  <!-- LADO ESQUERDO (Perfil) -->
  <g transform="translate(50, 50)" class="shadow">
    <!-- Pneus Esquerda -->
    <circle cx="120" cy="180" r="30" fill="#222" />
    <circle cx="380" cy="180" r="30" fill="#222" />
    
    <!-- Para-lama Dianteiro Esq -->
    <path class="stroke" fill="${getHex('peca_paralama_dianteiro_esquerdo')}" d="M30,110 Q80,90 120,90 L150,90 L150,150 L80,150 Z" />
    
    <!-- Porta Dianteira Esq -->
    <path class="stroke" fill="${getHex('peca_porta_dianteira_esquerda')}" d="M140,90 L230,90 L230,150 L140,150 Z" />
    
    <!-- Porta Traseira Esq -->
    <path class="stroke" fill="${getHex('peca_porta_traseira_esquerda')}" d="M260,90 L350,90 L350,150 L260,150 Z" />
    
    <!-- Lateral Traseira Esq -->
    <path class="stroke" fill="${getHex('peca_lateral_traseira_esquerda')}" d="M340,90 L410,90 Q460,90 470,130 L470,150 L390,150 Z" />
    
    <!-- Janelas Esq (Vidros) -->
    <path stroke="#333" stroke-width="2" fill="#90CAF9" d="M160,70 L235,70 L235,110 L140,110 Z" />
    <path stroke="#333" stroke-width="2" fill="#90CAF9" d="M245,70 L310,70 L320,110 L245,110 Z" />
    
    <!-- Teto Lateral Esq (Apenas visual, o teto real está na vista superior) -->
    <path class="stroke" fill="#cccccc" d="M150,60 L320,60 L350,120 L120,120 Z" />
    
    <text x="180" y="220" class="text">VISTA ESQUERDA</text>
  </g>

  <!-- LADO DIREITO (Perfil invertido para layout) -->
  <g transform="translate(50, 320)" class="shadow">
    <!-- Pneus Direita -->
    <circle cx="120" cy="180" r="30" fill="#222" />
    <circle cx="380" cy="180" r="30" fill="#222" />
    
    <!-- Para-lama Dianteiro Dir -->
    <path class="stroke" fill="${getHex('peca_paralama_dianteiro_direito')}" d="M30,140 Q80,120 120,120 L150,120 L150,180 L80,180 Z" />
    
    <!-- Porta Dianteira Dir -->
    <path class="stroke" fill="${getHex('peca_porta_dianteira_direita')}" d="M150,120 L240,120 L240,180 L150,180 Z" />
    
    <!-- Porta Traseira Dir -->
    <path class="stroke" fill="${getHex('peca_porta_traseira_direita')}" d="M240,120 L330,120 L330,180 L240,180 Z" />
    
    <!-- Lateral Traseira Dir -->
    <path class="stroke" fill="${getHex('peca_lateral_traseira_direita')}" d="M330,120 L400,120 Q450,120 460,160 L460,180 L380,180 Z" />
    
    <!-- Janelas Dir (Vidros) -->
    <path stroke="#333" stroke-width="2" fill="#90CAF9" d="M160,70 L235,70 L235,110 L140,110 Z" />
    <path stroke="#333" stroke-width="2" fill="#90CAF9" d="M245,70 L310,70 L320,110 L245,110 Z" />
    
    <!-- Teto Lateral Dir -->
    <path class="stroke" fill="#cccccc" d="M150,60 L320,60 L350,120 L120,120 Z" />

    <text x="180" y="220" class="text">VISTA DIREITA</text>
  </g>

  <!-- VISTA SUPERIOR (Centro Direita do SVG) -->
  <g transform="translate(550, 100)" class="shadow">
    <!-- Capô Dianteiro -->
    <rect x="0" y="0" width="140" height="90" rx="10" class="stroke" fill="${getHex('peca_capo_dianteiro')}" />
    
    <!-- Para-brisas Dianteiro -->
    <rect x="5" y="90" width="130" height="30" class="stroke" fill="#90CAF9" />
    
    <!-- Teto -->
    <rect x="5" y="120" width="130" height="150" class="stroke" fill="${getHex('peca_teto')}" />
    
    <!-- Para-brisas Traseiro -->
    <rect x="5" y="270" width="130" height="25" class="stroke" fill="#90CAF9" />
    
    <!-- Tampa Traseira / Porta Malas -->
    <rect x="0" y="295" width="140" height="60" rx="10" class="stroke" fill="${getHex('peca_tampa_traseira')}" />
    
    <text x="10" y="390" class="text">VISTA SUPERIOR</text>
  </g>

</svg>
    ''';
  }

  static String getCarSvgEstrutura({required Map<String, PdfColor> colors}) {
    // Um chassi básico para a estrutura, visualização superior (chassi em escada simplificado ou monobloco)
    String getHex(String key) {
      final color = colors[key] ?? PdfColor.fromHex('#e0e0e0');
      return color.toHex().substring(0, 7);
    }

    return '''
<svg viewBox="0 0 600 800" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .stroke { stroke: #222; stroke-width: 4; stroke-linecap: round; }
      .text { font-family: Helvetica, sans-serif; font-size: 16px; fill: #333333; font-weight: bold; }
    </style>
  </defs>
  
  <g transform="translate(150, 50)">
    <!-- Contorno do carro tracejado para referência -->
    <rect x="20" y="20" width="260" height="660" rx="30" stroke="#bbb" stroke-width="2" stroke-dasharray="10,10" fill="none" />
    
    <!-- Painel Frontal -->
    <rect x="60" y="40" width="180" height="20" class="stroke" fill="${getHex('painel_frontal')}" />
    
    <!-- Longarinas Dianteiras -->
    <rect x="80" y="60" width="20" height="100" class="stroke" fill="${getHex('longarina_dianteira_esquerda')}" />
    <rect x="200" y="60" width="20" height="100" class="stroke" fill="${getHex('longarina_dianteira_direita')}" />
    
    <!-- Caixas de Roda Dianteiras -->
    <rect x="30" y="80" width="30" height="60" rx="10" class="stroke" fill="${getHex('caixa_roda_dianteira_esquerda')}" />
    <rect x="240" y="80" width="30" height="60" rx="10" class="stroke" fill="${getHex('caixa_roda_dianteira_direita')}" />
    
    <!-- Torres de Amortecedor Dianteiras -->
    <circle cx="90" cy="110" r="15" class="stroke" fill="${getHex('torre_amortecedor_esquerda')}" />
    <circle cx="210" cy="110" r="15" class="stroke" fill="${getHex('torre_amortecedor_direita')}" />

    <!-- Painel Corta Fogo -->
    <rect x="60" y="160" width="180" height="15" class="stroke" fill="${getHex('painel_corta_fogo')}" />

    <!-- Colunas Dianteiras (A) -->
    <circle cx="50" cy="190" r="12" class="stroke" fill="${getHex('coluna_dianteira_esquerda')}" />
    <circle cx="250" cy="190" r="12" class="stroke" fill="${getHex('coluna_dianteira_direita')}" />

    <!-- Caixas de Ar -->
    <rect x="35" y="220" width="15" height="200" class="stroke" fill="${getHex('caixa_ar_esquerda')}" />
    <rect x="250" y="220" width="15" height="200" class="stroke" fill="${getHex('caixa_ar_direita')}" />

    <!-- Assoalhos -->
    <rect x="65" y="200" width="75" height="240" class="stroke" fill="${getHex('assoalho_esquerdo')}" />
    <rect x="160" y="200" width="75" height="240" class="stroke" fill="${getHex('assoalho_direito')}" />

    <!-- Longarinas Centrais -->
    <rect x="100" y="175" width="20" height="285" class="stroke" fill="${getHex('longarina_centro_esquerda')}" />
    <rect x="180" y="175" width="20" height="285" class="stroke" fill="${getHex('longarina_centro_direita')}" />

    <!-- Colunas Centrais (B) -->
    <circle cx="50" cy="320" r="12" class="stroke" fill="${getHex('coluna_central_esquerda')}" />
    <circle cx="250" cy="320" r="12" class="stroke" fill="${getHex('coluna_central_direita')}" />

    <!-- Colunas Traseiras (C) -->
    <circle cx="50" cy="460" r="12" class="stroke" fill="${getHex('coluna_traseira_esquerda')}" />
    <circle cx="250" cy="460" r="12" class="stroke" fill="${getHex('coluna_traseira_direita')}" />

    <!-- Longarinas Traseiras -->
    <rect x="80" y="460" width="20" height="140" class="stroke" fill="${getHex('longarina_traseira_esquerda')}" />
    <rect x="200" y="460" width="20" height="140" class="stroke" fill="${getHex('longarina_traseira_direita')}" />

    <!-- Caixas de Roda Traseiras -->
    <rect x="30" y="480" width="30" height="60" rx="10" class="stroke" fill="${getHex('caixa_roda_traseira_esquerda')}" />
    <rect x="240" y="480" width="30" height="60" rx="10" class="stroke" fill="${getHex('caixa_roda_traseira_direita')}" />

    <!-- Caixa de Estepe -->
    <circle cx="150" cy="530" r="45" class="stroke" fill="${getHex('caixa_estepe')}" />

    <!-- Painel Traseiro -->
    <rect x="60" y="600" width="180" height="20" class="stroke" fill="${getHex('painel_traseiro')}" />
    
    <text x="50" y="720" class="text">MAPA ESTRUTURAL DO VEÍCULO</text>
  </g>
</svg>
    ''';
  }
}
