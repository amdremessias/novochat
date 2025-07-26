#!/bin/bash

# --- Cores para melhor visualização ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Início da Configuração do Nginx como Proxy Reverso (Local/Autoassinado) para Chatwoot ---${NC}"

# --- Valores pré-definidos com base nas suas informações ---
DEFAULT_DOMAIN_OR_IP="host.novochat.internal"
DEFAULT_NGINX_HTTP_PORT="80"
DEFAULT_NGINX_HTTPS_PORT="443"
DEFAULT_CHATWOOT_RAILS_PORT="3000"
DEFAULT_CHATWOOT_INTERNAL_HOST="rails" # 'rails' é o nome do serviço no docker-compose e é resolvível internamente

# --- Solicitar variáveis para a configuração do Nginx ---
echo -e "${YELLOW}\nPor favor, confirme ou altere as seguintes informações para configurar o Nginx:${NC}"

read -p "1. Qual o nome de domínio (ou IP) que você usará para acessar o Chatwoot publicamente? (Padrão: ${DEFAULT_DOMAIN_OR_IP}): " DOMAIN_OR_IP
DOMAIN_OR_IP=${DOMAIN_OR_IP:-$DEFAULT_DOMAIN_OR_IP} # Define o padrão se vazio

read -p "2. Qual a porta que o Nginx usará para ouvir as requisições HTTP? (Padrão: ${DEFAULT_NGINX_HTTP_PORT}): " NGINX_HTTP_PORT
NGINX_HTTP_PORT=${NGINX_HTTP_PORT:-$DEFAULT_NGINX_HTTP_PORT} # Define o padrão se vazio

read -p "3. Qual a porta que o Nginx usará para ouvir as requisições HTTPS? (Padrão: ${DEFAULT_NGINX_HTTPS_PORT}): " NGINX_HTTPS_PORT
NGINX_HTTPS_PORT=${NGINX_HTTPS_PORT:-$DEFAULT_NGINX_HTTPS_PORT} # Define o padrão se vazio

read -p "4. Qual a porta interna do serviço Rails do Chatwoot no Docker Compose? (Padrão: ${DEFAULT_CHATWOOT_RAILS_PORT}): " CHATWOOT_RAILS_PORT
CHATWOOT_RAILS_PORT=${CHATWOOT_RAILS_PORT:-$DEFAULT_CHATWOOT_RAILS_PORT} # Define o padrão se vazio

read -p "5. Confirme o IP interno do Docker ou o nome do serviço 'rails' para o Nginx direcionar (Padrão: ${DEFAULT_CHATWOOT_INTERNAL_HOST}): " CHATWOOT_INTERNAL_HOST
CHATWOOT_INTERNAL_HOST=${CHATWOOT_INTERNAL_HOST:-$DEFAULT_CHATWOOT_INTERNAL_HOST} # Define o padrão se vazio

# --- Instalação do Nginx e OpenSSL ---
echo -e "${YELLOW}\nAtualizando a lista de pacotes e instalando Nginx e OpenSSL...${NC}"
sudo apt update
if ! sudo apt install -y nginx openssl; then
    echo -e "${RED}Erro: Falha ao instalar Nginx e/ou OpenSSL. Verifique seu gerenciador de pacotes.${NC}"
    exit 1
fi
echo -e "${GREEN}Nginx e OpenSSL instalados com sucesso!${NC}"

# --- Geração de Certificado SSL Autoassinado ---
echo -e "${YELLOW}\nGerando certificado SSL autoassinado para ${DOMAIN_OR_IP}...${NC}"

CERT_DIR="/etc/nginx/ssl"
KEY_PATH="${CERT_DIR}/${DOMAIN_OR_IP}.key"
CERT_PATH="${CERT_DIR}/${DOMAIN_OR_IP}.crt"

# Cria o diretório para os certificados se não existir
sudo mkdir -p "$CERT_DIR"

# Gera a chave privada e o certificado autoassinado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CERT_PATH" \
    -subj "/C=BR/ST=SaoPaulo/L=Ourinhos/O=LocalHost/CN=${DOMAIN_OR_IP}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro: Falha ao gerar certificado SSL autoassinado.${NC}"
    exit 1
