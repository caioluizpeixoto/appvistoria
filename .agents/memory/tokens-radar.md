# Catálogo de Tokens - Radar Consultas

Tokens e parâmetros oficiais da API Radar Consultas mapeados para uso em consultas veiculares no aplicativo e nas Edge Functions:

| Identificador / Slug | Nome Amigável | Parâmetro Aceito | Token da API Radar |
| :--- | :--- | :--- | :--- |
| `numero_crv` | Número CRV | `PLACA` | `21696E59C08FB7F176883961615M79UH32B1WOVGJHFY255O0I` |
| `codigo_crv` | Código CRV | `PLACA` | `21697118FF9B1101769019647Q5BFBB9FWVUYXKE9DRDLFYWFZ` |
| `auto_completa` | Auto Completa | `PLACA` | `21588A87D591BBD1485473749QJKNKEIFTWHHBWDJJVDNEOB76` |
| `auto_bin` | Auto BIN | `PLACA` ou `CHASSI` | `21589A1C74E953B1486494836NQ70TJ0EUZFTS9K7GGLAMHKOJ` |
| `auto_base_estadual` | Auto Base Estadual | `PLACA` | `21589C4F6FE5D851486638959Z74PAKY8WJ4M8EF5LQB945K5N` |
| `auto_pericia` | Auto Perícia | `PLACA` | `2158B04671523351487947377ALQNCW8LN4VGIJHLHSFJDD5G9` |
| `auto_leilao` | Auto Leilão | `PLACA` ou `CHASSI` | `2158DD027974724149087909770OG7270OE8LK17N7RET0LSJ3` |
| `auto_estadual_proprietario` | Auto Estadual + Proprietário | `PLACA` | `2158DE583B7654714909665876FV8VSPNER2DHLZR81SPVLMZ0` |
| `auto_decodificador_chassi` | Auto Decodificador de Chassi | `CHASSI` | `2158F0F1EF0ADB11492185583PRLK042XHWPU83FX7V5DJ8MRT` |
| `auto_gravame` | Auto Gravame | `CHASSI` | `2158FA1C23B8B8C1492786211KU65H6GRCDCNNLXZARBEQRLGY` |
| `auto_debitos_recall` | Auto Débitos + Recall | `PLACA` ou `CHASSI` | `2159EA6BFB60104150853529156RSGFTC62RP1XWPKV9CT99P1` |
| `auto_analise` | Auto Análise | `PLACA` | `215C7D7C9C6A8151551727772AXVADBADNQZAWS5M9SLVVF0R1` |
| `auto_analise_plus` | Auto Análise + | `PLACA` | `215C7D7D8400EAB1551728004RDCEG7NQ58EGUG34O9O4ATTRI` |
| `auto_pericia_hrf` | Auto Perícia HRF | `PLACA` | `2162AB9E27B63CD1655414311NO8UOXTCZ2SC4CW1L75PRFEVN` |
| `bin_por_motor` | Bin por Motor | `MOTOR` | `2162E98433071ED165947089995HQEQV32WR95PCLFIHJS2AOD` |
| `e_crlv_nova` | E-CRLV NOVA | Ver detalhe abaixo | `216952A87095C431767024752XO8PQAC1LARXMPKCF9J3DQ428` |

### Detalhes E-CRLV NOVA
- Estados: SP, MG, TO, PI, MA, AP, PA, MT, MS, SE, PR, BA, GO, AL, RR e RO: `(CPF ou CNPJ), PLACA e UF`.
- Estados: AC, AM, CE, DF, ES, PB, PE, RJ, RS e SC: `(CPF ou CNPJ), PLACA, RENAVAM e UF`.
- Estado: RN: `(CPF ou CNPJ), PLACA, RENAVAM, UF e CRV`.
