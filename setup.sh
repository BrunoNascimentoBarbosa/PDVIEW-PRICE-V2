#!/bin/bash

# PDVIEW - Script de Instalação Automática
# Instala tudo que é necessário automaticamente no Orange Pi
# Para usuários leigos - apenas execute: curl -sSL https://raw.githubusercontent.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2/main/setup.sh | bash

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    PDVIEW SETUP AUTOMÁTICO                  ║"
echo "║              Sistema de Preços para Orange Pi               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Função para imprimir mensagens
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
    log_error "Este script não deve ser executado como root!"
    echo "Execute como usuário normal: bash setup.sh"
    exit 1
fi

# Detectar sistema operacional e arquitetura
OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
ARCH=$(uname -m)
DISTRO=$(lsb_release -cs 2>/dev/null || echo "unknown")

log_info "Sistema detectado: $OS $DISTRO ($ARCH)"

# Verificar se é sistema compatível
if [[ "$ARCH" != "aarch64" && "$ARCH" != "armv7l" && "$ARCH" != "x86_64" ]]; then
    log_warning "Arquitetura $ARCH pode não ser totalmente compatível"
fi

# Diretórios
PROJECT_DIR="$HOME/pdview"
TEMP_DIR="/tmp/pdview-setup"
GO_VERSION="1.21.4"

# Função para instalar dependências do sistema
install_system_deps() {
    log_info "Instalando dependências do sistema..."

    # Atualizar lista de pacotes
    sudo apt update -qq

    # Instalar dependências básicas
    sudo apt install -y \
        curl \
        wget \
        git \
        build-essential \
        sqlite3 \
        ffmpeg \
        unzip \
        systemctl \
        ufw 2>/dev/null || true

    log_success "Dependências do sistema instaladas"
}

# Função para instalar Go
install_go() {
    # Verificar se Go já está instalado
    if command -v go &> /dev/null; then
        CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        log_info "Go $CURRENT_GO_VERSION já está instalado"
        return 0
    fi

    log_info "Instalando Go $GO_VERSION..."

    # Detectar arquitetura para download
    case $ARCH in
        "aarch64")
            GO_ARCH="linux-arm64"
            ;;
        "armv7l")
            GO_ARCH="linux-armv6l"
            ;;
        "x86_64")
            GO_ARCH="linux-amd64"
            ;;
        *)
            log_error "Arquitetura $ARCH não suportada"
            exit 1
            ;;
    esac

    # Download e instalação do Go
    cd /tmp
    wget -q "https://go.dev/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"

    # Remover instalação anterior se existir
    sudo rm -rf /usr/local/go

    # Extrair Go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.${GO_ARCH}.tar.gz"

    # Configurar PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    export PATH=$PATH:/usr/local/go/bin

    # Limpar download
    rm "go${GO_VERSION}.${GO_ARCH}.tar.gz"

    log_success "Go $GO_VERSION instalado com sucesso"
}

# Função para baixar o projeto
download_project() {
    log_info "Baixando projeto PDVIEW..."

    # Remover diretório anterior se existir
    if [ -d "$PROJECT_DIR" ]; then
        log_warning "Removendo instalação anterior..."
        rm -rf "$PROJECT_DIR"
    fi

    # Criar diretório temporário
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    # Baixar projeto do GitHub
    git clone https://github.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2.git .

    # Mover para diretório final
    mv "$TEMP_DIR" "$PROJECT_DIR"
    cd "$PROJECT_DIR"

    log_success "Projeto baixado para $PROJECT_DIR"
}

# Função para compilar o projeto
build_project() {
    log_info "Compilando projeto..."

    cd "$PROJECT_DIR"

    # Garantir que Go está no PATH
    export PATH=$PATH:/usr/local/go/bin

    # Inicializar módulo Go e baixar dependências
    go mod download
    go mod tidy

    # Compilar para a arquitetura atual
    go build -ldflags="-s -w" -o pdview main.go

    # Tornar executável
    chmod +x pdview

    log_success "Projeto compilado com sucesso"
}

# Função para criar estrutura de dados
setup_data() {
    log_info "Configurando estrutura de dados..."

    cd "$PROJECT_DIR"

    # Criar diretórios necessários
    mkdir -p data logs videos

    # Definir permissões
    chmod 755 data logs videos

    log_success "Estrutura de dados configurada"
}

