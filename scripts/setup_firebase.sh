#!/bin/bash

# =============================================================================
# Script para configurar o Firebase no projeto Flutter
# =============================================================================
# Uso: ./setup_firebase.sh
#
# Variáveis de ambiente necessárias:
#   GOOGLE_SERVICES_JSON_URL    - URL do arquivo google-services.json (Android)
#   GOOGLE_SERVICE_INFO_PLIST_URL - URL do arquivo GoogleService-Info.plist (iOS)
#
# Exemplo:
#   export GOOGLE_SERVICES_JSON_URL="https://firebasestorage.googleapis.com/v0/b/sigave-7dbf5.firebasestorage.app/o/apps%2Fgoogle-services.json?alt=media&token=55c6add4-asd8e2f-49asd8-80f0-b26b9f801bee"
#   export GOOGLE_SERVICE_INFO_PLIST_URL="https://firebasestorage.googleapis.com/v0/b/sigave-7dbf5.firebasestorage.app/o/apps%2FGoogleService-Info.plist?alt=media&token=20ea2d3aasd-4916-45e9-a0fe-304fda2d9511"
#   ./setup_firebase.sh
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Arquivos
MAIN_DART="$PROJECT_ROOT/lib/main.dart"
FIREBASE_OPTIONS="$PROJECT_ROOT/lib/firebase_options.dart"
GOOGLE_SERVICES_JSON="$PROJECT_ROOT/android/app/google-services.json"
GOOGLE_SERVICE_INFO_PLIST="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
ANDROID_BUILD_GRADLE="$PROJECT_ROOT/android/build.gradle.kts"
ANDROID_APP_BUILD_GRADLE="$PROJECT_ROOT/android/app/build.gradle.kts"
ANDROID_SETTINGS_GRADLE="$PROJECT_ROOT/android/settings.gradle.kts"

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Função para verificar variáveis de ambiente
check_env_vars() {
    local missing_vars=()
    
    [[ -z "$GOOGLE_SERVICES_JSON_URL" ]] && missing_vars+=("GOOGLE_SERVICES_JSON_URL")
    [[ -z "$GOOGLE_SERVICE_INFO_PLIST_URL" ]] && missing_vars+=("GOOGLE_SERVICE_INFO_PLIST_URL")
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Variáveis de ambiente não encontradas:"
        for var in "${missing_vars[@]}"; do
            echo -e "  ${RED}✗${NC} $var"
        done
        echo ""
        log_info "Configure as variáveis de ambiente antes de executar este script."
        return 1
    fi
    
    log_success "Todas as variáveis de ambiente encontradas!"
    return 0
}

# Função para baixar arquivo
download_file() {
    local url="$1"
    local output="$2"
    local name="$3"
    
    log_info "Baixando $name..."
    
    if curl -fsSL "$url" -o "$output"; then
        log_success "$name baixado com sucesso!"
        return 0
    else
        log_error "Falha ao baixar $name de: $url"
        return 1
    fi
}

