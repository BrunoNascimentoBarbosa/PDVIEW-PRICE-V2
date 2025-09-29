package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

type Price struct {
	ID        int       `json:"id"`
	Etanol    float64   `json:"etanol"`
	Gasolina  float64   `json:"gasolina"`
	Timestamp time.Time `json:"timestamp"`
}

type PriceUpdate struct {
	Etanol   float64 `json:"etanol"`
	Gasolina float64 `json:"gasolina"`
}

type VideoInfo struct {
	Name     string `json:"name"`
	Path     string `json:"path"`
	Size     int64  `json:"size"`
	IsActive bool   `json:"is_active"`
}

type VideoSelection struct {
	VideoName string `json:"video_name"`
}

var db *sql.DB
var activeVideo string = "base.mp4" // vídeo padrão

func initDB() *sql.DB {
	// Criar diretório data se não existir
	if err := os.MkdirAll("data", 0755); err != nil {
		log.Fatal("Erro ao criar diretório data:", err)
	}

	database, err := sql.Open("sqlite3", "./data/prices.db")
	if err != nil {
		log.Fatal("Erro ao abrir banco de dados:", err)
	}

	// Criar tabela se não existir
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS prices (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		etanol REAL NOT NULL,
		gasolina REAL NOT NULL,
		timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	if _, err := database.Exec(createTableSQL); err != nil {
		log.Fatal("Erro ao criar tabela:", err)
	}

	// Inserir preço inicial se a tabela estiver vazia
	var count int
	err = database.QueryRow("SELECT COUNT(*) FROM prices").Scan(&count)
	if err != nil {
		log.Fatal("Erro ao verificar tabela:", err)
	}

	if count == 0 {
		_, err = database.Exec("INSERT INTO prices (etanol, gasolina) VALUES (?, ?)", 3.99, 5.99)
		if err != nil {
			log.Fatal("Erro ao inserir preços iniciais:", err)
		}
		log.Println("Preços iniciais inseridos: Etanol R$ 3.99, Gasolina R$ 5.99")
	}

	return database
}

func handleGetPrices(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	// Buscar último preço
	var price Price
	err := db.QueryRow(`
		SELECT id, etanol, gasolina, timestamp
		FROM prices
		ORDER BY timestamp DESC
		LIMIT 1
	`).Scan(&price.ID, &price.Etanol, &price.Gasolina, &price.Timestamp)

	if err != nil {
		http.Error(w, "Erro ao buscar preços", http.StatusInternalServerError)
		log.Println("Erro ao buscar preços:", err)
		return
	}

	// Adicionar headers de cache para reduzir requisições
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "max-age=10")

	json.NewEncoder(w).Encode(price)
}

func handleUpdatePrices(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	var priceUpdate PriceUpdate
	if err := json.NewDecoder(r.Body).Decode(&priceUpdate); err != nil {
		http.Error(w, "Dados inválidos", http.StatusBadRequest)
		return
	}

	// Validar preços
	if priceUpdate.Etanol <= 0 || priceUpdate.Gasolina <= 0 {
		http.Error(w, "Preços devem ser maiores que zero", http.StatusBadRequest)
		return
	}

	// Inserir novo preço
	result, err := db.Exec(
		"INSERT INTO prices (etanol, gasolina) VALUES (?, ?)",
		priceUpdate.Etanol, priceUpdate.Gasolina,
	)
	if err != nil {
		http.Error(w, "Erro ao salvar preços", http.StatusInternalServerError)
		log.Println("Erro ao salvar preços:", err)
		return
	}

	lastID, _ := result.LastInsertId()
	log.Printf("Preços atualizados: Etanol R$ %.2f, Gasolina R$ %.2f (ID: %d)",
		priceUpdate.Etanol, priceUpdate.Gasolina, lastID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Preços atualizados com sucesso",
		"id":      lastID,
	})
}

func handlePriceHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	rows, err := db.Query(`
		SELECT id, etanol, gasolina, timestamp
		FROM prices
		ORDER BY timestamp DESC
		LIMIT 100
	`)
	if err != nil {
		http.Error(w, "Erro ao buscar histórico", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var prices []Price
	for rows.Next() {
		var p Price
		if err := rows.Scan(&p.ID, &p.Etanol, &p.Gasolina, &p.Timestamp); err != nil {
			continue
		}
		prices = append(prices, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(prices)
}

func handleListVideos(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	videosDir := "./videos"
	files, err := os.ReadDir(videosDir)
	if err != nil {
		http.Error(w, "Erro ao ler diretório de vídeos", http.StatusInternalServerError)
		return
	}

	var videos []VideoInfo
	for _, file := range files {
		if file.IsDir() {
			continue
		}

		// Verificar se é arquivo de vídeo
		ext := filepath.Ext(file.Name())
		if ext != ".mp4" && ext != ".avi" && ext != ".mov" && ext != ".webm" {
			continue
		}

		info, err := file.Info()
		if err != nil {
			continue
		}

		video := VideoInfo{
			Name:     file.Name(),
			Path:     "/videos/" + file.Name(),
			Size:     info.Size(),
			IsActive: file.Name() == activeVideo,
		}
		videos = append(videos, video)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(videos)
}

func handleSelectVideo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	var selection VideoSelection
	if err := json.NewDecoder(r.Body).Decode(&selection); err != nil {
		http.Error(w, "Dados inválidos", http.StatusBadRequest)
		return
	}

	// Verificar se o arquivo existe
	videoPath := filepath.Join("./videos", selection.VideoName)
	if _, err := os.Stat(videoPath); os.IsNotExist(err) {
		http.Error(w, "Vídeo não encontrado", http.StatusNotFound)
		return
	}

	// Atualizar vídeo ativo
	activeVideo = selection.VideoName
	log.Printf("Vídeo ativo alterado para: %s", activeVideo)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":      true,
		"message":      "Vídeo selecionado com sucesso",
		"active_video": activeVideo,
	})
}

func handleUploadVideo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	// Log detalhado da requisição incluindo IP de origem
	log.Printf("Upload iniciado - IP: %s, User-Agent: %s, Content-Type: %s, Content-Length: %s",
		r.RemoteAddr, r.UserAgent(), r.Header.Get("Content-Type"), r.Header.Get("Content-Length"))

	// Configurar tamanho máximo de memória e fazer parse
	r.Body = http.MaxBytesReader(w, r.Body, 100<<20) // 100MB
	err := r.ParseMultipartForm(32 << 20) // 32MB em memória, resto em disco
	if err != nil {
		log.Printf("Erro ao fazer parse do formulário multipart: %v", err)
		http.Error(w, "Erro ao processar formulário: "+err.Error(), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("video")
	if err != nil {
		log.Printf("Erro ao receber arquivo 'video': %v", err)
		http.Error(w, "Erro ao receber arquivo: "+err.Error(), http.StatusBadRequest)
		return
	}
	defer file.Close()

	log.Printf("Arquivo recebido: %s (tamanho: %d bytes)", handler.Filename, handler.Size)

	// Verificar extensão (case-insensitive)
	ext := strings.ToLower(filepath.Ext(handler.Filename))
	if ext != ".mp4" && ext != ".avi" && ext != ".mov" && ext != ".webm" {
		log.Printf("Formato de vídeo não suportado: %s", ext)
		http.Error(w, "Formato de vídeo não suportado. Use MP4, AVI, MOV ou WEBM", http.StatusBadRequest)
		return
	}

	// Criar arquivo de destino
	videoPath := filepath.Join("./videos", handler.Filename)
	dst, err := os.Create(videoPath)
	if err != nil {
		log.Printf("Erro ao criar arquivo de destino %s: %v", videoPath, err)
		http.Error(w, "Erro ao salvar arquivo no servidor", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	// Copiar arquivo com buffer para melhor performance
	written, err := io.Copy(dst, file)
	if err != nil {
		log.Printf("Erro ao copiar arquivo: %v", err)
		// Tentar remover arquivo parcialmente salvo
		os.Remove(videoPath)
		http.Error(w, "Erro ao salvar arquivo completo", http.StatusInternalServerError)
		return
	}

	log.Printf("Vídeo enviado com sucesso: %s (%.2f MB)", handler.Filename, float64(written)/(1024*1024))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":  true,
		"message":  "Vídeo enviado com sucesso",
		"filename": handler.Filename,
	})
}

func handleActiveVideo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"active_video": activeVideo,
		"video_path":   "/videos/" + activeVideo,
	})
}