fi
echo -e "${GREEN}Certificado autoassinado gerado com sucesso em ${CERT_PATH}!${NC}"
echo -e "${YELLOW}Lembre-se de importar este certificado para o seu navegador para evitar avisos de segurança.${NC}"

# --- Configuração do Proxy Reverso ---
echo -e "${YELLOW}\nGerando arquivo de configuração do Nginx...${NC}"

# Define o caminho do arquivo de configuração
NGINX_CONF_FILE="/etc/nginx/sites-available/$DOMAIN_OR_IP.conf"
NGINX_SYMLINK_FILE="/etc/nginx/sites-enabled/$DOMAIN_OR_IP.conf"

# Conteúdo da configuração do Nginx com HTTP e HTTPS (autoassinado)
NGINX_CONFIG_CONTENT="
server {
    listen ${NGINX_HTTP_PORT};
    server_name ${DOMAIN_OR_IP};
    return 301 https://\$host\$request_uri; # Redireciona HTTP para HTTPS
}

server {
    listen ${NGINX_HTTPS_PORT} ssl http2;
    server_name ${DOMAIN_OR_IP};

    ssl_certificate ${CERT_PATH};
    ssl_certificate_key ${KEY_PATH};

    # Configurações SSL comuns para segurança
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-CHACHA20-POLY1305';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s; # Exemplo, use seus próprios resolvers DNS (ou o DNS do seu router local)
    resolver_timeout 5s;
    add_header Strict-Transport-Security \"max-age=63072000\" always;

    location / {
        proxy_pass http://${CHATWOOT_INTERNAL_HOST}:${CHATWOOT_RAILS_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https; # Garante que a aplicação saiba que é HTTPS
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        send_timeout 300; # Aumenta o tempo limite para uploads grandes ou processamento de jobs
    }
}
"

echo "$NGINX_CONFIG_CONTENT" | sudo tee "$NGINX_CONF_FILE" > /dev/null

# Cria o symlink para habilitar a configuração
echo -e "${YELLOW}Habilitando a configuração do Nginx...${NC}"
sudo ln -sf "$NGINX_CONF_FILE" "$NGINX_SYMLINK_FILE"

# Remove a configuração padrão do Nginx se existir
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    echo -e "${YELLOW}Removendo configuração padrão do Nginx...${NC}"
    sudo rm /etc/nginx/sites-enabled/default
fi

# Testa a configuração do Nginx
echo -e "${YELLOW}Testando a configuração do Nginx...${NC}"
if ! sudo nginx -t; then
    echo -e "${RED}Erro: A configuração do Nginx possui erros. Verifique o arquivo $NGINX_CONF_FILE.${NC}"
    exit 1
fi
echo -e "${GREEN}Configuração do Nginx testada com sucesso!${NC}"

# Reinicia o Nginx
echo -e "${YELLOW}Reiniciando o serviço Nginx...${NC}"
sudo systemctl restart nginx
sudo systemctl enable nginx
echo -e "${GREEN}Nginx reiniciado e habilitado para iniciar com o sistema.${NC}"

echo -e "${GREEN}\n--- Configuração Nginx e Chatwoot Concluída! ---${NC}"
echo -e "${GREEN}Seu Chatwoot deve estar acessível via: http://${DOMAIN_OR_IP}:${NGINX_HTTP_PORT}${NC}"
echo -e "${GREEN}E também via: https://${DOMAIN_OR_IP}:${NGINX_HTTPS_PORT}${NC}"
echo -e "${YELLOW}Lembre-se de que '${DOMAIN_OR_IP}' (${DEFAULT_DOMAIN_OR_IP}) deve resolver para o IP do seu servidor (${DOMAIN_OR_IP_ACTUAL}) onde o Nginx está rodando.${NC}"
echo -e "${YELLOW}Para evitar avisos de segurança no navegador ao acessar HTTPS, você precisará importar o arquivo de certificado: ${CERT_PATH}${NC}"
echo -e "${YELLOW}Verifique o status do Nginx com: sudo systemctl status nginx${NC}"
