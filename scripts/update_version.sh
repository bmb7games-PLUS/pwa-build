#!/bin/bash

# =============================================================================
# Script para alterar a versão e build number no pubspec.yaml
# =============================================================================
# Uso: ./update_version.sh <versão> <build_number>
#
# Parâmetros:
#   versão        Versão da aplicação (ex: 1.2.3)
#   build_number  Número do build (ex: 10) - opcional, usa BUILD_NUMBER_INCREMENT do Codemagic se não informado
#
# Exemplos:
#   ./update_version.sh 2.0.0 100
#   ./update_version.sh 1.5.0              # Usa BUILD_NUMBER_INCREMENT do Codemagic
#   ./update_version.sh 1.5.0 $BUILD_NUMBER_INCREMENT
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
PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"

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
    echo "  Atualizar Versão - Flutter App"
    echo -e "==========================================${NC}"
    echo ""
    echo "Uso: $0 <versão> [build_number]"
    echo ""
    echo "Parâmetros:"
    echo "  versão        Versão da aplicação (ex: 1.2.3)"
    echo "  build_number  Número do build (ex: 10) - opcional"
    echo ""
    echo "Se build_number não for informado, usa a variável BUILD_NUMBER_INCREMENT do Codemagic."
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  $0 2.0.0 100"
    echo "  $0 1.5.0"
    echo "  $0 1.5.0 \$BUILD_NUMBER_INCREMENT"
    echo ""
}

# Função para obter a versão atual do pubspec.yaml
get_current_version() {
    if [[ ! -f "$PUBSPEC_FILE" ]]; then
        log_error "Arquivo pubspec.yaml não encontrado em: $PUBSPEC_FILE"
        exit 1
    fi
    
    local version_line=$(grep "^version:" "$PUBSPEC_FILE")
    echo "$version_line" | sed 's/version: //'
}

# Função para validar formato da versão
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Formato de versão inválido: $version"
        log_info "Use o formato semântico: MAJOR.MINOR.PATCH (ex: 1.2.3)"
        exit 1
    fi
}

# Função para validar build number
validate_build() {
    local build="$1"
    if [[ ! "$build" =~ ^[0-9]+$ ]]; then
        log_error "Build number inválido: $build"
        log_info "O build number deve ser um número inteiro positivo"
        exit 1
    fi
}

# Função para atualizar o pubspec.yaml
update_pubspec() {
    local new_full_version="$1"
    
    # Atualiza a versão no pubspec.yaml
    sed -i '' "s/^version: .*/version: $new_full_version/" "$PUBSPEC_FILE"
    
    log_success "pubspec.yaml atualizado para versão: $new_full_version"
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${CYAN}=========================================="
echo "  Atualizar Versão - Flutter App"
echo -e "==========================================${NC}"
echo ""

# Verificar se foi passado pelo menos 1 argumento (versão)
if [[ -z "$1" ]]; then
    show_help
    exit 1
fi

NEW_VERSION="$1"
NEW_BUILD="$2"

# Validar versão
validate_version "$NEW_VERSION"

# Se build não foi informado, tenta usar BUILD_NUMBER_INCREMENT do Codemagic
if [[ -z "$NEW_BUILD" ]]; then
    if [[ -n "$BUILD_NUMBER_INCREMENT" ]]; then
        NEW_BUILD="$BUILD_NUMBER_INCREMENT"
        log_info "Usando BUILD_NUMBER_INCREMENT do Codemagic: $NEW_BUILD"
    else
        # Extrai o build number atual do pubspec.yaml
        CURRENT_VERSION=$(get_current_version)
        NEW_BUILD=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
        log_warning "BUILD_NUMBER_INCREMENT não encontrado, mantendo build atual: $NEW_BUILD"
    fi
fi

# Validar build number
validate_build "$NEW_BUILD"

# Verificar se o pubspec.yaml existe
if [[ ! -f "$PUBSPEC_FILE" ]]; then
    log_error "Arquivo pubspec.yaml não encontrado!"
    exit 1
fi

# Obter versão atual
CURRENT_VERSION=$(get_current_version)
log_info "Versão atual: $CURRENT_VERSION"

# Construir nova versão
NEW_FULL_VERSION="$NEW_VERSION+$NEW_BUILD"

# Verificar se há alterações
if [[ "$NEW_FULL_VERSION" == "$CURRENT_VERSION" ]]; then
    log_warning "Nenhuma alteração necessária. Versão já está em: $CURRENT_VERSION"
    exit 0
fi

# Exibir informações
echo ""
echo -e "  Versão atual:  ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "  Nova versão:   ${GREEN}$NEW_FULL_VERSION${NC}"
echo ""

# Atualizar pubspec.yaml
update_pubspec "$NEW_FULL_VERSION"

echo ""
log_success "Versão atualizada com sucesso!"
echo ""
