#!/bin/bash

# =============================================================================
# Script para alterar o nome do aplicativo em Android, iOS e macOS
# =============================================================================
# Uso: ./change_app_name.sh <nome_do_app>
#
# Parâmetros:
#   nome_do_app   Nome do aplicativo (ex: "Meu App" ou "MeuApp")
#
# Exemplos:
#   ./change_app_name.sh "Meu Aplicativo"
#   ./change_app_name.sh MeuApp
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
ANDROID_MANIFEST="$PROJECT_ROOT/android/app/src/main/AndroidManifest.xml"
IOS_INFO_PLIST="$PROJECT_ROOT/ios/Runner/Info.plist"
MACOS_APP_INFO="$PROJECT_ROOT/macos/Runner/Configs/AppInfo.xcconfig"

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

# Função para exibir ajuda
show_help() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo "  Alterar Nome do Aplicativo"
    echo -e "==========================================${NC}"
    echo ""
    echo "Uso: $0 <nome_do_app>"
    echo ""
    echo "Parâmetros:"
    echo "  nome_do_app   Nome do aplicativo (ex: \"Meu App\")"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  $0 \"Meu Aplicativo\""
    echo "  $0 MeuApp"
    echo ""
    echo "Este script altera o nome do app em:"
    echo "  - Android: AndroidManifest.xml (android:label)"
    echo "  - iOS: Info.plist (CFBundleDisplayName e CFBundleName)"
    echo "  - macOS: AppInfo.xcconfig (PRODUCT_NAME)"
    echo ""
}

# Função para exibir nomes atuais
show_current_names() {
    echo ""
    log_info "Nomes atuais:"
    
    # Android
    if [[ -f "$ANDROID_MANIFEST" ]]; then
        local android_name=$(grep -o 'android:label="[^"]*"' "$ANDROID_MANIFEST" | head -1 | sed 's/android:label="\([^"]*\)"/\1/')
        echo -e "  ${BLUE}Android:${NC} $android_name"
    fi
    
    # iOS
    if [[ -f "$IOS_INFO_PLIST" ]]; then
        local ios_display_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$IOS_INFO_PLIST" 2>/dev/null || echo "N/A")
        local ios_bundle_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$IOS_INFO_PLIST" 2>/dev/null || echo "N/A")
        echo -e "  ${BLUE}iOS (Display):${NC} $ios_display_name"
        echo -e "  ${BLUE}iOS (Bundle):${NC} $ios_bundle_name"
    fi
    
    # macOS
    if [[ -f "$MACOS_APP_INFO" ]]; then
        local macos_name=$(grep "^PRODUCT_NAME" "$MACOS_APP_INFO" | sed 's/PRODUCT_NAME = //')
        echo -e "  ${BLUE}macOS:${NC} $macos_name"
    fi
    
    echo ""
}

# Função para alterar nome no Android
change_android_name() {
    local new_name="$1"
    
    log_info "Alterando nome no Android..."
    
    if [[ -f "$ANDROID_MANIFEST" ]]; then
        # Escapa caracteres especiais para sed
        local escaped_name=$(echo "$new_name" | sed 's/[&/\]/\\&/g')
        sed -i '' "s/android:label=\"[^\"]*\"/android:label=\"$escaped_name\"/" "$ANDROID_MANIFEST"
        log_success "AndroidManifest.xml atualizado"
    else
        log_warning "Arquivo AndroidManifest.xml não encontrado"
    fi
}

# Função para alterar nome no iOS
change_ios_name() {
    local new_name="$1"
    
    log_info "Alterando nome no iOS..."
    
    if [[ -f "$IOS_INFO_PLIST" ]]; then
        # Altera CFBundleDisplayName (nome exibido na home)
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$new_name'" "$IOS_INFO_PLIST" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$new_name'" "$IOS_INFO_PLIST"
        
        # Altera CFBundleName (nome interno)
        /usr/libexec/PlistBuddy -c "Set :CFBundleName '$new_name'" "$IOS_INFO_PLIST"
        
        log_success "Info.plist (iOS) atualizado"
    else
        log_warning "Arquivo Info.plist (iOS) não encontrado"
    fi
}

# Função para alterar nome no macOS
change_macos_name() {
    local new_name="$1"
    
    log_info "Alterando nome no macOS..."
    
    if [[ -f "$MACOS_APP_INFO" ]]; then
        sed -i '' "s/^PRODUCT_NAME = .*/PRODUCT_NAME = $new_name/" "$MACOS_APP_INFO"
        log_success "AppInfo.xcconfig (macOS) atualizado"
    else
        log_warning "Arquivo AppInfo.xcconfig não encontrado"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${CYAN}=========================================="
echo "  Alterar Nome do Aplicativo"
echo -e "==========================================${NC}"

# Verificar se foi passado argumento
if [[ -z "$1" ]]; then
    show_current_names
    show_help
    exit 1
fi

NEW_APP_NAME="$1"

log_info "Novo nome do app: $NEW_APP_NAME"

# Mostrar nomes atuais
show_current_names

# Executar alterações
change_android_name "$NEW_APP_NAME"
change_ios_name "$NEW_APP_NAME"
change_macos_name "$NEW_APP_NAME"

echo ""
log_success "Nome do aplicativo alterado com sucesso!"

# Mostrar novos nomes
show_current_names

log_warning "Lembre-se de:"
echo "  1. Executar 'flutter clean' antes de compilar novamente"
echo "  2. Para iOS, execute 'cd ios && pod install'"
echo ""
