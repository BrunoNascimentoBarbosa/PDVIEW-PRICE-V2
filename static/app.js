// Configurações da aplicação
const CONFIG = {
    apiBase: window.location.origin,
    updateInterval: 5000, // 5 segundos para atualização automática
    messageTimeout: 3000, // 3 segundos para mensagens
};

// Estado da aplicação
let isOnline = true;
let updateTimer = null;

// Elementos DOM
const elements = {
    currentEtanol: document.getElementById('current-etanol'),
    currentGasolina: document.getElementById('current-gasolina'),
    lastUpdate: document.getElementById('last-update'),
    priceForm: document.getElementById('price-form'),
    etanolInput: document.getElementById('etanol'),
    gasolinaInput: document.getElementById('gasolina'),
    historySection: document.getElementById('history-section'),
    historyBody: document.getElementById('history-body'),
    btnHistory: document.getElementById('btn-history'),
    btnCloseHistory: document.getElementById('btn-close-history'),
    btnVideos: document.getElementById('btn-videos'),
    btnRefresh: document.getElementById('btn-refresh'),
    videoModal: document.getElementById('video-modal'),
    btnCloseModal: document.getElementById('btn-close-modal'),
    videosList: document.getElementById('videos-list'),
    uploadForm: document.getElementById('upload-form'),
    videoFile: document.getElementById('video-file'),
    uploadText: document.getElementById('upload-text'),
    message: document.getElementById('message'),
    systemStatus: document.getElementById('system-status'),
};

// Funções de Utilidade
function formatCurrency(value) {
    return `R$ ${value.toFixed(2)}`;
}

function formatDateTime(dateString) {
    const date = new Date(dateString);
    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const year = date.getFullYear();
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${day}/${month}/${year} ${hours}:${minutes}`;
}

// Funções de Mensagem
function showMessage(text, type = 'success') {
    const messageElement = elements.message;
    messageElement.textContent = text;
    messageElement.className = `message ${type} show`;

    setTimeout(() => {
        messageElement.classList.remove('show');
    }, CONFIG.messageTimeout);
}

// Funções de Status
function setOnlineStatus(status) {
    isOnline = status;
    const statusElement = elements.systemStatus;

    if (status) {
        statusElement.innerHTML = 'Status: <span>Conectado</span>';
        statusElement.classList.remove('offline');
    } else {
        statusElement.innerHTML = 'Status: <span>Offline</span>';
        statusElement.classList.add('offline');
    }
}

// Funções de API
async function fetchPrices() {
    try {
        const response = await fetch(`${CONFIG.apiBase}/api/prices`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        updatePricesDisplay(data);
        setOnlineStatus(true);
        return data;
    } catch (error) {
        console.error('Erro ao buscar preços:', error);
        setOnlineStatus(false);
        showMessage('Erro ao carregar preços', 'error');
        return null;
    }
}

async function updatePrices(etanol, gasolina) {
    try {
        // Normalizar valores: converter vírgula para ponto
        const etanolNorm = etanol.replace(',', '.');
        const gasolinaNorm = gasolina.replace(',', '.');

        const response = await fetch(`${CONFIG.apiBase}/api/prices/update`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                etanol: parseFloat(etanolNorm),
                gasolina: parseFloat(gasolinaNorm),
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Erro ao atualizar preços:', error);
        throw error;
    }
}

async function fetchHistory() {
    try {
        const response = await fetch(`${CONFIG.apiBase}/api/prices/history`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Erro ao buscar histórico:', error);
        showMessage('Erro ao carregar histórico', 'error');
        return [];
    }
}

async function fetchVideos() {
    try {
        const response = await fetch(`${CONFIG.apiBase}/api/videos`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Erro ao buscar vídeos:', error);
        showMessage('Erro ao carregar vídeos', 'error');
        return [];
    }
}

async function selectVideo(videoName) {
    try {
        const response = await fetch(`${CONFIG.apiBase}/api/videos/select`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                video_name: videoName
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Erro ao selecionar vídeo:', error);
        throw error;
    }
}

async function uploadVideo(file) {
    try {
        const formData = new FormData();
        formData.append('video', file);

        const response = await fetch(`${CONFIG.apiBase}/api/videos/upload`, {
            method: 'POST',
            body: formData,
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Erro ao enviar vídeo:', error);
        throw error;
    }
}

// Funções de UI
function updatePricesDisplay(data) {
    if (!data) return;

    elements.currentEtanol.textContent = formatCurrency(data.etanol);
    elements.currentGasolina.textContent = formatCurrency(data.gasolina);
    elements.lastUpdate.textContent = formatDateTime(data.timestamp);
}

function displayHistory(history) {
    const tbody = elements.historyBody;
    tbody.innerHTML = '';

    if (!history || history.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3">Nenhum histórico disponível</td></tr>';
        return;
    }

    history.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${formatDateTime(item.timestamp)}</td>
            <td>${formatCurrency(item.etanol)}</td>
            <td>${formatCurrency(item.gasolina)}</td>
        `;
        tbody.appendChild(row);
    });
}

