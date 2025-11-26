#!/bin/bash

# =============================================================================
# Script para alterar a versão e build number no pubspec.yaml
# =============================================================================
# Uso: ./update_version.sh [opções]
#
# Opções:
#   -v, --version <versão>     Define a versão (ex: 1.2.3)
#   -b, --build <número>       Define o build number manualmente
#   --use-codemagic            Usa a variável BUILD_NUMBER do Codemagic
#   --bump-major               Incrementa a versão major (x.0.0)
#   --bump-minor               Incrementa a versão minor (0.x.0)
#   --bump-patch               Incrementa a versão patch (0.0.x)
#   --bump-build               Incrementa o build number
#   -h, --help                 Exibe esta ajuda
#
# Variáveis do Codemagic suportadas:
#   - BUILD_NUMBER_INCREMENT: Número do build auto-incrementado pelo Codemagic
#
# Exemplos:
#   ./update_version.sh -v 2.0.0 --use-codemagic
#   ./update_version.sh --bump-patch --use-codemagic
#   ./update_version.sh -v 1.5.0 -b 100
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

# Variáveis
NEW_VERSION=""
NEW_BUILD=""
USE_CODEMAGIC=false
BUMP_MAJOR=false
BUMP_MINOR=false
BUMP_PATCH=false
BUMP_BUILD=false

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
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -v, --version <versão>     Define a versão (ex: 1.2.3)"
    echo "  -b, --build <número>       Define o build number manualmente"
    echo "  --use-codemagic            Usa a variável BUILD_NUMBER do Codemagic"
    echo "  --bump-major               Incrementa a versão major (x.0.0)"
    echo "  --bump-minor               Incrementa a versão minor (0.x.0)"
    echo "  --bump-patch               Incrementa a versão patch (0.0.x)"
    echo "  --bump-build               Incrementa o build number"
    echo "  -h, --help                 Exibe esta ajuda"
    echo ""
    echo -e "${YELLOW}Variáveis do Codemagic suportadas:${NC}"
    echo "  - BUILD_NUMBER_INCREMENT: Número do build auto-incrementado pelo Codemagic"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  $0 -v 2.0.0 --use-codemagic"
    echo "  $0 --bump-patch --use-codemagic"
    echo "  $0 -v 1.5.0 -b 100"
    echo "  $0 --bump-minor --bump-build"
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

# Função para extrair partes da versão
parse_version() {
    local full_version="$1"
    
    # Separa versão do build number
    VERSION_PART=$(echo "$full_version" | cut -d'+' -f1)
    BUILD_PART=$(echo "$full_version" | cut -d'+' -f2)
    
    # Separa major, minor, patch
    MAJOR=$(echo "$VERSION_PART" | cut -d'.' -f1)
    MINOR=$(echo "$VERSION_PART" | cut -d'.' -f2)
    PATCH=$(echo "$VERSION_PART" | cut -d'.' -f3)
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

# Função para obter build number do Codemagic
get_codemagic_build_number() {
    # Codemagic define BUILD_NUMBER_INCREMENT
    if [[ -n "$BUILD_NUMBER_INCREMENT" ]]; then
        echo "$BUILD_NUMBER_INCREMENT"
    else
        log_warning "Variável BUILD_NUMBER_INCREMENT do Codemagic não encontrada"
        log_info "Usando build number atual do pubspec.yaml"
        echo ""
    fi
}

# Função para atualizar o pubspec.yaml
update_pubspec() {
    local new_full_version="$1"
    
    # Faz backup do arquivo original
    cp "$PUBSPEC_FILE" "$PUBSPEC_FILE.bak"
    
    # Atualiza a versão no pubspec.yaml
    sed -i '' "s/^version: .*/version: $new_full_version/" "$PUBSPEC_FILE"
    
    # Remove backup se tudo correu bem
    rm "$PUBSPEC_FILE.bak"
    
    log_success "pubspec.yaml atualizado para versão: $new_full_version"
}

# Função para exibir informações da versão
show_version_info() {
    local current="$1"
    local new="$2"
    
    echo ""
    echo -e "${CYAN}Informações de Versão:${NC}"
    echo -e "  Versão atual:  ${YELLOW}$current${NC}"
    echo -e "  Nova versão:   ${GREEN}$new${NC}"
    echo ""
}

# =============================================================================
# Processamento de argumentos
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            NEW_VERSION="$2"
            shift 2
            ;;
        -b|--build)
            NEW_BUILD="$2"
            shift 2
            ;;
        --use-codemagic)
            USE_CODEMAGIC=true
            shift
            ;;
        --bump-major)
            BUMP_MAJOR=true
            shift
            ;;
        --bump-minor)
            BUMP_MINOR=true
            shift
            ;;
        --bump-patch)
            BUMP_PATCH=true
            shift
            ;;
        --bump-build)
            BUMP_BUILD=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${CYAN}=========================================="
