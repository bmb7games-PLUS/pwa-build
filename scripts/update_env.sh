#!/bin/bash

# Script para atualizar variáveis de ambiente no arquivo .env.prod
# Uso: HOST_URL="https://exemplo.com" ./update_env.sh

ENV_FILE="envs/.env.prod"

# Função para verificar se o arquivo .env.prod existe
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        echo "❌ Erro: Arquivo $ENV_FILE não encontrado!"
        exit 1
    fi
    echo "✅ Arquivo $ENV_FILE encontrado."
}

# Função para atualizar a variável HOST_URL no arquivo .env.prod
update_host_url() {
    if [ -z "$HOST_URL" ]; then
        echo "❌ Erro: A variável de ambiente HOST_URL não está definida!"
        echo "   Uso: HOST_URL=\"https://exemplo.com\" ./update_env.sh"
        exit 1
    fi

    echo "🔄 Atualizando HOST_URL para: $HOST_URL"

    # Verifica se a variável HOST_URL já existe no arquivo
    if grep -q "^HOST_URL=" "$ENV_FILE"; then
        # Substitui o valor existente
        sed -i '' "s|^HOST_URL=.*|HOST_URL='$HOST_URL'|" "$ENV_FILE"
        echo "✅ HOST_URL atualizado com sucesso!"
    else
        # Adiciona a variável se não existir
        echo "HOST_URL='$HOST_URL'" >> "$ENV_FILE"
        echo "✅ HOST_URL adicionado ao arquivo!"
    fi
}

# Função para exibir o conteúdo atual do arquivo .env.prod
show_env_content() {
    echo "📄 Conteúdo atual do $ENV_FILE:"
    echo "----------------------------------------"
    cat "$ENV_FILE"
    echo "----------------------------------------"
}

# Função principal
main() {
    echo "🚀 Iniciando atualização do ambiente..."
    echo ""
    
    check_env_file
    update_host_url
    
    echo ""
    show_env_content
    
    echo ""
    echo "✨ Processo concluído!"
}

# Executa a função principal
main
