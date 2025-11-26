#!/bin/bash

# Script para baixar o ícone definido na variável de ambiente ICON_LINK
# Uso: ICON_LINK="https://exemplo.com/icon.png" ./download_icon.sh

ASSETS_DIR="assets"
ICON_PATH="$ASSETS_DIR/icon.png"

# Função para verificar se a variável ICON_LINK está definida
check_icon_link() {
    if [ -z "$ICON_LINK" ]; then
        echo "❌ Erro: A variável de ambiente ICON_LINK não está definida!"
        echo "   Uso: ICON_LINK=\"https://exemplo.com/icon.png\" ./download_icon.sh"
        exit 1
    fi
    echo "✅ Variável ICON_LINK definida: $ICON_LINK"
}

# Função para criar a pasta assets se não existir
create_assets_dir() {
    if [ ! -d "$ASSETS_DIR" ]; then
        mkdir -p "$ASSETS_DIR"
        echo "📁 Pasta $ASSETS_DIR criada."
    else
        echo "📁 Pasta $ASSETS_DIR já existe."
    fi
}

# Função para baixar o ícone
download_icon() {
    echo "⬇️  Baixando ícone de $ICON_LINK para $ICON_PATH ..."
    curl -fsSL "$ICON_LINK" -o "$ICON_PATH"
    if [ $? -eq 0 ]; then
        echo "✅ Ícone baixado com sucesso em $ICON_PATH!"
    else
        echo "❌ Erro ao baixar o ícone. Verifique o link e tente novamente."
        exit 1
    fi
}

# Função principal
main() {
    echo "🚀 Iniciando download do ícone..."
    echo ""
    check_icon_link
    create_assets_dir
    download_icon
    echo ""
    echo "✨ Processo concluído!"
}

main
