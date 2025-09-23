# 🚀 INSTALAÇÃO SUPER FÁCIL - PDVIEW

## Para Usuários Leigos - Um Comando Só!

### 📋 Pré-requisitos
- Orange Pi ou Raspberry Pi conectado à internet
- Sistema Armbian, Ubuntu ou Raspbian
- Acesso SSH ou terminal

### ⚡ Instalação Automática (1 COMANDO)

**Copie e cole este comando no terminal do seu Orange Pi:**

```bash
curl -sSL https://raw.githubusercontent.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2/main/setup.sh | bash
```

**OU baixe e execute:**

```bash
wget https://raw.githubusercontent.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2/main/setup.sh
bash setup.sh
```

### ✨ O que o script faz automaticamente:

1. ✅ **Atualiza o sistema**
2. ✅ **Instala todas as dependências** (curl, git, sqlite3, ffmpeg, etc.)
3. ✅ **Instala Go** (linguagem de programação)
4. ✅ **Baixa o projeto** do GitHub
5. ✅ **Compila** o programa
6. ✅ **Configura o serviço** para iniciar automaticamente
7. ✅ **Libera porta** no firewall
8. ✅ **Inicia o sistema**
9. ✅ **Cria atalhos** de controle

### 🎯 Após a instalação:

O script mostrará algo assim:
```
🎉 INSTALAÇÃO CONCLUÍDA! 🎉

📍 INFORMAÇÕES DE ACESSO:
   🌐 Interface Admin: http://192.168.1.100:8080
   📺 Player: http://192.168.1.100:player.html

🎛️  COMANDOS ÚTEIS:
   ./control.sh start    # Iniciar
   ./control.sh stop     # Parar
   ./control.sh restart  # Reiniciar
   ./control.sh status   # Ver status
```

### 🌐 Como usar:

1. **Abra o navegador** no seu celular/computador
2. **Digite o IP** mostrado na tela (ex: http://192.168.1.100:8080)
3. **Configure os preços** na interface
4. **Abra o player** em /player.html para ver a exibição

### 🔧 Comandos básicos:

```bash
# Ir para a pasta do programa
cd ~/pdview

# Controlar o serviço
./control.sh start     # Iniciar
./control.sh stop      # Parar
./control.sh restart   # Reiniciar
./control.sh status    # Ver se está rodando
./control.sh logs      # Ver logs do programa
./control.sh update    # Atualizar para nova versão
```

### 🎥 Adicionando seu vídeo:

1. **Otimize o vídeo** (recomendado):
   ```bash
   cd ~/pdview
   ./optimize-video.sh seu-video.mp4
   ```

2. **Ou copie direto** para a pasta:
   ```bash
   cp seu-video.mp4 ~/pdview/videos/base.mp4
   ```

3. **Reinicie** o serviço:
   ```bash
   ./control.sh restart
   ```

### 🆘 Problemas?

**Se algo não funcionar:**

```bash
# Ver logs de erro
./control.sh logs

# Ver status detalhado
./control.sh status

# Tentar reinstalar
curl -sSL https://raw.githubusercontent.com/BrunoNascimentoBarbosa/PDVIEW-PRICE-V2/main/setup.sh | bash
```

**Logs do sistema:**
```bash
sudo journalctl -u pdview -f
```

### 🔄 Atualização:

```bash
cd ~/pdview
./control.sh update
```

### 📱 Acesso Remoto:

- **Interface**: `http://IP-DO-ORANGE-PI:8080`
- **Player**: `http://IP-DO-ORANGE-PI:8080/player.html`

*Para descobrir o IP: `hostname -I | awk '{print $1}'`*

---

## 🎯 É isso! Um comando e está tudo funcionando!

**Suporte:** Abra uma issue no GitHub se tiver problemas.