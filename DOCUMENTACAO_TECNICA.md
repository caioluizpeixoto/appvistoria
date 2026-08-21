# 📘 Manual de Documentação Técnica e Arquitetura do Sistema
## Ultra Prime — Sistema de Vistoria Cautelar & Pesquisa Veicular

**Versão da Documentação:** 1.0.0  
**Data:** 20 de Agosto de 2026  
**Repositório Oficial:** [https://github.com/caioluizpeixoto/appvistoria](https://github.com/caioluizpeixoto/appvistoria)  
**Público-Alvo:** Gestores Técnicos, Desenvolvedores e Administradores de TI  

---

## 1. Visão Geral do Produto

O **Ultra Prime** é uma plataforma mobile de nível corporativo projetada para empresas de perícia, concessionárias, vistorias cautelares e despachantes. O sistema integra inteligência artificial em borda (OCR para leitura de placas), operação **Offline-First** (resiliência sem conexão à internet) e integração direta com serviços de dados veiculares nacionais (Radar Consultas / AutoCredCar / BIN) e armazenamento em nuvem via Supabase.

---

## 2. Módulos e Funcionalidades

### 2.1. Módulo de Vistoria Cautelar Completa
* **Tipos de Inspeção:** Suporte a Carros de Passeio, Caminhões e Veículos Comerciais com croqui estrutural dinâmico.
* **Wizard de 11 Etapas Guiadas:**
  1. Identificação do Veículo e Dados do Solicitante/Proprietário.
  2. Medição Técnica de Micragem de Pintura (leitura ponto a ponto com mapa de calor).
  3. Verificação de Chassi, Gravação de Motor e Câmbio.
  4. Checklist de Vidros, Faróis, Lanternas e Etiquetas de Segurança (ETA/VIS).
  5. Inspeção Estrutural (Longarinas, Caixas de Roda, Colunas A/B/C, Painel Frontal e Traseiro).
  6. Itens de Segurança, Pneus, Estepe e Mecânica Geral.
  7. Registro Fotográfico Obrigatório (Câmera com guias visuais e validação de resolução).
  8. Módulo de Apontamentos e Avarias com marcação gráfica sobre o croqui.
  9. Parecer Técnico Final (*Aprovado*, *Aprovado com Apontamentos*, *Reprovado*).
  10. Assinatura Digital na tela (Perito e Cliente).
  11. Emissão imediata do Laudo Pericial em PDF.
* **Política de Retificação:** Janela de 72 horas para correção e atualização de laudos emitidos.

### 2.2. Módulo de Pesquisas e Consultas Veiculares (BIN / Histórico)
* **Tipos de Consultas Integradas:**
  * `AUTO BIN`: Dados cadastrais oficiais da base nacional.
  * `AUTO PERÍCIA`: Histórico de leilão, sinistro, roubo e furto.
  * `AUTO COMPLETA`: Análise 360° com débitos, restrições e gravame.
  * `AUTO BASE ESTADUAL`: Débitos locais, IPVA, multas e licenciamento.
  * `AUTO DÉBITOS E RECALL`: Chamados de recall e débitos pendentes.
* **Leitor OCR Inteligente:** Leitura instantânea de placa mercosul/antiga através da câmera do dispositivo via Google ML Kit.
* **Visualização & Download:** Visualização instantânea na tela do app ou geração do relatório oficial em PDF pronto para compartilhamento.
* **Cache Inteligente:** Reaproveitamento de histórico para economia de custos com consultas duplicadas.

---

## 3. Arquitetura de Software

O aplicativo foi desenvolvido seguindo os princípios de **Clean Architecture** e **Design Modular (Feature-First)**, garantindo separação rigorosa de responsabilidades, alta testabilidade e fácil manutenção.

```text
lib/
├── core/                        # Núcleo compartilhado
│   ├── constants/               # Constantes de configuração e URLs
│   ├── errors/                  # Tratamento centralizado de exceções e falhas
│   ├── normalizers/             # Normalização de dados recebidos de APIs
│   ├── services/                # Serviços de PDF, Câmera OCR, Supabase e Radar
│   ├── theme/                   # Sistema de Design Tokens (Cores, Tipografia, Cards)
│   └── utils/                   # Formatadores (Placas, CPF/CNPJ, Moedas, Datas)
├── database/                    # Camada de Persistência Local (Offline-First)
│   ├── app_database.dart        # Banco SQLite via Drift ORM
│   ├── daos/                    # DAOs (VistoriaDao, AutocredDao)
│   └── tables/                  # Esquemas (Vistorias, Veiculos, Fotos, Inspecoes)
├── features/                    # Módulos de Domínio e Apresentação
│   ├── auth/                    # Fluxo de Autenticação
│   ├── consulta_bin/            # Consultas e Histórico de Pesquisas
│   ├── pdf/                     # Visualização e Renderização de Laudos
│   └── vistoria/                # Wizard, Checklist, Croquis e Pareceres
├── injection_container.dart     # Service Locator e Injeção de Dependência (GetIt)
├── main.dart                    # Inicialização da Aplicação
└── router.dart                  # Roteamento Declarativo (GoRouter)
```

---

## 4. Stack Tecnológica e Dependências

| Componente | Tecnologia | Finalidade |
| :--- | :--- | :--- |
| **Linguagem & Framework** | Flutter SDK (^3.5) / Dart | Aplicação mobile nativa multiplataforma (Android e iOS) |
| **Gerenciamento de Estado**| `flutter_bloc` & `provider` | Fluxo previsível e reativo de estados |
| **Banco Local (Offline)** | SQLite via `drift` | Armazenamento local de vistorias, rascunhos e fotos |
| **Backend & Cloud** | Supabase (PostgreSQL + Auth + Storage) | Sincronização em nuvem, controle de acessos e CDN |
| **Backend Serverless** | Supabase Edge Functions (Deno / TypeScript) | Processamento de relatórios e regras de negócio complexas |
| **Reconhecimento Óptico (OCR)**| `google_mlkit_text_recognition` | Leitura em tempo real de placas veiculares pela câmera |
| **Motor de Relatórios PDF** | `pdf` & `printing` | Geração de laudos diagramados em alta resolução vetorial |
| **Comunicação HTTP** | `dio` | Cliente HTTP com interceptors e retentativas |
| **Injeção de Dependências** | `get_it` | Desacoplamento e injeção de serviços/repositórios |

---

## 5. Banco de Dados e Infraestrutura Cloud

### 5.1. Banco de Dados Local (SQLite / Drift)
Garante que o vistoriador realize vistorias completas no pátio ou subsolo **sem sinal de internet**. Os dados e fotos são gravados localmente e sincronizados assim que a conexão é restabelecida.

### 5.2. Banco de Dados Remoto (Supabase / PostgreSQL)
* **Tabelas Principais:** Usuários, Permissões, Histórico de Consultas BIN, Laudos de Vistoria, Metadados de Mídias.
* **Segurança (RLS - Row Level Security):** Políticas ativas para garantir que cada organização acesse exclusivamente seus próprios registros.
* **Storage Buckets:**
  * `laudos-pdf`: Armazenamento com link seguro para download e auditoria dos laudos periciais.
  * `fotos-vistoria`: Armazenamento otimizado de imagens de vistorias com categorização por veículo.

---

## 6. Guia de Instalação, Configuração e Deploy

### 6.1. Pré-requisitos
* Flutter SDK (v3.5.0 ou superior).
* Android Studio (SDK Android 34+) / Xcode (para compilação iOS).
* Node.js & Supabase CLI (para deploy de Edge Functions e migrations).

### 6.2. Configuração do Arquivo de Ambiente (`.env`)
Na raiz do projeto, configure o arquivo `.env`:
```env
SUPABASE_URL=https://[SEU-PROJETO].supabase.co
SUPABASE_ANON_KEY=[SUA-CHAVE-PUBLICA-ANONIMA]
RADAR_API_TOKEN=[SEU-TOKEN-DA-RADAR-CONSULTAS]
```

### 6.3. Passos para Execução Local
```bash
# 1. Obter dependências do Flutter
flutter pub get

# 2. Executar gerador de código (Drift ORM)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Iniciar o app em modo de desenvolvimento
flutter run
```

### 6.4. Geração de Builds de Produção

#### Para Android (Google Play Store):
```bash
# Geração do pacote otimizado AAB (Android App Bundle)
flutter build appbundle --release

# Geração de APK direto para instalação manual
flutter build apk --release
```

#### Para iOS (Apple App Store):
```bash
# Geração do pacote IPA / Xcode Archive
flutter build ipa --release
```

---

## 7. Segurança, Conformidade e Boas Práticas

1. **Proteção de Segredos:** Tokens de serviços e credenciais são injetados exclusivamente via variáveis de ambiente (`.env`), nunca hardcoded no código.
2. **Criptografia em Trânsito:** Todas as comunicações utilizam conexões seguras criptografadas (HTTPS / TLS 1.3).
3. **Imutabilidade de Laudos:** Laudos emitidos possuem hash de controle e bloqueio após o período legal de retificação.

---

**Elaborado por:** Equipe de Engenharia de Software  
**Contato:** suporte@caioluizpeixoto.dev | Repositório: [caioluizpeixoto/appvistoria](https://github.com/caioluizpeixoto/appvistoria)
