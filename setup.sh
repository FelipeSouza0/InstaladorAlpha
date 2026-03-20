#!/bin/bash

# Cores para o terminal ficar bonito
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}==> Iniciando a instalação de programas...${NC}"

# Lista de comandos de instalação (Exemplo para Ubuntu/Debian/Mint)
sudo apt update
sudo apt install -y git curl wget vlc chrome-gnome-shell

echo -e "${GREEN}==> Tudo pronto! Aproveite seu sistema.${NC}"
