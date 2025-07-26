🚀 NovoChat Automação

Autor: André Luiz Messias
Data: Ourinhos, 26 de julho de 2025

Este repositório fornece uma configuração automatizada e pré-ajustada para implantar o Chatwoot com Nginx como proxy reverso, incluindo um certificado SSL autoassinado, ideal para ambientes de desenvolvimento ou redes locais.

🎯 Objetivo

Simplificar a instalação e configuração do Chatwoot, eliminando as complexidades iniciais e permitindo que você tenha uma instância funcionando rapidamente em seu ambiente local, acessível por um domínio amigável e com HTTPS.

🛠️ Pré-requisitos

Certifique-se de ter os seguintes softwares instalados em seu sistema:

    Git: Para clonar os repositórios.

    Docker & Docker Compose: Para orquestrar os serviços do Chatwoot.

    Nginx: Será instalado e configurado automaticamente pelo script.

    OpenSSL: Será instalado e utilizado pelo script para gerar o certificado SSL autoassinado.

⚙️ Configuração e Instalação

Siga os passos abaixo para colocar seu NovoChat em funcionamento:

1. Preparação do Ambiente

1.1. Clone o Repositório Oficial do Chatwoot

Primeiro, obtenha a base do Chatwoot:
Bash

git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot

1.2. Configure o Arquivo hosts

É fundamental que o host.novochat.internal aponte para o IP do seu servidor Docker.

    No seu servidor (Linux): Edite o arquivo /etc/hosts:
    Bash

    sudo nano /etc/hosts
    # Adicione a seguinte linha, substituindo 192.168.5.40 pelo IP REAL do seu servidor
    192.168.5.40    host.novochat.internal

    No seu computador local (Windows): Edite o arquivo C:\Windows\System32\drivers\etc\hosts (execute o Bloco de Notas como administrador):

    192.168.5.40    host.novochat.internal

2. Configure o Chatwoot

Navegue de volta para o diretório raiz do seu projeto novochat-automacao que você clonou.

2.1. Clone o Repositório de Automação

Bash

cd .. # Se você ainda estiver no diretório 'chatwoot'
git clone https://github.com/amdremessias/novochat.git novochat-automacao
cd novochat-automacao

2.2. Ajuste o Arquivo .env

Dentro do diretório novochat-automacao, você encontrará um arquivo .env.example. Copie-o para .env e edite suas variáveis.
Bash

cp .env.example .env
nano .env # ou seu editor de texto preferido

Verifique e ajuste as seguintes linhas para corresponder ao seu ambiente e ao uso do Nginx (HTTPS):
Snippet de código

# Substitua pela URL que você planeja usar para sua aplicação
FRONTEND_URL=https://host.novochat.internal
# Para usar uma URL dedicada para as páginas da central de ajuda
HELPCENTER_URL=https://host.novochat.internal

# Se você planeja usar CDN para seus assets, defina o Host do CDN de Assets
ASSET_CDN_HOST=https://host.novochat.internal

# Certifique-se de que sua senha do Redis seja forte e única!
REDIS_PASSWORD=UMA_SENHA_MUITO_FORTE_E_UNICA_AQUI! # <--- **ALTERE ESTA LINHA**

# Se usar DATABASE_URL, comente as variáveis POSTGRES_ separadas
# Exemplo se for usar:
# DATABASE_URL=postgresql://postgres:SUA_SENHA_POSTGRES@postgres:5432/chatwoot

2.3. Confirme o compose.yml

O arquivo compose.yml neste repositório já está configurado para expor os serviços Docker no IP do seu host (192.168.5.40). Verifique as portas mapeadas, especialmente a do serviço rails:
YAML

# Exemplo relevante do compose.yml:
  rails:
    ports:
      - '192.168.5.40:3000:3000' # Acesso do Nginx ao Chatwoot interno

3. Deploy do Chatwoot com Docker Compose

Com o .env e o compose.yml configurados, vamos iniciar os serviços e preparar o banco de dados.
Bash

# Navegue para o diretório raiz do Chatwoot (onde está o compose.yml e .env)
cd /caminho/para/seu/diretorio/chatwoot-base

