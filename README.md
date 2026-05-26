<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-Cloud-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Status-Em%20Desenvolvimento-yellow?style=for-the-badge" />
<img src="https://img.shields.io/badge/Licença-Acadêmica-blue?style=for-the-badge" />

<br/><br/>

# 🌿 ÍNTEGRA
### Plataforma de Gestão de Clínicas Universitárias de Práticas Integrativas e Complementares em Saúde

<br/>

> Projeto acadêmico desenvolvido para a disciplina de **Programação para Dispositivos Móveis**  
> Curso de Ciência da Computação — **UERN (Universidade do Estado do Rio Grande do Norte)**  
> Docente: **Prof. Raul Benites Paradeda** | Ano: **2026**

</div>

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Objetivos](#-objetivos)
- [Arquitetura e Stack Tecnológico](#-arquitetura-e-stack-tecnológico)
- [Estrutura de Módulos](#-estrutura-de-módulos)
- [Estrutura de Diretórios](#-estrutura-de-diretórios)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação e Execução](#-instalação-e-execução)
- [Variáveis de Ambiente e Configuração](#-variáveis-de-ambiente-e-configuração)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Perfis de Acesso](#-perfis-de-acesso)
- [Requisitos Técnicos Obrigatórios](#-requisitos-técnicos-obrigatórios)
- [Autores](#-autores)

---

## 🌿 Sobre o Projeto

O **ÍNTEGRA** é um Sistema de Informação em Saúde (SIS) móvel, especializado na gestão de atendimentos clínicos de **Práticas Integrativas e Complementares em Saúde (PICS)**. O sistema foi concebido para atender ao **NUPICS (Núcleo de Práticas Integrativas e Complementares em Saúde) da UERN**, onde a documentação manual em papel gera ineficiência, fragmentação de dados e dificulta a produção de evidências científicas.

O aplicativo centraliza, organiza e analisa o fluxo de informações geradas por práticas como **acupuntura auricular, aromaterapia, massoterapia**, entre outras, servindo tanto a profissionais supervisores quanto a estagiários em formação.

**Problemas que o ÍNTEGRA resolve:**

- ❌ Prontuários manuais e em papel → ✅ Prontuário Eletrônico do Paciente (PEP) digital
- ❌ Fragmentação e perda de dados clínicos → ✅ Banco de dados centralizado em nuvem
- ❌ Dificuldade em comprovar horas de estágio → ✅ Relatórios automáticos para estagiários
- ❌ Ausência de suporte à decisão clínica → ✅ Identificação automática de padrões e recorrências de sintomas

---

## 🎯 Objetivos

### Objetivo Geral
Desenvolver um SIS móvel para a gestão completa e integrada de atendimentos clínicos de PICS em ambiente universitário, fornecendo ferramentas de suporte à decisão clínica e gestão acadêmica de estágios.

### Objetivos Específicos

| # | Objetivo |
|---|---|
| 1 | Estruturar um módulo de **Gestão de Pacientes** com cadastro completo e histórico clínico seguro |
| 2 | Projetar uma **Anamnese Estruturada** modular (histórico clínico, físico com mapeamento corporal interativo, e social) |
| 3 | Implementar o **Registro de Dados Clínicos** (sinais vitais: PA, FC, Temperatura) por atendimento |
| 4 | Desenvolver **Relatórios Inteligentes** para profissionais (padrões clínicos) e estagiários (comprovação de atendimentos) |
| 5 | Integrar **GPS** para geolocalização automática do ponto de atendimento |
| 6 | Integrar **Câmera** para digitalização de receitas, atestados e laudos |
| 7 | Garantir uma **UX intuitiva** para uso durante o atendimento clínico |

---

## 🏗️ Arquitetura e Stack Tecnológico

O ÍNTEGRA é construído com **Flutter** como framework de desenvolvimento mobile, escolhido por:

- **Motor de renderização próprio (Skia/Impeller):** Essencial para o componente de mapa corporal interativo (`CustomPainter`), que exige desenho pixel-perfect e detecção de toque precisa sobre uma imagem anatômica — impossível de implementar com a mesma elegância no React Native.
- **Compilação AOT para código nativo ARM:** Performance superior em operações de UI complexas e acesso a sensores do dispositivo.
- **Consistência visual garantida entre Android e iOS:** O Flutter não utiliza widgets nativos do sistema operacional, garantindo que a interface seja idêntica em ambas as plataformas.
- **Experiência prévia da equipe:** Elimina risco de curva de aprendizado em projeto com prazo definido.

### Stack Completa

```
┌────────────────────────────────────────────────────────────┐
│                     CAMADA DE APRESENTAÇÃO                  │
│              Flutter 3.x (Dart) — Material 3                │
├────────────────────────────────────────────────────────────┤
│                    CAMADA DE NEGÓCIO                        │
│       BLoC / Cubit (gerenciamento de estado)                │
├─────────────────────┬──────────────────────────────────────┤
│    SERVIÇOS NATIVOS │         SERVIÇOS REMOTOS              │
│  geolocator (GPS)   │  Firebase Auth (autenticação)         │
│  image_picker       │  Cloud Firestore (banco de dados)     │
│  (câmera/galeria)   │  Firebase Storage (mídias)            │
│  permission_handler │  dio (HTTP client)                    │
├─────────────────────┴──────────────────────────────────────┤
│                   INFRAESTRUTURA (NUVEM)                    │
│            Google Firebase (Backend-as-a-Service)           │
└────────────────────────────────────────────────────────────┘
```

### Dependências Principais (`pubspec.yaml`)

| Pacote | Versão | Finalidade | Justificativa |
|--------|--------|-----------|---------------|
| `firebase_core` | ^3.x | Inicialização do Firebase | SDK oficial Google para Flutter |
| `firebase_auth` | ^5.x | Autenticação de usuários (Profissional/Estagiário) | Gerenciamento seguro de perfis de acesso |
| `cloud_firestore` | ^5.x | Banco de dados NoSQL em nuvem (RF012) | Persistência centralizada, acesso em tempo real |
| `firebase_storage` | ^12.x | Armazenamento de mídias (imagens digitalizadas) | Integração nativa com Firestore, URLs seguras |
| `geolocator` | ^13.x | Captura de GPS (RF010) | API unificada, bem mantida, suporte a permissões |
| `image_picker` | ^1.x | Acesso à câmera e galeria (RF011) | Biblioteca oficial Flutter, suporte robusto |
| `dio` | ^5.x | HTTP client para chamadas à API/backend | Suporte a interceptors, upload multipart, retry |
| `flutter_bloc` | ^8.x | Gerenciamento de estado (BLoC pattern) | Separa UI da lógica de negócio, testável |
| `permission_handler` | ^11.x | Gerenciamento de permissões Android/iOS | Abstrai diferenças entre plataformas |
| `pdf` | ^3.x | Geração de relatórios em PDF (RF006, RF007) | Criação de PDFs diretamente no dispositivo |
| `fl_chart` | ^0.x | Gráficos nos relatórios clínicos | Visualização da evolução do paciente |
| `intl` | ^0.x | Formatação de datas e localização (pt-BR) | Internacionalização |
| `go_router` | ^14.x | Navegação declarativa entre telas | Gerenciamento robusto de rotas e deep links |

---

## 🧩 Estrutura de Módulos

O ÍNTEGRA é organizado em **5 módulos funcionais** principais:

```
ÍNTEGRA
│
├── 👤 Módulo: Autenticação
│   └── Login por perfil (Profissional/Supervisor ou Estagiário)
│
├── 🏠 Módulo: Dashboard
│   └── Resumo do dia (agendamentos, pendentes) e acesso rápido
│
├── 📋 Módulo: Gestão de Pacientes
│   ├── Cadastro e edição de dados pessoais (RF001)
│   ├── Histórico completo de atendimentos (RF002)
│   └── Busca e filtragem de pacientes
│
├── 🩺 Módulo: Atendimento
│   ├── Anamnese Estruturada — 1º Atendimento
│   │   ├── Anamnese Clínica (histórico de saúde, queixa principal)
│   │   ├── Anamnese Física — Mapa Corporal Interativo (RF004)
│   │   │   └── CustomPainter: marcação de Pontos de Dor e Tensão Muscular
│   │   └── Anamnese Social (moradia, renda, composição familiar) (RF003)
│   ├── Registro de Atendimento
│   │   ├── Sinais Vitais — PA, FC, Temperatura (RF005)
│   │   ├── Terapias aplicadas (seleção múltipla)
│   │   ├── Observações clínicas (campo livre)
│   │   ├── Captura GPS automática ao salvar (RF010)
│   │   └── Digitalização de documentos via câmera (RF011)
│   └── Consulta de Histórico com linha do tempo (RF002)
│
└── 📊 Módulo: Relatórios Inteligentes
    ├── Relatório Clínico — resumo evolutivo + identificação de padrões (RF006, RF008)
    │   └── Gráfico de evolução da dor (fl_chart)
    └── Relatório de Estágio — quantitativo por período (RF007)
        └── Exportação em PDF (pacote pdf)
```

---

## 📁 Estrutura de Diretórios

```
integra_app/
│
├── android/                        # Configurações nativas Android
│   └── app/src/main/
│       ├── AndroidManifest.xml     # Permissões: LOCATION, CAMERA, INTERNET
│       └── google-services.json    # Configuração Firebase (não commitado)
│
├── ios/                            # Configurações nativas iOS
│   └── Runner/
│       ├── Info.plist              # Descrições de permissão (NSLocation, NSCamera)
│       └── GoogleService-Info.plist # Configuração Firebase iOS (não commitado)
│
├── lib/
│   ├── main.dart                   # Ponto de entrada, inicialização do Firebase
│   │
│   ├── app/
│   │   ├── app.dart                # MaterialApp, tema global, GoRouter
│   │   └── routes.dart             # Definição de todas as rotas nomeadas
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart     # Paleta de cores (Azul Safira, Verde-Água)
│   │   │   └── app_strings.dart    # Strings e textos centralizados
│   │   ├── services/
│   │   │   ├── gps_service.dart    # Abstração do geolocator
│   │   │   ├── camera_service.dart # Abstração do image_picker
│   │   │   └── auth_service.dart   # Abstração do Firebase Auth
│   │   └── utils/
│   │       └── validators.dart     # Validações de formulário
│   │
│   ├── data/
│   │   ├── models/                 # Classes de domínio (data classes)
│   │   │   ├── usuario_model.dart
│   │   │   ├── paciente_model.dart
│   │   │   ├── atendimento_model.dart
│   │   │   ├── anamnese_model.dart
│   │   │   ├── dados_clinicos_model.dart
│   │   │   ├── midia_model.dart
│   │   │   └── relatorio_model.dart
│   │   └── repositories/           # Acesso ao Firestore/Storage
│   │       ├── paciente_repository.dart
│   │       ├── atendimento_repository.dart
│   │       └── relatorio_repository.dart
│   │
│   └── presentation/
│       ├── auth/
│       │   ├── login_screen.dart
│       │   └── bloc/auth_bloc.dart
│       ├── dashboard/
│       │   └── dashboard_screen.dart
│       ├── pacientes/
│       │   ├── lista_pacientes_screen.dart
│       │   ├── cadastro_paciente_screen.dart
│       │   ├── historico_paciente_screen.dart
│       │   └── bloc/paciente_bloc.dart
│       ├── atendimento/
│       │   ├── registro_atendimento_screen.dart
│       │   ├── anamnese_clinica_screen.dart
│       │   ├── anamnese_fisica_screen.dart     # CustomPainter — mapa corporal
│       │   ├── anamnese_social_screen.dart
│       │   └── bloc/atendimento_bloc.dart
│       └── relatorios/
│           ├── relatorio_clinico_screen.dart
│           ├── relatorio_estagio_screen.dart
│           └── bloc/relatorio_bloc.dart
│
├── assets/
│   ├── images/
│   │   ├── logo_integra.png
│   │   ├── body_map_front.png      # Mapa corporal — frente
│   │   └── body_map_back.png       # Mapa corporal — costas
│   └── fonts/
│
├── test/                           # Testes unitários e de widget
│
├── pubspec.yaml                    # Dependências do projeto
├── pubspec.lock
├── .env.example                    # Exemplo de variáveis de ambiente
├── .gitignore
└── README.md
```

---

## ⚙️ Pré-requisitos

Certifique-se de ter as seguintes ferramentas instaladas e configuradas:

| Ferramenta | Versão Mínima | Link |
|------------|---------------|------|
| Flutter SDK | 3.22.x ou superior | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.4.x (incluído no Flutter) | Instalado com o Flutter |
| Android Studio | Hedgehog (2023.1.1) ou superior | Com Android SDK 34+ e emulador configurado |
| Xcode | 15.x (apenas macOS, para iOS) | Via Mac App Store |
| Git | 2.x | [git-scm.com](https://git-scm.com) |
| Conta Firebase | — | [console.firebase.google.com](https://console.firebase.google.com) |

**Verificar instalação do Flutter:**
```bash
flutter doctor -v
```
Todos os itens relevantes devem estar marcados com ✅.

---

## 🚀 Instalação e Execução

### 1. Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/integra_app.git
cd integra_app
```

### 2. Configurar o Firebase

O ÍNTEGRA utiliza o Firebase como backend. Você precisa criar seu próprio projeto e configurá-lo:

**a) Instalar o Firebase CLI e FlutterFire CLI:**
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

**b) Criar o projeto Firebase:**
- Acesse [console.firebase.google.com](https://console.firebase.google.com)
- Crie um novo projeto chamado `integra-app`
- Habilite os seguintes serviços:
  - **Authentication** (método: E-mail/Senha)
  - **Cloud Firestore** (modo de produção, região: `southamerica-east1`)
  - **Firebase Storage**

**c) Configurar o FlutterFire no projeto:**
```bash
flutterfire configure --project=SEU_PROJETO_FIREBASE_ID
```
Esse comando gera automaticamente o arquivo `lib/firebase_options.dart`. **Não commite este arquivo.**

**d) Baixar os arquivos de configuração nativa:**
- `google-services.json` → copiar para `android/app/`
- `GoogleService-Info.plist` → copiar para `ios/Runner/`

> ⚠️ Estes arquivos contêm chaves privadas. Eles já estão listados no `.gitignore`.

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Configurar Permissões Nativas

#### Android — `android/app/src/main/AndroidManifest.xml`
Adicione dentro da tag `<manifest>`:
```xml
<!-- Localização -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Câmera -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />

<!-- Internet (obrigatório para Firebase) -->
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS — `ios/Runner/Info.plist`
Adicione dentro da tag `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>O ÍNTEGRA precisa da sua localização para registrar o local do atendimento clínico.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>O ÍNTEGRA precisa da sua localização para registrar o local do atendimento clínico.</string>

<key>NSCameraUsageDescription</key>
<string>O ÍNTEGRA usa a câmera para digitalizar receitas, atestados e laudos do paciente.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>O ÍNTEGRA acessa a galeria para anexar documentos ao prontuário do paciente.</string>
```

### 5. Executar o Aplicativo

**Em um emulador Android ou dispositivo físico:**
```bash
# Listar dispositivos disponíveis
flutter devices

# Rodar em modo debug
flutter run

# Rodar em um dispositivo específico
flutter run -d <device_id>
```

**Para gerar o APK de debug:**
```bash
flutter build apk --debug
# APK gerado em: build/app/outputs/flutter-apk/app-debug.apk
```

**Para gerar o APK de release:**
```bash
flutter build apk --release
# APK gerado em: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔧 Variáveis de Ambiente e Configuração

As configurações sensíveis do Firebase são gerenciadas pelo arquivo `lib/firebase_options.dart` (gerado pelo `flutterfire configure`, nunca commitado).

Copie o arquivo de exemplo e preencha com os dados do seu projeto Firebase:

```bash
cp .env.example .env
```

O arquivo `.env.example` contém:
```env
# Não é necessário para Firebase com FlutterFire CLI.
# Adicione aqui outras variáveis de ambiente caso o projeto
# evolua para uma arquitetura com backend customizado (ex: API REST).

# Exemplo:
# API_BASE_URL=https://sua-api.supabase.co
# API_KEY=sua_chave_de_api
```

---

## ✨ Funcionalidades Principais

### 🗺️ Mapa Corporal Interativo (Anamnese Física)
Componente customizado desenvolvido com `CustomPainter` e `GestureDetector`. O profissional toca sobre a silhueta anatômica para marcar:
- 🔴 **Pontos de Dor** — círculo sólido vermelho
- 🟢 **Tensão Muscular** — círculo contornado verde

As coordenadas normalizadas (x%, y%) são salvas no Firestore associadas ao atendimento, permitindo reexibição fiel em qualquer resolução de tela.

### 📍 Captura de GPS no Atendimento
Ao tocar em "Salvar Registro", o `GpsService` (que abstrai o `geolocator`) captura automaticamente latitude e longitude do dispositivo. As coordenadas são salvas junto ao atendimento no Firestore, identificando se o procedimento ocorreu na clínica ou em deslocamento externo.

### 📷 Digitalização de Documentos
O `CameraService` (que abstrai o `image_picker`) permite ao profissional fotografar receitas, atestados e laudos diretamente pelo aplicativo. As imagens são enviadas ao **Firebase Storage** e a URL pública segura é salva no prontuário eletrônico do atendimento correspondente.

### 📊 Relatórios Inteligentes com Identificação de Padrões
O módulo de relatórios analisa o histórico do paciente para identificar recorrência de sintomas (RF008), exibindo gráficos de evolução via `fl_chart` e gerando PDFs exportáveis com o pacote `pdf`.

---

## 👥 Perfis de Acesso

| Funcionalidade | Profissional/Supervisor | Estagiário |
|---|:---:|:---:|
| Gerenciar Pacientes | ✅ | ✅ |
| Realizar Anamnese | ✅ | ✅ |
| Registrar Atendimento | ✅ | ✅ |
| Consultar Histórico | ✅ | ✅ |
| Digitalizar Documentos | ✅ | ✅ |
| Registrar Localização (GPS) | ✅ | ✅ |
| Gerar Relatório de Estágio | ✅ | ✅ |
| **Gerar Relatório Clínico** | ✅ | ❌ |
| **Identificar Recorrência de Sintomas** | ✅ | ❌ |
| **Gerenciar Usuários** | ✅ | ❌ |

---

## 📱 Requisitos Técnicos Obrigatórios

### RF010 — GPS
- **Biblioteca:** `geolocator: ^13.x`
- **Implementação:** Captura automática de coordenadas (lat/lng) no momento em que o registro de atendimento é salvo.
- **Permissões:** `ACCESS_FINE_LOCATION` (Android) e `NSLocationWhenInUseUsageDescription` (iOS).
- **Armazenamento:** Coordenadas salvas como campos `latitude` e `longitude` no documento de `Atendimento` no Firestore.

### RF011 — Mídia (Câmera)
- **Biblioteca:** `image_picker: ^1.x`
- **Implementação:** Acesso exclusivo à câmera para fotografar documentos do paciente. Imagens são comprimidas, enviadas ao Firebase Storage e a URL é associada ao prontuário.
- **Permissões:** `CAMERA` (Android) e `NSCameraUsageDescription` (iOS).

### RF012 — Banco de Dados Remoto
- **Serviço:** Google Cloud Firestore (Firebase)
- **Modo de operação:** **Online exclusivo** — o aplicativo não possui cache offline ativo. Requer conexão ativa com a internet para todas as operações de leitura e escrita.
- **Coleções principais:** `usuarios`, `pacientes`, `atendimentos`, `anamneses`, `dados_clinicos`, `midias`, `relatorios`.

---

## 👨‍💻 Autores

<table>
  <tr>
    <td align="center">
      <b>Eduardo Milhomes Barbosa de Medeiros</b><br/>
      Estudante de Ciência da Computação — UERN<br/>
      <a href="https://github.com/">GitHub</a>
    </td>
    <td align="center">
      <b>José Júnior Medeiros Andrade</b><br/>
      Estudante de Ciência da Computação — UERN<br/>
      <a href="https://github.com/">GitHub</a>
    </td>
  </tr>
</table>

---

<div align="center">

**ÍNTEGRA** — Plataforma de Gestão Clínica Integrativa  
Projeto Acadêmico · UERN Natal · 2026  
Disciplina: Programação para Dispositivos Móveis  
Docente: Prof. Raul Benites Paradeda

</div>