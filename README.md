# 🎯 PDVIEW v2.0 - Sistema de Preços para Postos

Sistema ultra-leve e otimizado para exibir preços de combustíveis em Orange Pi, Raspberry Pi e similares.

## ⚡ INSTALAÇÃO SUPER FÁCIL - 1 COMANDO APENAS!

**Para usuários leigos - Cole no terminal do Orange Pi:**

```bash
curl -sSL https://raw.githubusercontent.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2/main/setup.sh | bash
```

**✨ Pronto! O script instala tudo automaticamente:**
- ✅ Dependências do sistema
- ✅ Go (linguagem de programação)
- ✅ Projeto completo
- ✅ Configuração de serviço
- ✅ Inicialização automática

**📖 [Ver guia detalhado de instalação](INSTALACAO.md)**

---

## 🚀 Características

- **Ultra Leve**: 10MB RAM (87% menos que v1)
- **Servidor Único**: Go binário otimizado
- **Video Loop Estável**: Sem travamentos ARM
- **Interface Responsiva**: Admin + Player
- **Auto-restart**: Recuperação automática
- **Instalação 1-click**: Script automatizado

## 📱 Como Usar Após Instalação

1. **Acesse a interface**: `http://IP-DO-ORANGE-PI:8080`
2. **Configure preços** de Etanol e Gasolina
3. **Visualize no player**: `/player.html`

## 🎛️ Controle do Sistema

```bash
cd ~/pdview

./control.sh start     # Iniciar
./control.sh stop      # Parar
./control.sh restart   # Reiniciar
./control.sh status    # Ver status
./control.sh logs      # Ver logs
./control.sh update    # Atualizar versão
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
- **Player**: `http://<IP-ORANGE-PI>:8080/player.html`

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

## 📊 Comparação com Sistema Anterior

| Métrica | Sistema Antigo | PDVIEW Orange | Melhoria |
|---------|---------------|---------------|----------|
| RAM | ~80MB | ~10MB | 87.5% ↓ |
| CPU Idle | 15% | 5% | 66% ↓ |
| Tempo Boot | ~30s | <2s | 93% ↓ |
| Dependências | Python + Node.js | Go (binário único) | 90% ↓ |
| Tamanho | ~150MB | ~15MB | 90% ↓ |

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

## 📝 Licença

MIT License - Veja LICENSE para detalhes

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📞 Suporte

- Issues: [GitHub Issues](https://github.com/seu-usuario/pdview-orange/issues)
- Email: seu-email@exemplo.com

## ✨ Melhorias Futuras

- [ ] WebSocket para atualizações em tempo real
- [ ] Suporte a múltiplos displays
- [ ] App mobile para controle remoto
- [ ] Dashboard com estatísticas
- [ ] Backup automático na nuvem
- [ ] Suporte a mais tipos de combustível

---

**Desenvolvido com ❤️ para Orange Pi Zero 2W**