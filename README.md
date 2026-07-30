# 🚗 App Auto Vistoria — Laudos Cautelares & Pesquisas Veiculares

O **App Auto Vistoria** é uma solução profissional mobile (desenvolvida em Flutter) voltada para peritos, vistoriadores e empresas de consultas veiculares. O aplicativo possui arquitetura **Offline-First**, integração com serviços de consulta de histórico/BIN (Radar Consultas / AutoCredCar), leitura de placas por câmera (OCR ML Kit), wizard completo de vistoria cautelar e geração/emissão de laudos em PDF com upload em nuvem (Supabase).

---

## 📌 Visão Geral do Sistema

O aplicativo disponibiliza **dois módulos/serviços principais** na tela inicial:

1. **Vistoria Cautelar**:
   - Fluxo completo de inspeção cautelar veicular para **Carros**, **Caminhões** e **Veículos com Croqui de Estrutura**.
   - Wizard guiado com 11 etapas interativas.
   - Teste e medição de micragem de pintura por peça veicular.
   - Checklist minucioso de vidros, etiquetas, chassi, motor e itens de segurança.
   - Registro fotográfico com marcação visual de irregularidades.
   - Assinatura digital do cliente/vistoriador e conclusão de laudo com parecer (Aprovado, Com Apontamentos, Reprovado).
   - Prazo de retificação de laudo de **72 horas**.

2. **Pesquisa Veicular**:
   - Consulta isolada e rápida de veículos por **Placa**, **Chassi** ou **Motor**.
   - Suporte a múltiplos produtos da API Radar Consultas:
     - `AUTO BIN`
     - `AUTO PERÍCIA`
     - `AUTO COMPLETA`
     - `AUTO LEILÃO`
     - `AUTO BASE ESTADUAL`
     - `AUTO DÉBITOS E RECALL`
   - Visualização instantânea de dados na tela (**Acessar a Pesquisa**).
   - Download direto do relatório PDF oficial (**Baixar a Pesquisa**).
   - Sistema inteligente de reaproveitamento de histórico (evita consultas duplicadas no prazo de 72h).

---

## 🏗️ Arquitetura do Projeto

O projeto adota os princípios de **Clean Architecture** e **Offline-First**, estruturado em módulos (`features`) e com injeção de dependências global via `GetIt`.

```text
lib/
├── core/                        # Núcleo de utilitários, temas, erros e serviços globais
│   ├── constants/               # Constantes de configuração da aplicação
│   ├── mock/                    # Dados mockados para testes e fallback offline
│   ├── services/                # Serviços de PDF, Câmera OCR, Supabase Storage e Radar Service
│   ├── theme/                   # Sistema de design visual e tokens (AppTheme)
│   └── utils/                   # Formatadores de texto, placa, moedas e datas
├── database/                    # Camada de Persistência Local (Offline-First)
│   ├── app_database.dart        # Configuração do banco SQLite local usando Drift ORM
│   ├── daos/                    # DAOs (VistoriaDao, AutocredDao)
│   └── tables/                  # Esquemas das tabelas (Vistorias, Veiculos, Fotos, Inspecoes)
├── features/                    # Módulos funcionais da aplicação
│   ├── auth/                    # Autenticação de usuários (Supabase Auth)
│   ├── consulta_bin/            # Histórico e integração de consultas veiculares (Radar API)
│   ├── pdf/                     # Visualização e geração de laudos em PDF
│   └── vistoria/                # Fluxo de Vistoria Cautelar (Screens, Widgets, Wizard, BLoC)
├── injection_container.dart     # Service Locator (GetIt) para injeção de dependências
├── main.dart                    # Ponto de entrada do app Flutter
└── router.dart                  # Configuração de rotas de navegação (GoRouter)
```

---

## 🛠️ Tecnologias e Bibliotecas Utilizadas

