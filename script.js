// ============ NAVEGACIÓN ENTRE VISTAS ============
const navIcons = document.querySelectorAll('.nav-icon[data-view]');
const views = document.querySelectorAll('.view');

function switchView(viewId) {
  views.forEach(v => v.classList.toggle('active', v.id === `view-${viewId}`));
  navIcons.forEach(btn => btn.classList.toggle('active', btn.dataset.view === viewId));
}

navIcons.forEach(btn => {
  btn.addEventListener('click', () => switchView(btn.dataset.view));
});

// Permite que enlaces internos (ej. "Ver lista →" del asistente IA) cambien de vista
document.querySelectorAll('[data-view-link]').forEach(link => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    switchView(link.dataset.viewLink);
  });
});

function showToast(message) {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => toast.classList.remove('show'), 2200);
}

// ============ BANDEJA DE CONCILIACIÓN ============
const itemsTable = document.getElementById('items-table');
const pendingCountEl = document.getElementById('pending-count');
let pendingCount = 23;

function updatePendingCount(delta) {
  pendingCount = Math.max(0, pendingCount + delta);
  pendingCountEl.textContent = `${pendingCount} pendientes`;
}

itemsTable.addEventListener('click', (e) => {
  const row = e.target.closest('tr[data-row]');
  if (!row || row.classList.contains('row-resolved')) return;

  if (e.target.classList.contains('act-emparejar')) {
    row.classList.add('row-resolved');
    updatePendingCount(-1);
    showToast('Ítem emparejado correctamente');
  } else if (e.target.classList.contains('act-crear')) {
    row.classList.add('row-resolved');
    updatePendingCount(-1);
    showToast('Nuevo producto creado desde el ítem');
  } else if (e.target.classList.contains('act-buscar')) {
    showToast('Abriendo buscador de productos…');
  }
});

document.getElementById('btn-validar-todo').addEventListener('click', () => {
  document.querySelectorAll('#items-table tr[data-row]:not(.row-resolved)').forEach(row => {
    row.classList.add('row-resolved');
  });
  updatePendingCount(-pendingCount);
  showToast('Todos los ítems fueron validados');
});

// ============ ASISTENTE IA (MCP) ============
const aiForm = document.getElementById('ai-form');
const aiInput = document.getElementById('ai-input');
const aiMessages = document.getElementById('ai-messages');

const aiResponses = [
  { match: /90 d|no se venden|inventario muerto/i, reply: 'Hay 12 ítems sin movimiento &gt;90 días, valor total $2,140. <a href="#" data-view-link="directorio">Ver lista →</a>' },
  { match: /reponer|reorden|stock/i, reply: 'Detecté 2 productos bajo el punto de reorden: Pepsi 350ml y Arroz 1kg. <a href="#" data-view-link="directorio">Ver directorio →</a>' },
  { match: /valor|valoriz/i, reply: 'La valorización total del inventario es de $128,450 (USD, costo local).' },
];

function addBubble(text, sender) {
  const bubble = document.createElement('div');
  bubble.className = `ai-bubble ai-${sender}`;
  bubble.innerHTML = text;
  aiMessages.appendChild(bubble);
  aiMessages.scrollTop = aiMessages.scrollHeight;
  bubble.querySelectorAll('[data-view-link]').forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      switchView(link.dataset.viewLink);
    });
  });
}

aiForm.addEventListener('submit', (e) => {
  e.preventDefault();
  const question = aiInput.value.trim();
  if (!question) return;
  addBubble(question, 'user');
  aiInput.value = '';

  setTimeout(() => {
    const found = aiResponses.find(r => r.match.test(question));
    addBubble(found ? found.reply : 'Consultando el modelo de datos… no encontré una métrica exacta para eso, pero puedo revisar el directorio de inventario contigo.', 'bot');
  }, 500);
});

// ============ DIRECTORIO: SELECCIÓN EN BLOQUE ============
const checkAll = document.getElementById('check-all');
const rowChecks = document.querySelectorAll('.row-check');
const bulkBar = document.getElementById('bulk-bar');
const bulkCount = document.getElementById('bulk-count');

function refreshBulkBar() {
  const checked = document.querySelectorAll('.row-check:checked').length;
  bulkBar.hidden = checked === 0;
  bulkCount.textContent = `${checked} seleccionado${checked === 1 ? '' : 's'}`;
  checkAll.checked = checked === rowChecks.length;
}

checkAll.addEventListener('change', () => {
  rowChecks.forEach(cb => cb.checked = checkAll.checked);
  refreshBulkBar();
});

rowChecks.forEach(cb => cb.addEventListener('change', refreshBulkBar));

document.getElementById('bulk-cancel').addEventListener('click', () => {
  rowChecks.forEach(cb => cb.checked = false);
  checkAll.checked = false;
  refreshBulkBar();
});

// ============ CONFIGURACIÓN: TABS ============
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    // En este prototipo solo la pestaña "Categorías" tiene contenido construido
    if (tab.dataset.tab !== 'categorias') {
      showToast(`Sección "${tab.textContent}" — pendiente de maquetar`);
    }
  });
});

// ============ CONFIGURACIÓN: ÁRBOL DE CATEGORÍAS ============
const editName = document.getElementById('edit-name');
const editNameInput = document.getElementById('edit-name-input');
const editParentInput = document.getElementById('edit-parent-input');
const editCount = document.getElementById('edit-count');

document.querySelectorAll('.tree-node').forEach(node => {
  node.addEventListener('click', (e) => {
    e.stopPropagation();
    document.querySelectorAll('.tree-node').forEach(n => n.classList.remove('selected'));
    node.classList.add('selected');

    const name = node.dataset.name;
    editName.textContent = name;
    editNameInput.value = name;
    editParentInput.value = node.dataset.parent.replace(/&gt;/g, '>');
    editCount.textContent = node.dataset.count;
  });
});

// Expandir / colapsar nodos con hijos (▾ / ▸)
document.querySelectorAll('.tree-toggle').forEach(toggle => {
  toggle.addEventListener('click', (e) => {
    e.stopPropagation();
    const li = toggle.parentElement;
    const childUl = li.querySelector(':scope > ul');
    if (!childUl) return;
    const collapsed = childUl.style.display === 'none';
    childUl.style.display = collapsed ? '' : 'none';
    toggle.textContent = collapsed ? '▾' : '▸';
  });
});

document.getElementById('btn-guardar').addEventListener('click', () => {
  editName.textContent = editNameInput.value || editName.textContent;
  showToast('Categoría guardada');
});

document.getElementById('btn-eliminar').addEventListener('click', () => {
  showToast('Categoría eliminada (simulado)');
});

document.getElementById('btn-add-root').addEventListener('click', () => {
  showToast('Función "Agregar categoría raíz" — próximo paso de implementación');
});
