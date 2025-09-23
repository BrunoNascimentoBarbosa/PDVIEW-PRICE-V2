#!/bin/bash

# Script de instalação do PDVIEW para Orange Pi
# Compatível com Orange Pi Zero 2W e outros modelos ARM

set -e

echo "======================================"
echo "PDVIEW - Instalador para Orange Pi"
echo "======================================"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script não deve ser executado como root!"
   echo "Execute como usuário normal: ./install.sh"
   exit 1
fi

# Detectar arquitetura
ARCH=$(uname -m)
echo "Arquitetura detectada: $ARCH"

# Verificar se é ARM
if [[ "$ARCH" != "aarch64" ]] && [[ "$ARCH" != "armv7l" ]]; then
    print_warning "Arquitetura não é ARM. Continuando mesmo assim..."
fi

# Diretório de instalação
INSTALL_DIR="$HOME/pdview"
SERVICE_NAME="pdview"

echo ""
echo "Diretório de instalação: $INSTALL_DIR"
echo ""

# Função para verificar dependências
check_dependencies() {
    echo "Verificando dependências..."

    # Lista de comandos necessários
    local deps=("sqlite3")
    local missing=()

    for cmd in "${deps[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        print_warning "Dependências faltando: ${missing[*]}"
        echo ""
        read -p "Deseja instalar as dependências agora? (s/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            echo "Instalando dependências..."
            sudo apt update
            sudo apt install -y sqlite3
            print_success "Dependências instaladas!"
        else
            print_error "Instalação cancelada. Instale as dependências manualmente."
            exit 1
        fi
    else
        print_success "Todas as dependências encontradas!"
    fi
}

# Função para criar estrutura de diretórios
create_directories() {
    echo ""
    echo "Criando estrutura de diretórios..."

    # Verificar se já existe instalação anterior
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Diretório $INSTALL_DIR já existe!"
        read -p "Deseja sobrescrever a instalação existente? (s/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            print_error "Instalação cancelada."
            exit 1
        fi
        # Fazer backup
        BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        echo "Criando backup em $BACKUP_DIR..."
        mv "$INSTALL_DIR" "$BACKUP_DIR"
        print_success "Backup criado!"
    fi

    # Criar diretórios
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/data"
    mkdir -p "$INSTALL_DIR/videos"
    mkdir -p "$INSTALL_DIR/static"
    mkdir -p "$INSTALL_DIR/logs"

    print_success "Diretórios criados!"
}

