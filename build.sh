#!/bin/bash

# Build Script para PDVIEW Orange Pi
# Compila o servidor Go para ARM64 (Orange Pi Zero 2W)

set -e

echo "======================================"
echo "PDVIEW Build Script para Orange Pi"
echo "======================================"

# Detectar sistema operacional
OS=$(uname -s)
ARCH=$(uname -m)

echo "Sistema atual: $OS $ARCH"
echo ""

# Função para build local (desenvolvimento)
build_local() {
    echo "Building para sistema local..."
    go build -o pdview main.go
    echo "✅ Build local concluído: ./pdview"
}

# Função para build ARM64
build_arm64() {
    echo "Building para ARM64 (Orange Pi Zero 2W)..."

    # Configurar variáveis de ambiente para cross-compilation
    export GOOS=linux
    export GOARCH=arm64
    export CGO_ENABLED=1

    # Para cross-compilation com CGO, precisamos de um compilador ARM
    if [[ "$OS" == "Darwin" ]]; then
        echo "⚠️  Cross-compilation com SQLite no macOS requer configuração adicional."
        echo "Tentando build sem CGO (funcionalidade limitada)..."
        export CGO_ENABLED=0
    fi

    # Build com flags de otimização
    go build -ldflags="-s -w" -o pdview-arm64 main.go

    echo "✅ Build ARM64 concluído: ./pdview-arm64"
    echo "Tamanho do binário:"
    ls -lh pdview-arm64
}

# Função para build ARM (32-bit, caso necessário)
build_arm32() {
    echo "Building para ARM 32-bit..."

    export GOOS=linux
    export GOARCH=arm
    export GOARM=7
    export CGO_ENABLED=0

    go build -ldflags="-s -w" -o pdview-arm32 main.go

    echo "✅ Build ARM32 concluído: ./pdview-arm32"
    echo "Tamanho do binário:"
    ls -lh pdview-arm32
}

# Função para criar pacote de distribuição
create_package() {
    echo ""
    echo "Criando pacote de distribuição..."

    PACKAGE_NAME="pdview-orange-$(date +%Y%m%d)"

    # Criar diretório temporário
    mkdir -p dist/$PACKAGE_NAME

    # Copiar arquivos necessários
    cp pdview-arm64 dist/$PACKAGE_NAME/pdview 2>/dev/null || true
    cp -r static dist/$PACKAGE_NAME/
    cp -r videos dist/$PACKAGE_NAME/ 2>/dev/null || mkdir -p dist/$PACKAGE_NAME/videos
    cp pdview.service dist/$PACKAGE_NAME/ 2>/dev/null || true
    cp install.sh dist/$PACKAGE_NAME/ 2>/dev/null || true
    cp README.md dist/$PACKAGE_NAME/ 2>/dev/null || true

    # Criar diretório data
    mkdir -p dist/$PACKAGE_NAME/data

    # Criar arquivo zip
    cd dist
    tar -czf $PACKAGE_NAME.tar.gz $PACKAGE_NAME
    cd ..

    echo "✅ Pacote criado: dist/$PACKAGE_NAME.tar.gz"
    echo "Tamanho do pacote:"
    ls -lh dist/$PACKAGE_NAME.tar.gz
}

# Menu principal
echo "Selecione o tipo de build:"
echo "1) Local (desenvolvimento)"
echo "2) ARM64 (Orange Pi Zero 2W)"
echo "3) ARM32 (Orange Pi antigos)"
echo "4) Todos"
echo "5) ARM64 + Criar pacote"
echo ""
read -p "Opção [1-5]: " option

case $option in
    1)
        build_local
        ;;
    2)
        build_arm64
        ;;
    3)
        build_arm32
        ;;
    4)
        build_local
        echo ""
        build_arm64
        echo ""
        build_arm32
        ;;
    5)
        build_arm64
        create_package
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Build concluído com sucesso!"
echo "======================================"
echo ""
echo "Próximos passos:"
echo "1. Copie o binário para o Orange Pi:"
echo "   scp pdview-arm64 pi@<IP-DO-ORANGE-PI>:/home/pi/pdview/"
echo ""
echo "2. No Orange Pi, execute:"
echo "   chmod +x pdview"
echo "   ./pdview"
echo ""
echo "3. Acesse a interface:"
echo "   http://<IP-DO-ORANGE-PI>:8080"
echo ""