- **Core**: [Flutter](https://flutter.dev/) (SDK ^3.5.0) & Dart
- **Gerenciamento de Estado**: [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) & [`provider`](https://pub.dev/packages/provider)
- **Persistência Local (SQLite)**: [`drift`](https://pub.dev/packages/drift) + `sqlite3_flutter_libs`
- **Backend & Cloud**: [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) (Autenticação e Storage de PDFs/Fotos)
- **OCR (Leitura de Placas)**: [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition) + `camera`
- **Geração e Impressão de PDF**: [`pdf`](https://pub.dev/packages/pdf), [`printing`](https://pub.dev/packages/printing), `syncfusion_flutter_pdf`
- **Navegação**: [`go_router`](https://pub.dev/packages/go_router)
- **Injeção de Dependências**: [`get_it`](https://pub.dev/packages/get_it)
- **Rede e Requisições**: [`dio`](https://pub.dev/packages/dio) & `url_launcher`

---

## 🚀 Como Executar o Projeto Localmente

### Pré-requisitos

- **Flutter SDK** instalado (versão igual ou superior a 3.5.0).
- **Android Studio** ou **VS Code** com extensão Flutter/Dart instalada.
- Emulador Android/iOS ou dispositivo físico conectado.

### 1. Clonar o Repositório e Instalar Dependências

```bash
git clone <URL_DO_REPOSITORIO>
cd app_vistoria
flutter pub get
```

### 2. Configurar Variáveis de Ambiente (`.env`)

Crie ou edite o arquivo `.env` na raiz do projeto contendo as chaves do Supabase e APIs externas:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anonima-aqui
RADAR_API_TOKEN=seu-token-radar-aqui
```

### 3. Gerar Códigos Automáticos (Drift ORM)

Sempre que alterar esquemas de tabelas no diretório `lib/database/tables/`, execute o `build_runner`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Executar o App

```bash
flutter run
```

---

## 🗄️ Banco de Dados e Scripts SQL

O sistema conta com tabelas locais SQLite (Drift) e tabelas/buckets remotos no Supabase.

- `setup_laudos_pdf_bucket.sql`: Script de criação e políticas de acesso (RLS) para o bucket de armazenamento de PDFs dos laudos concluídos no Supabase.
- `supabase_setup.sql`: Estrutura de tabelas remotas e sincronização de vistorias/consultas na nuvem.

---

## 🔄 Fluxos de Trabalho do Aplicativo

### Fluxo 1: Pesquisa Veicular
1. O usuário clica em **Pesquisa** na tela inicial.
2. Seleciona o **Tipo de Consulta** (ex: AUTO BIN, AUTO COMPLETA).
3. Informa a **Placa** ou **Chassi** (via teclado ou tirando foto da placa com OCR).
4. O sistema consulta a base da Radar / Histórico e retorna o veículo.
5. O usuário utiliza o botão **Acessar a Pesquisa** (para ver todos os dados na tela) ou **Baixar a Pesquisa** (para obter o relatório PDF oficial).

### Fluxo 2: Vistoria Cautelar Completa
1. O usuário clica em **Cautelar** na tela inicial.
2. Seleciona a categoria do veículo (Carro Cautelar, Caminhão, Croqui).
3. Informa a Placa/Chassi para puxar dados preliminares da BIN.
4. Entra no **Wizard de 11 Etapas**:
   - Dados do Veículo & Cliente
   - Medição de Micragem de Pintura
   - Inspeção de Chassi, Motor, Vidros e Etiquetas
   - Verificação Estrutural & Apontamentos
   - Registro Fotografico Obrigatório (Fotos com guias)
   - Parecer Técnico & Observações
   - Assinatura Digital do Cliente e Vistoriador
5. O laudo é finalizado, armazenado localmente e publicado em PDF no Supabase Storage.

---

## 📝 Guias de Boas Práticas para Novos Desenvolvedores

1. **Adição de Novas Telas**:
   - Declare a rota em `lib/router.dart`.
   - Mantenha o padrão de UI utilizando tokens do `AppTheme` (`lib/core/theme/app_theme.dart`).

2. **Edição do Banco de Dados Drift**:
   - Ao alterar um arquivo em `lib/database/tables/`, altere a versão do banco em `lib/database/app_database.dart` e rode o `build_runner`.

3. **Gerenciamento de Erros no PDF**:
   - Toda alteração nos layouts de laudo em PDF deve ser testada na tela de preview (`PdfPreviewScreen`).

---

*Documentação atualizada em Julho/2026.*