function displayVideos(videos) {
    const container = elements.videosList || document.getElementById('videos-list');

    if (!container) {
        console.error('Container de vídeos não encontrado!');
        return;
    }

    container.innerHTML = '';

    if (!videos || videos.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #666;">Nenhum vídeo disponível</p>';
        return;
    }

    videos.forEach(video => {
        const videoCard = document.createElement('div');
        videoCard.className = `video-card ${video.is_active ? 'active' : ''}`;
        videoCard.innerHTML = `
            <h4>${video.name}</h4>
            <div class="video-info">${formatFileSize(video.size)}</div>
            <div class="video-status ${video.is_active ? 'active' : 'inactive'}">
                ${video.is_active ? 'ATIVO' : 'INATIVO'}
            </div>
        `;

        videoCard.addEventListener('click', () => handleVideoSelect(video.name));
        container.appendChild(videoCard);
    });
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Event Handlers
async function handleFormSubmit(event) {
    event.preventDefault();

    const etanol = elements.etanolInput.value;
    const gasolina = elements.gasolinaInput.value;

    // Validação básica
    if (!etanol || !gasolina) {
        showMessage('Por favor, preencha todos os campos', 'error');
        return;
    }

    // Desabilitar botão durante envio
    const submitButton = event.target.querySelector('button[type="submit"]');
    submitButton.disabled = true;
    submitButton.textContent = 'Atualizando...';

    try {
        await updatePrices(etanol, gasolina);
        showMessage('Preços atualizados com sucesso!', 'success');

        // Limpar formulário
        elements.priceForm.reset();

        // Atualizar display imediatamente
        await fetchPrices();
    } catch (error) {
        showMessage('Erro ao atualizar preços', 'error');
    } finally {
        submitButton.disabled = false;
        submitButton.textContent = 'Atualizar Preços';
    }
}

async function handleShowHistory() {
    elements.historySection.style.display = 'block';
    const history = await fetchHistory();
    displayHistory(history);

    // Scroll suave até o histórico
    elements.historySection.scrollIntoView({ behavior: 'smooth' });
}

function handleCloseHistory() {
    elements.historySection.style.display = 'none';
}

function handleRefresh() {
    location.reload();
}

async function handleShowVideos() {
    console.log('Abrindo modal de vídeos...');

    // Buscar o modal diretamente se não estiver nos elementos
    const modal = elements.videoModal || document.getElementById('video-modal');

    if (!modal) {
        console.error('Modal de vídeos não encontrado!');
        showMessage('Erro ao abrir modal de vídeos', 'error');
        return;
    }

    // Garantir que o modal seja exibido
    modal.style.display = 'flex';
    modal.style.visibility = 'visible';
    modal.style.opacity = '1';

    try {
        const videos = await fetchVideos();
        console.log('Vídeos carregados:', videos);
        displayVideos(videos);
    } catch (error) {
        console.error('Erro ao carregar vídeos:', error);
        showMessage('Erro ao carregar lista de vídeos', 'error');
    }
}

function handleCloseModal() {
    const modal = elements.videoModal || document.getElementById('video-modal');
    if (modal) {
        modal.style.display = 'none';
    }
}

async function handleVideoSelect(videoName) {
    try {
        await selectVideo(videoName);
        showMessage(`Vídeo "${videoName}" selecionado com sucesso!`, 'success');

        // Atualizar lista de vídeos
        const videos = await fetchVideos();
        displayVideos(videos);
    } catch (error) {
        showMessage('Erro ao selecionar vídeo', 'error');
    }
}

async function handleUploadVideo(event) {
    event.preventDefault();

    const file = elements.videoFile.files[0];
    if (!file) {
        showMessage('Por favor, selecione um arquivo', 'error');
        return;
    }

    // Validar tamanho (100MB)
    if (file.size > 100 * 1024 * 1024) {
        showMessage('Arquivo muito grande. Máximo 100MB', 'error');
        return;
    }

    // Validar formato
    const validTypes = ['video/mp4', 'video/avi', 'video/mov', 'video/webm'];
    if (!validTypes.includes(file.type)) {
        showMessage('Formato não suportado. Use MP4, AVI, MOV ou WEBM', 'error');
        return;
    }

    // Mostrar progresso
    elements.uploadText.textContent = 'Enviando...';
    const submitButton = elements.uploadForm.querySelector('button[type="submit"]');
    submitButton.disabled = true;

    try {
        await uploadVideo(file);
        showMessage('Vídeo enviado com sucesso!', 'success');

        // Limpar formulário
        elements.uploadForm.reset();

        // Atualizar lista de vídeos
        const videos = await fetchVideos();
        displayVideos(videos);
    } catch (error) {
        showMessage('Erro ao enviar vídeo', 'error');
    } finally {
        elements.uploadText.textContent = 'Enviar Vídeo';
        submitButton.disabled = false;
    }
}

// Função de inicialização
async function initialize() {
    console.log('Inicializando aplicação PDVIEW...');

    // Debug: verificar todos os elementos
    console.log('Elementos encontrados:', {
        btnVideos: !!document.getElementById('btn-videos'),
        videoModal: !!document.getElementById('video-modal'),
        uploadForm: !!document.getElementById('upload-form'),
        btnCloseModal: !!document.getElementById('btn-close-modal')
    });

    // Configurar event listeners
    elements.priceForm.addEventListener('submit', handleFormSubmit);
    elements.btnHistory.addEventListener('click', handleShowHistory);
    elements.btnCloseHistory.addEventListener('click', handleCloseHistory);

    // Verificar se o botão de vídeos existe
    const btnVideos = document.getElementById('btn-videos');
    if (btnVideos) {
        console.log('Botão de vídeos encontrado, registrando listener...');
        btnVideos.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('Botão de vídeos clicado!');
            handleShowVideos();
        });
    } else {
        console.error('ERRO: Botão btn-videos não encontrado no DOM!');
        // Tentar novamente após o DOM estar completamente carregado
        setTimeout(() => {
            const btnVideosRetry = document.getElementById('btn-videos');
            if (btnVideosRetry) {
                console.log('Botão de vídeos encontrado na segunda tentativa!');
                btnVideosRetry.addEventListener('click', function(e) {
                    e.preventDefault();
                    console.log('Botão de vídeos clicado (retry)!');
                    handleShowVideos();
                });
            } else {
                console.error('ERRO: Botão btn-videos não encontrado mesmo após retry!');
            }
        }, 1000);
    }

    // Configurar botão fechar modal
    const btnCloseModal = document.getElementById('btn-close-modal');
    if (btnCloseModal) {
        btnCloseModal.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('Fechando modal...');
            handleCloseModal();
        });
    }

    if (elements.uploadForm) {
        elements.uploadForm.addEventListener('submit', handleUploadVideo);
    }

    elements.btnRefresh.addEventListener('click', handleRefresh);

    // Fechar modal ao clicar fora
    if (elements.videoModal) {
        elements.videoModal.addEventListener('click', (e) => {
            if (e.target === elements.videoModal) {
                handleCloseModal();
            }
        });
    }

    // Drag and drop para upload
    if (elements.uploadForm) {
        const uploadArea = elements.uploadForm.querySelector('.upload-area');
        if (uploadArea) {
            uploadArea.addEventListener('dragover', (e) => {
                e.preventDefault();
                uploadArea.classList.add('dragover');
            });

            uploadArea.addEventListener('dragleave', () => {
                uploadArea.classList.remove('dragover');
            });

            uploadArea.addEventListener('drop', (e) => {
                e.preventDefault();
                uploadArea.classList.remove('dragover');

                const files = e.dataTransfer.files;
                if (files.length > 0) {
                    elements.videoFile.files = files;
                }
            });
        }
    }

    // Validação em tempo real dos inputs
    [elements.etanolInput, elements.gasolinaInput].forEach(input => {
        input.addEventListener('input', (e) => {
            // Permitir apenas números e ponto decimal
            let value = e.target.value;

            // Substituir vírgula por ponto automaticamente
            value = value.replace(',', '.');

            // Validar formato: números com até 2 casas decimais
            const regex = /^\d*\.?\d{0,2}$/;
            if (!regex.test(value)) {
                e.target.value = e.target.value.slice(0, -1);
            } else {
                e.target.value = value;
            }
        });
    });

    // Carregar preços iniciais
    await fetchPrices();

    // Configurar atualização automática
    updateTimer = setInterval(() => {
        fetchPrices();
    }, CONFIG.updateInterval);

    // Verificar conectividade
    window.addEventListener('online', () => {
        setOnlineStatus(true);
        fetchPrices();
    });

    window.addEventListener('offline', () => {
        setOnlineStatus(false);
    });

    // Limpar timer ao sair da página
    window.addEventListener('beforeunload', () => {
        if (updateTimer) {
            clearInterval(updateTimer);
        }
    });

    // Atalhos de teclado
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + R para atualizar
        if ((e.ctrlKey || e.metaKey) && e.key === 'r') {
            e.preventDefault();
            fetchPrices();
            showMessage('Dados atualizados', 'success');
        }

        // Ctrl/Cmd + H para histórico
        if ((e.ctrlKey || e.metaKey) && e.key === 'h') {
            e.preventDefault();
            handleShowHistory();
        }

        // ESC para fechar histórico
        if (e.key === 'Escape' && elements.historySection.style.display !== 'none') {
            handleCloseHistory();
        }
    });

    console.log('Aplicação inicializada com sucesso');
}

// Inicializar quando DOM estiver pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
} else {
    initialize();
}

// Service Worker comentado por enquanto (causando erro 404)
// if ('serviceWorker' in navigator) {
//     navigator.serviceWorker.register('/sw.js').catch(err => {
//         console.log('Service Worker não registrado:', err);
//     });
// }