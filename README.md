# 🎯 PDVIEW v2.0 - Sistema de Preços para Postos

Sistema ultra-leve e otimizado para exibir preços de combustíveis em Orange Pi, Raspberry Pi e similares.

## 📦 Instalação Completa no Orange Pi

### 1️⃣ Instalar Dependências do Sistema

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências essenciais
sudo apt install -y git curl wget build-essential ffmpeg

# Instalar SQLite (para banco de dados)
sudo apt install -y sqlite3 libsqlite3-dev
```

### 2️⃣ Instalar Go Language

```bash
# Baixar Go para ARM64
wget https://go.dev/dl/go1.21.5.linux-arm64.tar.gz

# Extrair para /usr/local
sudo tar -C /usr/local -xzf go1.21.5.linux-arm64.tar.gz

# Configurar PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
source ~/.bashrc

# Verificar instalação
go version
# Deve mostrar: go version go1.21.5 linux/arm64
```

### 3️⃣ Clonar e Configurar o Projeto

```bash
# Clonar repositório
git clone https://github.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2.git ~/pdview
cd ~/pdview

# Criar pastas necessárias
mkdir -p videos data

# Baixar dependências do Go
go mod init pdview-orange  # Se não existir go.mod
go get github.com/gorilla/mux
go get github.com/mattn/go-sqlite3
go mod tidy
```

### 4️⃣ Executar o Projeto

```bash
# Navegar até o projeto
cd ~/pdview

# Rodar o servidor
go run main.go

# Ou compilar e executar
go build -o pdview main.go
./pdview
```

### 5️⃣ Verificar Funcionamento

```bash
# Em outro terminal, testar a API
curl http://localhost:8080/api/prices

# Ou acessar no navegador
# http://IP-DO-ORANGE-PI:8080
```

### 🚀 Início Rápido (Comandos Sequenciais)

```bash
# Copie e cole tudo de uma vez:
sudo apt update && sudo apt upgrade -y && \
sudo apt install -y git curl wget build-essential ffmpeg sqlite3 libsqlite3-dev && \
wget https://go.dev/dl/go1.21.5.linux-arm64.tar.gz && \
sudo tar -C /usr/local -xzf go1.21.5.linux-arm64.tar.gz && \
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc && \
echo 'export GOPATH=$HOME/go' >> ~/.bashrc && \
source ~/.bashrc && \
git clone https://github.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2.git ~/pdview && \
cd ~/pdview && \
mkdir -p videos data && \
go mod tidy && \
go run main.go
```

Após executar, acesse `http://IP-DO-ORANGE-PI:8080` no navegador.


## 🚀 Características

- **Ultra Leve**: 10MB RAM (87% menos que v1)
- **Servidor Único**: Go binário otimizado
- **Video Loop Estável**: Sem travamentos ARM
- **Interface Responsiva**: Admin + Player
- **Auto-restart**: Recuperação automática

## 📱 Como Usar Após Instalação

1. **Acesse a interface**: `http://IP-DO-ORANGE-PI:8080`
2. **Configure preços** de Etanol e Gasolina
3. **Visualize no player**: `http://IP-DO-ORANGE-PI/player.html`

## 🎛️ Controle do Sistema

```bash
# Navegar até a pasta do projeto
cd ~/pdview

# Iniciar o servidor
go run main.go

# Para parar o servidor: Ctrl+C
```

## 🎥 Preparação de Vídeos

### Otimizar vídeo para o Orange Pi:

```bash
# No seu PC/Mac
chmod +x optimize-video.sh
./optimize-video.sh seu-video.mp4

# Escolha o perfil 2 (Recomendado)
# Copie o vídeo otimizado para o Orange Pi
scp videos/base.mp4 pi@<IP>:/home/pi/pdview/videos/
```

## 🖥️ Uso

### Acessar o Sistema

- **Interface Admin**: `http://<IP-ORANGE-PI>:8080`
- **Player que deve ser enviado para TB40 usando o programa Viplex Express no windows**: `http://<IP-ORANGE-PI>:8080/player.html`

### Comandos de Controle

```bash
# Iniciar serviço
sudo systemctl start pdview

# Parar serviço
sudo systemctl stop pdview

# Reiniciar serviço
sudo systemctl restart pdview

# Ver status
sudo systemctl status pdview

# Ver logs em tempo real
sudo journalctl -u pdview -f
```

### Script de Controle Alternativo

```bash
# Após instalação, use:
~/pdview/control.sh start|stop|restart|status|logs
```

## 📁 Estrutura do Projeto

```
pdview-orange/
├── main.go              # Servidor Go principal
├── go.mod               # Dependências Go
├── build.sh             # Script de compilação
├── install.sh           # Script de instalação
├── optimize-video.sh    # Otimizador de vídeos
├── pdview.service       # Arquivo systemd
├── static/
│   ├── index.html       # Interface administrativa
│   ├── player.html      # Player de vídeo
│   ├── style.css        # Estilos CSS
│   └── app.js           # JavaScript frontend
├── videos/
│   └── base.mp4         # Vídeo otimizado
└── data/
    └── prices.db        # Banco SQLite
```

## 🔌 API Endpoints

### GET /api/prices
Retorna os preços atuais

```json
{
  "id": 1,
  "etanol": 3.99,
  "gasolina": 5.99,
  "timestamp": "2024-01-10T10:30:00Z"
}
```

### POST /api/prices/update
Atualiza os preços

```json
{
  "etanol": 4.29,
  "gasolina": 6.19
}
```

### GET /api/prices/history
Retorna histórico de preços (últimos 100)

## ⚙️ Configuração Avançada

### Ajustar Porta do Servidor

Edite `/etc/systemd/system/pdview.service`:

```ini
Environment="PORT=8080"  # Mude para porta desejada
```

### Configurar IP Estático

```bash
sudo nano /etc/dhcpcd.conf

# Adicionar:
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8
```

### Limites de Recursos

Edite o serviço systemd para ajustar limites:

```ini
MemoryMax=100M    # Limite de RAM
CPUQuota=50%      # Limite de CPU
```

## 🐛 Troubleshooting

### Serviço não inicia

```bash
# Verificar logs
sudo journalctl -u pdview -n 50

# Verificar permissões
ls -la /home/pi/pdview/

# Testar manualmente
cd /home/pi/pdview
./pdview
```

### Vídeo não carrega

1. Verifique se o arquivo existe: `ls -la /home/pi/pdview/videos/`
2. Teste o vídeo: `ffplay /home/pi/pdview/videos/base.mp4`
3. Re-otimize com perfil mais leve

### Problemas de Performance

```bash
# Monitorar recursos
htop

# Verificar temperatura
vcgencmd measure_temp  # Raspberry Pi
cat /sys/class/thermal/thermal_zone0/temp  # Orange Pi

# Reduzir uso de recursos
# Use perfil "Ultra Leve" na otimização de vídeo
```


## 🔄 Atualizações

```bash
# No PC/Mac
git pull
./build.sh

# Copiar novo binário
scp pdview-arm64 pi@<IP>:/home/pi/pdview/pdview

# No Orange Pi
sudo systemctl restart pdview
```

---

**Desenvolvido com ❤️ para Orange Pi Zero 2W**