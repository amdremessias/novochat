#!/bin/bash
echo "auto-remoção e setup"
echo "
   _____
  | ___ |
  ||   ||  M.C.
  ||___||
  |   _ |
  |_____|
 /_/_|_\_\----.
/_/__|__\_\   )
             (
             []


"
echo ""
echo " Removendo orphnas e imagens"
sleep 7
docker compose down -v --remove-orphans --rmi all
echo "Restart Docker....."
sudo systemctl restart docker
sleep 7
echo ""
echo "Preparando banco db:chatwoot_prepare"
docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
sleep 5
docker compose up -d
sleep 7
#DISABLE_DATABASE_ENVIRONMENT_CHECK=1 docker-compose run --rm rails bundle exec rails db:schema:reload
echo ""
echo "Criando user admin defautl diretamente no banco"
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 docker compose run --rm rails bundle exec rake chatwoot:create_admin --trace EMAIL="amdrelmes@gmail.con" PASSWORD="@mdreWp4ss"
echo "Fim"
echo "Acesse https://host.novochat.internal/" 
eho ""
echo "

███╗   ███╗██████╗ ███████╗███████╗ ██╗██╗  ██╗███████╗
████╗ ████║╚════██╗██╔════╝██╔════╝███║██║  ██║██╔════╝
██╔████╔██║ █████╔╝███████╗███████╗╚██║███████║███████╗
██║╚██╔╝██║ ╚═══██╗╚════██║╚════██║ ██║╚════██║╚════██║
██║ ╚═╝ ██║██████╔╝███████║███████║ ██║     ██║███████║
╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═╝     ╚═╝╚══════╝


"
