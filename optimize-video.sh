#!/bin/bash

# Script para otimizar vídeos para Orange Pi Zero 2W
# Converte para formato eficiente para dispositivos ARM

set -e

echo "======================================"
echo "PDVIEW - Otimizador de Vídeo"
echo "Para Orange Pi Zero 2W (ARM64)"
echo "======================================"
echo ""

# Verificar se ffmpeg está instalado
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Erro: ffmpeg não está instalado!"
    echo ""
    echo "Instale com:"
    echo "  macOS:  brew install ffmpeg"
    echo "  Linux:  sudo apt install ffmpeg"
    echo "  Orange Pi: sudo apt install ffmpeg"
    exit 1
fi

# Verificar parâmetros
if [ "$#" -lt 1 ]; then
    echo "Uso: $0 <video-entrada> [video-saida]"
    echo ""
    echo "Exemplo:"
    echo "  $0 propaganda.mp4"
    echo "  $0 propaganda.mp4 base.mp4"
    echo ""
    echo "Se o nome de saída não for especificado,"
    echo "será salvo como 'videos/base.mp4'"
    exit 1
fi

INPUT_VIDEO="$1"
OUTPUT_VIDEO="${2:-videos/base.mp4}"

# Verificar se arquivo de entrada existe
if [ ! -f "$INPUT_VIDEO" ]; then
    echo "❌ Erro: Arquivo '$INPUT_VIDEO' não encontrado!"
    exit 1
fi

# Criar diretório videos se não existir
mkdir -p videos

echo "📹 Vídeo de entrada: $INPUT_VIDEO"
echo "🎯 Vídeo de saída: $OUTPUT_VIDEO"
echo ""

# Obter informações do vídeo original
echo "Analisando vídeo original..."
ffmpeg -i "$INPUT_VIDEO" 2>&1 | grep -E "Stream|Duration" || true
echo ""

echo "======================================"
echo "Selecione o perfil de otimização:"
echo "======================================"
echo ""
echo "1) Ultra Leve (192x384, 24fps, 300kbps)"
echo "   ✅ Máxima economia de recursos"
echo "   ✅ Ideal para Orange Pi Zero 2W"
echo "   ⚠️  Qualidade visual básica"
echo ""
echo "2) Leve (192x384, 24fps, 500kbps) [RECOMENDADO]"
echo "   ✅ Bom equilíbrio qualidade/performance"
echo "   ✅ Funciona bem no Orange Pi"
echo "   ✅ Qualidade visual aceitável"
echo ""
echo "3) Normal (192x384, 30fps, 800kbps)"
echo "   ✅ Boa qualidade visual"
echo "   ⚠️  Maior uso de recursos"
echo "   ⚠️  Pode ter lentidão no Orange Pi"
echo ""
echo "4) Alta Qualidade (192x384, 30fps, 1200kbps)"
echo "   ✅ Melhor qualidade visual"
echo "   ❌ Não recomendado para Orange Pi"
echo "   ⚠️  Alto uso de CPU/RAM"
echo ""
echo "5) Personalizado"
echo "   Configure manualmente todos os parâmetros"
echo ""
read -p "Escolha [1-5]: " profile

# Configurações base
WIDTH=192
HEIGHT=384
CODEC="libx264"
PROFILE="baseline"
LEVEL="3.0"
PRESET="slow"
PIXEL_FORMAT="yuv420p"

# Aplicar perfil selecionado
case $profile in
    1)
        echo "➜ Perfil: Ultra Leve"
        FPS=24
        BITRATE="300k"
        PRESET="ultrafast"
        ;;
    2)
        echo "➜ Perfil: Leve (Recomendado)"
        FPS=24
        BITRATE="500k"
        PRESET="fast"
        ;;
    3)
        echo "➜ Perfil: Normal"
        FPS=30
        BITRATE="800k"
        PRESET="medium"
        ;;
    4)
        echo "➜ Perfil: Alta Qualidade"
        FPS=30
        BITRATE="1200k"
        PRESET="slow"
        ;;
    5)
        echo "➜ Perfil: Personalizado"
        read -p "Largura [192]: " custom_width
        WIDTH=${custom_width:-192}
        read -p "Altura [384]: " custom_height
        HEIGHT=${custom_height:-384}
        read -p "FPS [24]: " custom_fps
        FPS=${custom_fps:-24}
        read -p "Bitrate (ex: 500k) [500k]: " custom_bitrate
        BITRATE=${custom_bitrate:-500k}
        read -p "Preset (ultrafast/fast/medium/slow) [fast]: " custom_preset
        PRESET=${custom_preset:-fast}
        ;;
    *)
        echo "❌ Opção inválida!"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Configurações de conversão:"
echo "======================================"
echo "Resolução: ${WIDTH}x${HEIGHT}"
echo "FPS: $FPS"
echo "Bitrate: $BITRATE"
echo "Codec: H.264 baseline"
echo "Preset: $PRESET"
echo ""

echo "🎬 Iniciando conversão..."
echo "⏳ Isso pode levar alguns minutos..."
echo ""

# Comando ffmpeg com todas as otimizações
ffmpeg -i "$INPUT_VIDEO" \
    -vf "scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease,pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}" \
    -c:v $CODEC \
    -profile:v $PROFILE \
    -level:v $LEVEL \
    -preset $PRESET \
    -b:v $BITRATE \
    -maxrate $BITRATE \
    -bufsize $(echo $BITRATE | sed 's/k//')k \
    -g $((FPS * 2)) \
    -pix_fmt $PIXEL_FORMAT \
    -movflags +faststart \
    -an \
    -y "$OUTPUT_VIDEO"

echo ""
echo "✅ Conversão concluída com sucesso!"
echo ""

# Mostrar informações do arquivo gerado
echo "======================================"
echo "Informações do vídeo otimizado:"
echo "======================================"
ls -lh "$OUTPUT_VIDEO"
echo ""
ffmpeg -i "$OUTPUT_VIDEO" 2>&1 | grep -E "Stream|Duration" || true

echo ""
echo "======================================"
echo "✅ Vídeo otimizado salvo em:"
echo "   $OUTPUT_VIDEO"
echo ""
echo "Próximos passos:"
echo "1. Copie o vídeo para o Orange Pi:"
echo "   scp $OUTPUT_VIDEO pi@<IP>:/home/pi/pdview/videos/"
echo ""
echo "2. Teste o player:"
echo "   http://<IP-DO-ORANGE-PI>:8080/player.html"
echo "======================================"