# Função para configurar serviço systemd
setup_service() {
    log_info "Configurando serviço do sistema..."

    cd "$PROJECT_DIR"

    # Criar arquivo de serviço personalizado
    cat > pdview.service << EOF
[Unit]
Description=PDVIEW Orange Pi Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/pdview
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
    sudo cp pdview.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable pdview

    log_success "Serviço configurado e habilitado"
}

# Função para configurar firewall
setup_firewall() {
    log_info "Configurando firewall..."

    # Verificar se ufw está disponível
    if command -v ufw &> /dev/null; then
        sudo ufw allow 8080/tcp 2>/dev/null || true
        log_success "Porta 8080 liberada no firewall"
    else
        log_warning "UFW não encontrado, configure o firewall manualmente se necessário"
    fi
}

# Função para iniciar serviços
start_services() {
    log_info "Iniciando serviços..."

    # Iniciar serviço
    sudo systemctl start pdview

    # Verificar se iniciou corretamente
    sleep 3
    if systemctl is-active --quiet pdview; then
        log_success "Serviço PDVIEW iniciado com sucesso"
    else
        log_error "Falha ao iniciar serviço. Verificando logs..."
        sudo journalctl -u pdview -n 10 --no-pager
        exit 1
    fi
}

# Função para criar scripts de controle
create_shortcuts() {
    log_info "Criando atalhos de controle..."

    cd "$PROJECT_DIR"

    # Script de controle
    cat > control.sh << 'EOF'
#!/bin/bash
case "$1" in
    start)
        sudo systemctl start pdview
        echo "✅ PDVIEW iniciado"
        ;;
    stop)
        sudo systemctl stop pdview
        echo "⏹️  PDVIEW parado"
        ;;
    restart)
        sudo systemctl restart pdview
        echo "🔄 PDVIEW reiniciado"
        ;;
    status)
        sudo systemctl status pdview
        ;;
    logs)
        sudo journalctl -u pdview -f
        ;;
    update)
        cd ~/pdview
        git pull
        go build -ldflags="-s -w" -o pdview main.go
        sudo systemctl restart pdview
        echo "🚀 PDVIEW atualizado e reiniciado"
        ;;
    *)
        echo "Uso: ./control.sh {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF

    chmod +x control.sh

    # Criar link no PATH se possível
    mkdir -p "$HOME/bin"
    ln -sf "$PROJECT_DIR/control.sh" "$HOME/bin/pdview" 2>/dev/null || true

    log_success "Scripts de controle criados"
}

# Função para exibir informações finais
show_final_info() {
    # Obter IP local
    IP=$(hostname -I | awk '{print $1}' | head -1)

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 🎉 INSTALAÇÃO CONCLUÍDA! 🎉                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📍 INFORMAÇÕES DE ACESSO:${NC}"
    echo "   🌐 Interface Admin: http://${IP}:8080"
    echo "   📺 Player: http://${IP}:8080/player.html"
    echo "   📁 Diretório: $PROJECT_DIR"
    echo ""
    echo -e "${BLUE}🎛️  COMANDOS ÚTEIS:${NC}"
    echo "   Iniciar:    ./control.sh start"
    echo "   Parar:      ./control.sh stop"
    echo "   Reiniciar:  ./control.sh restart"
    echo "   Status:     ./control.sh status"
    echo "   Logs:       ./control.sh logs"
    echo "   Atualizar:  ./control.sh update"
    echo ""
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo "   1. Abra um navegador e acesse: http://${IP}:8080"
    echo "   2. Configure os preços de combustível"
    echo "   3. Teste o player em: http://${IP}:8080/player.html"
    echo ""
    echo -e "${YELLOW}📝 NOTAS IMPORTANTES:${NC}"
    echo "   • O serviço inicia automaticamente no boot"
    echo "   • Para adicionar vídeo: coloque em $PROJECT_DIR/videos/base.mp4"
    echo "   • Use ./optimize-video.sh para otimizar vídeos"
    echo ""
    echo -e "${GREEN}✨ PDVIEW está rodando e pronto para uso! ✨${NC}"
}

# Função principal
main() {
    log_info "Iniciando instalação automática do PDVIEW..."

    # Verificar conexão com internet
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Sem conexão com internet. Verifique sua conexão e tente novamente."
        exit 1
    fi

    # Executar instalação passo a passo
    install_system_deps
    install_go
    download_project
    build_project
    setup_data
    setup_service
    setup_firewall
    create_shortcuts
    start_services
    show_final_info

    log_success "Instalação automática concluída com sucesso!"
}

# Executar instalação
main "$@"