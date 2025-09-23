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
    btnRefresh: document.getElementById('btn-refresh'),
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
        const response = await fetch(`${CONFIG.apiBase}/api/prices/update`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                etanol: parseFloat(etanol),
                gasolina: parseFloat(gasolina),
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

// Funções de UI
function updatePricesDisplay(data) {
    if (!data) return;

    elements.currentEtanol.textContent = formatCurrency(data.etanol);
    elements.currentGasolina.textContent = formatCurrency(data.gasolina);
    elements.lastUpdate.textContent = formatDateTime(data.timestamp);

    // Atualizar inputs com valores atuais (para facilitar edição)
    if (!elements.etanolInput.value) {
        elements.etanolInput.value = data.etanol.toFixed(2);
    }
    if (!elements.gasolinaInput.value) {
        elements.gasolinaInput.value = data.gasolina.toFixed(2);
    }
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

// Função de inicialização
async function initialize() {
    console.log('Inicializando aplicação PDVIEW...');

    // Configurar event listeners
    elements.priceForm.addEventListener('submit', handleFormSubmit);
    elements.btnHistory.addEventListener('click', handleShowHistory);
    elements.btnCloseHistory.addEventListener('click', handleCloseHistory);
    elements.btnRefresh.addEventListener('click', handleRefresh);

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

// Service Worker para funcionar offline (opcional)
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(err => {
        console.log('Service Worker não registrado:', err);
    });
}