# Função para extrair valores do google-services.json
extract_android_config() {
    log_info "Extraindo configurações do Android..."
    
    if [[ ! -f "$GOOGLE_SERVICES_JSON" ]]; then
        log_error "Arquivo google-services.json não encontrado!"
        return 1
    fi
    
    # Extrai valores usando grep e sed (compatível com macOS)
    FIREBASE_ANDROID_PROJECT_ID=$(grep -o '"project_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$GOOGLE_SERVICES_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    FIREBASE_ANDROID_PROJECT_NUMBER=$(grep -o '"project_number"[[:space:]]*:[[:space:]]*"[^"]*"' "$GOOGLE_SERVICES_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    FIREBASE_ANDROID_APP_ID=$(grep -o '"mobilesdk_app_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$GOOGLE_SERVICES_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    FIREBASE_ANDROID_API_KEY=$(grep -o '"current_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$GOOGLE_SERVICES_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    FIREBASE_ANDROID_STORAGE_BUCKET=$(grep -o '"storage_bucket"[[:space:]]*:[[:space:]]*"[^"]*"' "$GOOGLE_SERVICES_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    
    # Messaging Sender ID é o mesmo que project_number
    FIREBASE_ANDROID_MESSAGING_SENDER_ID="$FIREBASE_ANDROID_PROJECT_NUMBER"
    
    if [[ -z "$FIREBASE_ANDROID_PROJECT_ID" ]] || [[ -z "$FIREBASE_ANDROID_APP_ID" ]]; then
        log_error "Não foi possível extrair as configurações do google-services.json"
        return 1
    fi
    
    log_success "Configurações do Android extraídas!"
    echo "  Project ID: $FIREBASE_ANDROID_PROJECT_ID"
    echo "  App ID: $FIREBASE_ANDROID_APP_ID"
    echo "  Messaging Sender ID: $FIREBASE_ANDROID_MESSAGING_SENDER_ID"
}

# Função para extrair valores do GoogleService-Info.plist
extract_ios_config() {
    log_info "Extraindo configurações do iOS..."
    
    if [[ ! -f "$GOOGLE_SERVICE_INFO_PLIST" ]]; then
        log_error "Arquivo GoogleService-Info.plist não encontrado!"
        return 1
    fi
    
    # Extrai valores do plist usando PlistBuddy (macOS) ou grep/sed
    if command -v /usr/libexec/PlistBuddy &> /dev/null; then
        FIREBASE_IOS_API_KEY=$(/usr/libexec/PlistBuddy -c "Print :API_KEY" "$GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || echo "")
        FIREBASE_IOS_APP_ID=$(/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" "$GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || echo "")
        FIREBASE_IOS_MESSAGING_SENDER_ID=$(/usr/libexec/PlistBuddy -c "Print :GCM_SENDER_ID" "$GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || echo "")
        FIREBASE_IOS_PROJECT_ID=$(/usr/libexec/PlistBuddy -c "Print :PROJECT_ID" "$GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || echo "")
        FIREBASE_IOS_STORAGE_BUCKET=$(/usr/libexec/PlistBuddy -c "Print :STORAGE_BUCKET" "$GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || echo "")
        FIREBASE_IOS_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$GOOGLE_SERVICE_INFO_PLIST" 2>/dev/null || echo "")
    else
        # Fallback usando grep/sed para Linux ou outros sistemas
        FIREBASE_IOS_API_KEY=$(grep -A1 ">API_KEY<" "$GOOGLE_SERVICE_INFO_PLIST" | grep "<string>" | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
        FIREBASE_IOS_APP_ID=$(grep -A1 ">GOOGLE_APP_ID<" "$GOOGLE_SERVICE_INFO_PLIST" | grep "<string>" | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
        FIREBASE_IOS_MESSAGING_SENDER_ID=$(grep -A1 ">GCM_SENDER_ID<" "$GOOGLE_SERVICE_INFO_PLIST" | grep "<string>" | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
        FIREBASE_IOS_PROJECT_ID=$(grep -A1 ">PROJECT_ID<" "$GOOGLE_SERVICE_INFO_PLIST" | grep "<string>" | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
        FIREBASE_IOS_STORAGE_BUCKET=$(grep -A1 ">STORAGE_BUCKET<" "$GOOGLE_SERVICE_INFO_PLIST" | grep "<string>" | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
        FIREBASE_IOS_BUNDLE_ID=$(grep -A1 ">BUNDLE_ID<" "$GOOGLE_SERVICE_INFO_PLIST" | grep "<string>" | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
    fi
    
    if [[ -z "$FIREBASE_IOS_PROJECT_ID" ]] || [[ -z "$FIREBASE_IOS_APP_ID" ]]; then
        log_error "Não foi possível extrair as configurações do GoogleService-Info.plist"
        return 1
    fi
    
    log_success "Configurações do iOS extraídas!"
    echo "  Project ID: $FIREBASE_IOS_PROJECT_ID"
    echo "  App ID: $FIREBASE_IOS_APP_ID"
    echo "  Bundle ID: $FIREBASE_IOS_BUNDLE_ID"
    echo "  Messaging Sender ID: $FIREBASE_IOS_MESSAGING_SENDER_ID"
}

# Função para criar o arquivo firebase_options.dart
create_firebase_options() {
    log_info "Criando arquivo firebase_options.dart..."
    
    # Valores opcionais com fallback
    local android_storage="${FIREBASE_ANDROID_STORAGE_BUCKET:-${FIREBASE_ANDROID_PROJECT_ID}.appspot.com}"
    local ios_storage="${FIREBASE_IOS_STORAGE_BUCKET:-${FIREBASE_IOS_PROJECT_ID}.appspot.com}"
    
    cat > "$FIREBASE_OPTIONS" << EOF
// File generated by setup_firebase.sh script
// Do not edit manually

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$FIREBASE_ANDROID_API_KEY',
    appId: '$FIREBASE_ANDROID_APP_ID',
    messagingSenderId: '$FIREBASE_ANDROID_MESSAGING_SENDER_ID',
    projectId: '$FIREBASE_ANDROID_PROJECT_ID',
    storageBucket: '$android_storage',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '$FIREBASE_IOS_API_KEY',
    appId: '$FIREBASE_IOS_APP_ID',
    messagingSenderId: '$FIREBASE_IOS_MESSAGING_SENDER_ID',
    projectId: '$FIREBASE_IOS_PROJECT_ID',
    storageBucket: '$ios_storage',
    iosBundleId: '$FIREBASE_IOS_BUNDLE_ID',
  );
}
EOF

    log_success "Arquivo firebase_options.dart criado!"
}

# Função para configurar o Gradle do Android
configure_android_gradle() {
    log_info "Configurando Gradle do Android para Firebase..."
    
    # Adicionar plugin do Google Services ao settings.gradle.kts
    if ! grep -q "com.google.gms.google-services" "$ANDROID_SETTINGS_GRADLE"; then
        log_info "Adicionando plugin Google Services ao settings.gradle.kts..."
        
        # Adiciona o plugin na seção de plugins
        sed -i '' 's/id("org.jetbrains.kotlin.android") version "[^"]*" apply false/id("org.jetbrains.kotlin.android") version "2.1.0" apply false\n    id("com.google.gms.google-services") version "4.4.2" apply false/' "$ANDROID_SETTINGS_GRADLE"
        
        log_success "Plugin adicionado ao settings.gradle.kts"
    else
        log_warning "Plugin Google Services já existe no settings.gradle.kts"
    fi
    
    # Adicionar plugin ao app/build.gradle.kts
    if ! grep -q "com.google.gms.google-services" "$ANDROID_APP_BUILD_GRADLE"; then
        log_info "Adicionando plugin Google Services ao app/build.gradle.kts..."
        
        # Adiciona o plugin após o flutter plugin
        sed -i '' 's/id("dev.flutter.flutter-gradle-plugin")/id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")/' "$ANDROID_APP_BUILD_GRADLE"
        
        log_success "Plugin adicionado ao app/build.gradle.kts"
    else
        log_warning "Plugin Google Services já existe no app/build.gradle.kts"
    fi
    
    # Verificar e ajustar minSdk se necessário (Firebase requer minSdk 21+)
    if grep -q "minSdk = flutter.minSdkVersion" "$ANDROID_APP_BUILD_GRADLE"; then
        log_info "Ajustando minSdk para 21 (requisito do Firebase)..."
        sed -i '' 's/minSdk = flutter.minSdkVersion/minSdk = Math.max(flutter.minSdkVersion, 21)/' "$ANDROID_APP_BUILD_GRADLE"
        log_success "minSdk ajustado"
    fi
    
    log_success "Gradle do Android configurado!"
}

# Função para atualizar o main.dart
update_main_dart() {
    log_info "Atualizando main.dart com Firebase..."
    
    # Verificar se já tem Firebase configurado
    if grep -q "firebase_core" "$MAIN_DART"; then
        log_warning "Firebase já está configurado no main.dart"
        return 0
    fi
    
    # Criar novo main.dart com Firebase
    cat > "$MAIN_DART" << 'EOF'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';

// Handler para mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Mensagem recebida em background: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "envs/.env.prod");
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configura o handler de mensagens em background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Inicializa o Firebase Messaging
  await _initFirebaseMessaging();
  
  runApp(const MyApp());
}

Future<void> _initFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;
  
  // Solicita permissão para notificações
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  print('Permissão de notificação: ${settings.authorizationStatus}');
  
  // Obtém o token FCM (com tratamento para iOS APNS)
  String? token;
  try {
    // No iOS, é necessário obter o APNS token antes do FCM token
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) {
        print('APNS Token: $apnsToken');
      }
    }
    token = await messaging.getToken();
    print('FCM Token: $token');
  } catch (e) {
    print('Erro ao obter token: $e');
    // Em caso de erro, tenta novamente após um delay (útil para iOS)
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        token = await messaging.getToken();
        print('FCM Token (retry): $token');
      } catch (e) {
        print('Erro ao obter token (retry): $e');
      }
    });
  }
  
  // Listener para quando o token é atualizado
  messaging.onTokenRefresh.listen((newToken) {
    print('FCM Token atualizado: $newToken');
  });
  
  // Listener para mensagens em foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensagem recebida em foreground: ${message.notification?.title}');
  });
  
  // Listener para quando o usuário clica na notificação
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notificação clicada: ${message.notification?.title}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
EOF

    log_success "main.dart atualizado com Firebase Messaging!"
}

# Função para exibir ajuda
show_help() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo "  Setup Firebase - Flutter App"
    echo -e "==========================================${NC}"
    echo ""
    echo "Uso: $0"
    echo ""
    echo "Este script configura o Firebase no projeto Flutter baixando os arquivos"
    echo "de configuração e gerando o firebase_options.dart automaticamente."
    echo ""
    echo -e "${YELLOW}Variáveis de ambiente necessárias:${NC}"
    echo ""
    echo "  GOOGLE_SERVICES_JSON_URL      - URL do arquivo google-services.json (Android)"
    echo "  GOOGLE_SERVICE_INFO_PLIST_URL - URL do arquivo GoogleService-Info.plist (iOS)"
    echo ""
    echo -e "${YELLOW}Exemplo:${NC}"
    echo "  export GOOGLE_SERVICES_JSON_URL='https://storage.com/google-services.json'"
    echo "  export GOOGLE_SERVICE_INFO_PLIST_URL='https://storage.com/GoogleService-Info.plist'"
    echo "  $0"
    echo ""
    echo -e "${YELLOW}O script irá:${NC}"
    echo "  1. Baixar google-services.json para android/app/"
    echo "  2. Baixar GoogleService-Info.plist para ios/Runner/"
    echo "  3. Extrair as configurações dos arquivos"
    echo "  4. Gerar lib/firebase_options.dart"
    echo "  5. Atualizar lib/main.dart com Firebase Messaging"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${CYAN}=========================================="
echo "  Setup Firebase - Flutter App"
echo -e "==========================================${NC}"
echo ""

# Verificar argumentos
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Verificar variáveis de ambiente
if ! check_env_vars; then
    echo ""
    show_help
    exit 1
fi

echo ""

# Baixar arquivos de configuração
download_file "$GOOGLE_SERVICES_JSON_URL" "$GOOGLE_SERVICES_JSON" "google-services.json"
download_file "$GOOGLE_SERVICE_INFO_PLIST_URL" "$GOOGLE_SERVICE_INFO_PLIST" "GoogleService-Info.plist"

echo ""

# Extrair configurações
extract_android_config
echo ""
extract_ios_config

echo ""

# Configurar Gradle do Android
configure_android_gradle

echo ""

# Criar firebase_options.dart
create_firebase_options

# Atualizar main.dart
update_main_dart

echo ""
log_success "Firebase configurado com sucesso!"
echo ""
echo -e "${YELLOW}Arquivos criados/atualizados:${NC}"
echo "  ✓ android/app/google-services.json"
echo "  ✓ android/settings.gradle.kts (plugin Google Services)"
echo "  ✓ android/app/build.gradle.kts (plugin Google Services)"
echo "  ✓ ios/Runner/GoogleService-Info.plist"
echo "  ✓ lib/firebase_options.dart"
echo "  ✓ lib/main.dart"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "  1. Execute 'flutter pub get'"
echo "  2. Para iOS, execute 'cd ios && pod install'"
echo ""