echo "  Atualizar Versão - Flutter App"
echo -e "==========================================${NC}"
echo ""

# Verificar se o pubspec.yaml existe
if [[ ! -f "$PUBSPEC_FILE" ]]; then
    log_error "Arquivo pubspec.yaml não encontrado!"
    exit 1
fi

# Obter versão atual
CURRENT_FULL_VERSION=$(get_current_version)
parse_version "$CURRENT_FULL_VERSION"

log_info "Versão atual: $CURRENT_FULL_VERSION"
log_info "  Major: $MAJOR, Minor: $MINOR, Patch: $PATCH, Build: $BUILD_PART"
echo ""

# Detectar ambiente Codemagic
if [[ -n "$CI" ]] && [[ -n "$FCI_BUILD_ID" ]]; then
    log_info "Ambiente Codemagic detectado"
    log_info "  FCI_BUILD_ID: $FCI_BUILD_ID"
    [[ -n "$BUILD_NUMBER_INCREMENT" ]] && log_info "  BUILD_NUMBER_INCREMENT: $BUILD_NUMBER_INCREMENT"
    echo ""
fi

# Processar bumps de versão
if [[ "$BUMP_MAJOR" == true ]]; then
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    log_info "Incrementando versão major"
fi

if [[ "$BUMP_MINOR" == true ]]; then
    MINOR=$((MINOR + 1))
    PATCH=0
    log_info "Incrementando versão minor"
fi

if [[ "$BUMP_PATCH" == true ]]; then
    PATCH=$((PATCH + 1))
    log_info "Incrementando versão patch"
fi

# Definir nova versão (se especificada via argumento)
if [[ -n "$NEW_VERSION" ]]; then
    validate_version "$NEW_VERSION"
    FINAL_VERSION="$NEW_VERSION"
else
    FINAL_VERSION="$MAJOR.$MINOR.$PATCH"
fi

# Definir novo build number
if [[ "$USE_CODEMAGIC" == true ]]; then
    CODEMAGIC_BUILD=$(get_codemagic_build_number)
    if [[ -n "$CODEMAGIC_BUILD" ]]; then
        FINAL_BUILD="$CODEMAGIC_BUILD"
        log_info "Usando BUILD_NUMBER do Codemagic: $FINAL_BUILD"
    else
        FINAL_BUILD="$BUILD_PART"
    fi
elif [[ -n "$NEW_BUILD" ]]; then
    validate_build "$NEW_BUILD"
    FINAL_BUILD="$NEW_BUILD"
elif [[ "$BUMP_BUILD" == true ]]; then
    FINAL_BUILD=$((BUILD_PART + 1))
    log_info "Incrementando build number"
else
    FINAL_BUILD="$BUILD_PART"
fi

# Construir versão final
FINAL_FULL_VERSION="$FINAL_VERSION+$FINAL_BUILD"

# Verificar se há alterações
if [[ "$FINAL_FULL_VERSION" == "$CURRENT_FULL_VERSION" ]]; then
    log_warning "Nenhuma alteração necessária. Versão já está em: $CURRENT_FULL_VERSION"
    exit 0
fi

# Exibir informações
show_version_info "$CURRENT_FULL_VERSION" "$FINAL_FULL_VERSION"

# Atualizar pubspec.yaml
update_pubspec "$FINAL_FULL_VERSION"

echo ""
log_success "Versão atualizada com sucesso!"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "  1. Verifique as alterações: git diff pubspec.yaml"
echo "  2. Commit as alterações: git add pubspec.yaml && git commit -m 'bump: $FINAL_FULL_VERSION'"
echo ""