func handleDeleteVideo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete && r.Method != http.MethodPost {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	var selection VideoSelection
	if err := json.NewDecoder(r.Body).Decode(&selection); err != nil {
		http.Error(w, "Dados inválidos", http.StatusBadRequest)
		return
	}

	// Não permitir excluir o vídeo base.mp4
	if selection.VideoName == "base.mp4" {
		http.Error(w, "Não é permitido excluir o vídeo base", http.StatusForbidden)
		return
	}

	// Não permitir excluir o vídeo ativo
	if selection.VideoName == activeVideo {
		http.Error(w, "Não é permitido excluir o vídeo ativo. Selecione outro vídeo antes.", http.StatusForbidden)
		return
	}

	// Verificar se o arquivo existe
	videoPath := filepath.Join("./videos", selection.VideoName)
	if _, err := os.Stat(videoPath); os.IsNotExist(err) {
		http.Error(w, "Vídeo não encontrado", http.StatusNotFound)
		return
	}

	// Excluir o arquivo
	if err := os.Remove(videoPath); err != nil {
		log.Printf("Erro ao excluir vídeo %s: %v", selection.VideoName, err)
		http.Error(w, "Erro ao excluir vídeo", http.StatusInternalServerError)
		return
	}

	log.Printf("Vídeo %s excluído com sucesso", selection.VideoName)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": fmt.Sprintf("Vídeo %s excluído com sucesso", selection.VideoName),
	})
}

func enableCORS(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Permitir qualquer origem (necessário para acesso via WiFi de diferentes dispositivos)
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Accept, Authorization, X-Requested-With")
		w.Header().Set("Access-Control-Max-Age", "3600")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		// Para requisições OPTIONS (preflight), retornar sucesso imediatamente
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "localhost"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil && !strings.HasPrefix(ipnet.IP.String(), "169.254") {
				return ipnet.IP.String()
			}
		}
	}
	return "localhost"
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s %v", r.RemoteAddr, r.Method, r.URL.Path, time.Since(start))
	})
}

func main() {
	// Inicializar banco de dados
	db = initDB()
	defer db.Close()

	// Configurar rotas
	mux := http.NewServeMux()

	// API endpoints
	mux.HandleFunc("/api/prices", enableCORS(handleGetPrices))
	mux.HandleFunc("/api/prices/update", enableCORS(handleUpdatePrices))
	mux.HandleFunc("/api/prices/history", enableCORS(handlePriceHistory))

	// Video endpoints
	mux.HandleFunc("/api/videos", enableCORS(handleListVideos))
	mux.HandleFunc("/api/videos/select", enableCORS(handleSelectVideo))
	mux.HandleFunc("/api/videos/upload", enableCORS(handleUploadVideo))
	mux.HandleFunc("/api/videos/active", enableCORS(handleActiveVideo))
	mux.HandleFunc("/api/videos/delete", enableCORS(handleDeleteVideo))

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	})

	// Servir arquivos estáticos
	fileServer := http.FileServer(http.Dir("./static/"))
	mux.Handle("/", fileServer)

	// Servir videos
	videoServer := http.FileServer(http.Dir("./videos/"))
	mux.Handle("/videos/", http.StripPrefix("/videos/", videoServer))

	// Configurar servidor com timeouts otimizados para uploads via WiFi
	server := &http.Server{
		Addr:              "0.0.0.0:8080",
		Handler:           loggingMiddleware(mux),
		ReadTimeout:       60 * time.Second,  // Aumentado para uploads grandes via WiFi
		WriteTimeout:      60 * time.Second,  // Aumentado para uploads grandes via WiFi
		IdleTimeout:       120 * time.Second, // Aumentado para conexões lentas
		MaxHeaderBytes:    1 << 20,           // 1 MB para headers
	}

	port := ":8080"
	localIP := getLocalIP()

	log.Printf("PDVIEW Server iniciado na porta %s", port)
	log.Printf("Acesso local: http://localhost%s", port)
	log.Printf("Acesso via WiFi: http://%s%s", localIP, port)
	log.Printf("Interface de configuração: http://%s%s", localIP, port)
	log.Printf("Player: http://%s%s/player.html", localIP, port)

	if err := server.ListenAndServe(); err != nil {
		log.Fatal("Erro ao iniciar servidor:", err)
	}
}