# 3.1. Pare e remova qualquer instalação Docker Compose anterior (limpeza completa)
docker compose down -v --remove-orphans
docker volume rm chatwoot_postgres_data # Confirme o nome do volume se for diferente

# 3.2. Suba os serviços
docker compose up -d

# 3.3. Carregue o esquema do banco de dados (isso cria as tabelas iniciais)
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 docker compose run --rm rails bundle exec rails db:schema:load

# 3.4. Recompile os assets (garantindo que as URLs HTTPS sejam geradas)
docker compose run --rm rails bundle exec rails assets:clobber
docker compose run --rm rails bundle exec rails assets:precompile

# 3.5. Verifique se todos os serviços estão "Up"
docker compose ps

4. Configuração do Nginx como Proxy Reverso (com SSL Autoassinado)

Este repositório inclui um script que automatiza a instalação e configuração do Nginx.

4.1. Clone e Dê Permissões ao Script

Bash

# Certifique-se de estar no diretório 'novochat-automacao'
cd /caminho/para/seu/diretorio/novochat-automacao

git clone https://github.com/amdremessias/novochat/tree/main .
chmod +x install_nginx_chatwoot_final.sh # Ou o nome do seu script final

4.2. Execute o Script de Configuração do Nginx

Bash

sudo ./install_nginx_chatwoot_final.sh

O script solicitará algumas confirmações. Pressione Enter para aceitar os valores padrão, que já estão otimizados para sua configuração. Ele irá:

    Instalar Nginx e OpenSSL.

    Gerar um certificado SSL autoassinado para host.novochat.internal.

    Configurar o Nginx para redirecionar HTTP (porta 80) para HTTPS (porta 443).

    Configurar o proxy reverso para direcionar as requisições para o serviço Chatwoot (seu IP do host:3000).

🔐 Importante: Certificado SSL Autoassinado

Como você está usando um certificado autoassinado para host.novochat.internal, seu navegador emitirá um aviso de segurança. Para evitar isso e garantir que o navegador confie na conexão, você deve importar o certificado gerado pelo script para o seu navegador.

O arquivo do certificado estará em: /etc/nginx/ssl/host.novochat.internal.crt no seu servidor. Copie-o para sua máquina local e importe-o nas configurações de certificado do seu navegador.

✅ Teste o NovoChat

Após todos os passos, abra seu navegador e acesse:

    https://host.novochat.internal

Você deverá ver a tela de login/cadastro do Chatwoot.

Criação / Redefinição de Conta de Administrador

Se você não conseguir fazer login ou precisa criar a primeira conta, use os comandos Docker Compose abaixo (no diretório raiz do Chatwoot):

    Criar nova conta de administrador:
    Bash

DISABLE_DATABASE_ENVIRONMENT_CHECK=1 docker compose run --rm rails bundle exec rake chatwoot:create_admin --trace EMAIL="seuemail@exemplo.com" PASSWORD="SuaSenhaSegura!"

(Substitua seuemail@exemplo.com e SuaSenhaSegura!)

Redefinir senha de uma conta existente:
Bash

    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 docker compose run --rm rails bundle exec rake chatwoot:reset_password --trace EMAIL="seuemail@exemplo.com" PASSWORD="NovaSenhaSegura!"

    (Substitua seuemail@exemplo.com e NovaSenhaSegura!)

🔄 Manutenção e Reinicialização

Se precisar parar ou reiniciar seu ambiente, use os comandos Docker Compose no diretório raiz do Chatwoot:

    Parar todos os serviços:
    Bash

docker compose stop

Iniciar todos os serviços:
Bash

docker compose up -d

Reiniciar Nginx (após alterações em sua config):
Bash

    sudo systemctl restart nginx

🧹 Script de Auto Limpeza e Novo Deploy

Para uma limpeza completa e um novo deploy do projeto, você pode usar o script autocloeansetup.sh (se você o tiver no seu repositório de automação). Certifique-se de que ele esteja executável (chmod +x autocloeansetup.sh) e execute-o na raiz do seu repositório de automação:
Bash

sudo ./autocloeansetup.sh

__________________________________________________
https://hub.docker.com/r/chatwoot/chatwoot/tags
___________________________________________________
https://hub.docker.com/r/atendai/evolution-api/tags

docker compose run --rm rails bundle exec rails db:migrate