# Função para copiar arquivos
copy_files() {
    echo ""
    echo "Copiando arquivos..."

    # Verificar se o binário existe
    if [ ! -f "pdview" ]; then
        print_error "Binário 'pdview' não encontrado!"
        echo "Execute primeiro: ./build.sh"
        exit 1
    fi

    # Copiar binário
    cp pdview "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/pdview"

    # Copiar arquivos estáticos
    cp -r static/* "$INSTALL_DIR/static/" 2>/dev/null || true

    # Copiar vídeos (se existirem)
    if [ -d "videos" ] && [ "$(ls -A videos)" ]; then
        cp -r videos/* "$INSTALL_DIR/videos/" 2>/dev/null || true
        print_success "Vídeos copiados!"
    else
        print_warning "Nenhum vídeo encontrado. Adicione vídeos em $INSTALL_DIR/videos/"
    fi

    print_success "Arquivos copiados!"
}

# Função para configurar serviço systemd
setup_service() {
    echo ""
    echo "Configurando serviço systemd..."

    # Criar arquivo de serviço personalizado
    SERVICE_FILE="/tmp/${SERVICE_NAME}.service"

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=PDVIEW Orange Pi Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/pdview
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pdview
Environment="PORT=8080"
Environment="GOGC=50"

[Install]
WantedBy=multi-user.target
EOF

    # Instalar serviço
    sudo cp "$SERVICE_FILE" "/etc/systemd/system/${SERVICE_NAME}.service"
    sudo systemctl daemon-reload

    print_success "Serviço systemd configurado!"

    # Perguntar se deseja habilitar o serviço
    read -p "Deseja habilitar o serviço para iniciar automaticamente? (s/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        sudo systemctl enable ${SERVICE_NAME}
        print_success "Serviço habilitado para inicialização automática!"
    fi

    # Perguntar se deseja iniciar o serviço agora
    read -p "Deseja iniciar o serviço agora? (s/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        sudo systemctl start ${SERVICE_NAME}
        sleep 2
        if systemctl is-active --quiet ${SERVICE_NAME}; then
            print_success "Serviço iniciado com sucesso!"
        else
            print_error "Erro ao iniciar serviço. Verifique com: sudo journalctl -u ${SERVICE_NAME}"
        fi
    fi
}

# Função para configurar firewall (opcional)
setup_firewall() {
    echo ""
    read -p "Deseja configurar o firewall para permitir acesso na porta 8080? (s/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        # Verificar se ufw está instalado
        if command -v ufw &> /dev/null; then
            sudo ufw allow 8080/tcp
            print_success "Regra de firewall adicionada!"
        else
            print_warning "UFW não encontrado. Configure o firewall manualmente se necessário."
        fi
    fi
}

# Função para criar atalhos
create_shortcuts() {
    echo ""
    echo "Criando atalhos úteis..."

    # Criar script de controle
    cat > "$INSTALL_DIR/control.sh" << 'EOF'
#!/bin/bash
# Script de controle do PDVIEW

case "$1" in
    start)
        sudo systemctl start pdview
        echo "PDVIEW iniciado"
        ;;
    stop)
        sudo systemctl stop pdview
        echo "PDVIEW parado"
        ;;
    restart)
        sudo systemctl restart pdview
        echo "PDVIEW reiniciado"
        ;;
    status)
        sudo systemctl status pdview
        ;;
    logs)
        sudo journalctl -u pdview -f
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF

    chmod +x "$INSTALL_DIR/control.sh"

    # Criar link simbólico para acesso fácil
    if [ -d "$HOME/bin" ]; then
        ln -sf "$INSTALL_DIR/control.sh" "$HOME/bin/pdview-control"
        print_success "Atalho criado: pdview-control"
    fi

    print_success "Scripts de controle criados!"
}

# Função para mostrar informações finais
show_info() {
    # Obter IP local
    IP=$(hostname -I | awk '{print $1}')

    echo ""
    echo "======================================"
    echo -e "${GREEN}✅ Instalação concluída com sucesso!${NC}"
    echo "======================================"
    echo ""
    echo "Informações importantes:"
    echo "------------------------"
    echo "📁 Diretório de instalação: $INSTALL_DIR"
    echo "🌐 URL de acesso: http://${IP}:8080"
    echo "📺 Player: http://${IP}:8080/player.html"
    echo ""
    echo "Comandos úteis:"
    echo "--------------"
    echo "Iniciar serviço:    sudo systemctl start ${SERVICE_NAME}"
    echo "Parar serviço:      sudo systemctl stop ${SERVICE_NAME}"
    echo "Reiniciar serviço:  sudo systemctl restart ${SERVICE_NAME}"
    echo "Status do serviço:  sudo systemctl status ${SERVICE_NAME}"
    echo "Ver logs:           sudo journalctl -u ${SERVICE_NAME} -f"
    echo ""
    echo "Ou use o script de controle:"
    echo "  $INSTALL_DIR/control.sh {start|stop|restart|status|logs}"
    echo ""
    echo "Adicionar vídeos:"
    echo "----------------"
    echo "1. Otimize o vídeo com: ./optimize-video.sh seu-video.mp4"
    echo "2. Copie para: $INSTALL_DIR/videos/base.mp4"
    echo "3. Reinicie o serviço: sudo systemctl restart ${SERVICE_NAME}"
    echo ""
    echo "======================================"
}

# Execução principal
main() {
    echo "Este script irá instalar o PDVIEW no seu Orange Pi"
    echo ""
    read -p "Deseja continuar? (s/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_error "Instalação cancelada."
        exit 1
    fi

    check_dependencies
    create_directories
    copy_files
    setup_service
    setup_firewall
    create_shortcuts
    show_info
}

# Executar instalação
main