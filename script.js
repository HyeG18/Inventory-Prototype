// ============ STATE ============
let state = {
  conciliationQueue: [],
  categoryTree: [],
  inventoryDirectory: [],
  dashboardMetrics: null,
  dashboardMetricsByRange: {},
  currentRange: 'ago_2026',
  locationTree: [],
  unitOfMeasures: [],
  productTypes: [],
  reorderPolicies: [],
  selectedCategoryId: null,
  selectedLocationId: null,
  selectedProduct: null,
  selectedMacCategoryId: null,
  rpPage: 1,
  rpSearch: '',
  editingPolicyId: null,
};

// ============ MOCK DATA LOADER ============
async function loadMockData() {
  try {
    const res = await fetch('./data/mockData.json');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();

    state.conciliationQueue = data.conciliationQueue || [];
    state.categoryTree = data.categoryTree || [];
    state.inventoryDirectory = data.inventoryDirectory || [];
    state.dashboardMetrics = data.dashboardMetrics || {};
    state.dashboardMetricsByRange = data.dashboardMetricsByRange || {};
    state.locationTree = data.locationTree || [];
    state.unitOfMeasures = data.unitOfMeasures || [];
    state.productTypes = data.productTypes || [];
    state.reorderPolicies = data.reorderPolicies || [];

    renderConciliationTable(state.conciliationQueue);
    renderDirectoryTable(state.inventoryDirectory, state.categoryTree);
    renderCategoryTree(state.categoryTree);
    renderDashboardKPIs(state.dashboardMetrics);
    renderReorderTable(state.dashboardMetrics.reorderSuggestions);
    renderDeadStockTable(state.dashboardMetrics.deadStock);
    updatePendingCount(state.conciliationQueue.length);

    populateCrearModalSelects();
    renderLocationTree();
    renderReorderPolicies();

    bindBulkBarEvents();
    bindBuscarModal();
  } catch (err) {
    console.error('Error loading mock data:', err);
    showToast('Error al cargar datos. Ver consola.');
  }
}

// ============ HELPERS ============
function getCategoryPath(categoryId, tree) {
  if (!categoryId) return null;
  const map = {};
  tree.forEach(c => { map[c.categoryId] = c; });
  const parts = [];
  let current = map[categoryId];
  while (current) {
    parts.unshift(current.name);
    current = current.parentId ? map[current.parentId] : null;
  }
  return parts.join(' > ');
}

function getLocationPath(locationId, tree) {
  if (!locationId) return null;
  const map = {};
  tree.forEach(l => { map[l.locationId] = l; });
  const parts = [];
  let current = map[locationId];
  while (current) {
    parts.unshift(current.name);
    current = current.parentId ? map[current.parentId] : null;
  }
  return parts.join(' > ');
}

function countProductsByCategory(categoryId, directory) {
  return directory.filter(p => p.categoryId === categoryId).length;
}

function countLocationsByParent(parentId, tree) {
  return tree.filter(l => l.parentId === parentId).length;
}

function confidenceClass(score) {
  if (score < 50) return 'conf-red';
  if (score < 80) return 'conf-amber';
  return '';
}

// ============ MODAL HELPERS ============
function openModal(id) {
  document.getElementById(id).classList.add('open');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}
function closeAllModals() {
  document.querySelectorAll('.modal-backdrop.open').forEach(m => m.classList.remove('open'));
}

// ============ RENDER: CONCILIATION TABLE ============
function renderConciliationTable(items) {
  const tbody = document.getElementById('conciliation-tbody');
  tbody.innerHTML = items.map(item => `
    <tr data-row data-item-id="${item.id}">
      <td>${item.invoiceLineText}</td>
      <td>→ ${item.suggestedProductName}</td>
      <td><span class="confidence ${confidenceClass(item.confidenceScore)}">${item.confidenceScore}%</span></td>
      <td class="actions-cell">
        <button class="btn btn-sm btn-primary act-emparejar">Emparejar</button>
        <button class="btn btn-sm btn-outline act-crear">Crear Nuevo</button>
        <button class="btn btn-sm btn-ghost act-buscar">Buscar…</button>
      </td>
    </tr>
  `).join('');
}

// ============ RENDER: DIRECTORY TABLE ============
function renderDirectoryTable(directory, tree) {
  const tbody = document.getElementById('directory-tbody');
  tbody.innerHTML = directory.map(product => {
    const categoryPath = getCategoryPath(product.categoryId, tree);
    const colorClass = product.isActive ? 'tag-green' : 'tag-gray';
    const categoryHtml = categoryPath
      ? categoryPath
      : '<span class="tag-warning">SIN CATEGORIZAR</span>';
    return `
      <tr>
        <td class="th-check"><input type="checkbox" class="row-check"></td>
        <td><span class="color-tag ${colorClass}"></span>${product.name}</td>
        <td>${categoryHtml}</td>
        <td>${product.uom}</td>
        <td>${product.balance}</td>
        <td>${product.preferredSupplier}</td>
      </tr>
    `;
  }).join('');
  bindDirectoryRowEvents();
}

// ============ RENDER: CATEGORY TREE ============
function buildTreeNodes(tree, parentId = null) {
  const roots = tree.filter(c => c.parentId === parentId);
  return roots.map(cat => {
    const children = tree.filter(c => c.parentId === cat.categoryId);
    const hasChildren = children.length > 0;
    const count = countProductsByCategory(cat.categoryId, state.inventoryDirectory);
    const toggleSymbol = hasChildren ? '▸' : '○';
    const childUl = hasChildren
      ? `<ul>${buildTreeNodes(tree, cat.categoryId)}</ul>`
      : '';
    return `<li class="tree-node" data-name="${cat.name}" data-category-id="${cat.categoryId}" data-parent="${cat.parentId || '—'}" data-count="${count}">
      <span class="tree-toggle">${toggleSymbol}</span> ${cat.name}
      ${childUl}
    </li>`;
  }).join('');
}

function renderCategoryTree(tree) {
  const ul = document.getElementById('category-tree');
  if (!tree || tree.length === 0) {
    ul.innerHTML = '<li class="doc-note">No hay categorías registradas.</li>';
    return;
  }
  ul.innerHTML = buildTreeNodes(tree);
  bindTreeEvents();
}

// ============ RENDER: LOCATION TREE ============
function buildLocationNodes(tree, parentId = null) {
  const roots = tree.filter(l => l.parentId === parentId);
  return roots.map(loc => {
    const children = tree.filter(l => l.parentId === loc.locationId);
    const hasChildren = children.length > 0;
    const count = countLocationsByParent(loc.locationId, tree);
    const toggleSymbol = hasChildren ? '▸' : '○';
    const childUl = hasChildren
      ? `<ul>${buildLocationNodes(tree, loc.locationId)}</ul>`
      : '';
    return `<li class="tree-node" data-name="${loc.name}" data-location-id="${loc.locationId}" data-parent="${loc.parentId || '—'}" data-count="${count}">
      <span class="tree-toggle">${toggleSymbol}</span> ${loc.name}
      ${childUl}
    </li>`;
  }).join('');
}

function renderLocationTree() {
  const ul = document.getElementById('location-tree');
  if (!state.locationTree || state.locationTree.length === 0) {
    ul.innerHTML = '<li class="doc-note">No hay ubicaciones registradas.</li>';
    return;
  }
  ul.innerHTML = buildLocationNodes(state.locationTree);
  bindLocationTreeEvents();
}

// ============ RENDER: DASHBOARD KPIs ============
function renderDashboardKPIs(metrics) {
  if (!metrics) return;
  const fmt = (n) => n == null ? '—' : n.toLocaleString('es-CO');
  document.getElementById('kpi-valuation').textContent = `$${fmt(metrics.totalValuation)}`;
  document.getElementById('kpi-currency').textContent = metrics.currency || '—';
  document.getElementById('kpi-active-items').textContent = fmt(metrics.activeItems);
  document.getElementById('kpi-alerts').textContent = metrics.criticalStockAlerts ?? '—';
}

// ============ RENDER: REORDER TABLE ============
function renderReorderTable(rows) {
  if (!rows || !Array.isArray(rows)) rows = [];
  const tbody = document.getElementById('reorder-tbody');
  tbody.innerHTML = rows.map(r => `
    <tr>
      <td>${r.productName}</td>
      <td>${r.currentStock}</td>
      <td>${r.reorderLevel}</td>
      <td>${r.suggestedQty}</td>
    </tr>
  `).join('');
}

// ============ RENDER: DEAD STOCK TABLE ============
function renderDeadStockTable(rows) {
  if (!rows || !Array.isArray(rows)) rows = [];
  const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
  const tbody = document.getElementById('deadstock-tbody');
  tbody.innerHTML = rows.map(r => {
    let formatted = r.lastSaleDate || '';
    if (formatted && formatted.includes('-')) {
      const [year, month, day] = formatted.split('-');
      const mesIdx = parseInt(month, 10) - 1;
      formatted = `${parseInt(day, 10)} ${meses[mesIdx] || '??'} ${year}`;
    }
    return `
      <tr>
        <td>${r.productName}</td>
        <td>${formatted}</td>
        <td>${r.daysSinceMovement}</td>
        <td>$${r.value}</td>
      </tr>
    `;
  }).join('');
}

// ============ RENDER: REORDER POLICIES ============
const RP_ITEMS_PER_PAGE = 4;

function renderReorderPolicies() {
  const filtered = state.reorderPolicies.filter(p =>
    p.productName.toLowerCase().includes(state.rpSearch.toLowerCase())
  );
  const totalPages = Math.ceil(filtered.length / RP_ITEMS_PER_PAGE) || 1;
  if (state.rpPage > totalPages) state.rpPage = totalPages;
  const start = (state.rpPage - 1) * RP_ITEMS_PER_PAGE;
  const pageItems = filtered.slice(start, start + RP_ITEMS_PER_PAGE);

  const lista = document.getElementById('rp-lista');
  lista.innerHTML = pageItems.map(p => `
    <div class="policy-row">
      <div class="policy-info">
        <div class="policy-name">${p.productName}</div>
        <div class="policy-detail">Nivel reorden: ${p.reorderLevel} · Cantidad: ${p.reorderQuantity}</div>
      </div>
      <label class="toggle-switch">
        <input type="checkbox" ${p.isActive ? 'checked' : ''} data-policy-id="${p.policyId}">
        <span class="toggle-slider"></span>
      </label>
      <button class="btn btn-sm btn-outline" data-edit-policy="${p.policyId}" style="margin-left:8px;">Editar</button>
    </div>
  `).join('');

  document.getElementById('rp-info').textContent =
    filtered.length === 0
      ? 'Sin resultados'
      : `Mostrando ${start+1}–${Math.min(start+RP_ITEMS_PER_PAGE, filtered.length)} de ${filtered.length}`;

  document.getElementById('rp-pagination').innerHTML =
    totalPages <= 1
      ? '« ‹ 1 › »'
      : `« <span id="rp-prev" style="cursor:pointer">‹</span> ${state.rpPage} <span id="rp-next" style="cursor:pointer">›</span> »`;

  document.getElementById('rp-lista').removeEventListener('change', onRpToggle);
  document.getElementById('rp-lista').addEventListener('change', onRpToggle);
}

function onRpToggle(e) {
  const cb = e.target.closest('[data-policy-id]');
  if (!cb) return;
  const policy = state.reorderPolicies.find(p => p.policyId === parseInt(cb.dataset.policyId));
  if (!policy) return;
  policy.isActive = cb.checked;
  showToast(`Política "${policy.productName}" ${cb.checked ? 'activada' : 'desactivada'} (simulado)`);
}

// ============ MODAL: CREAR NUEVO ============
function populateCrearModalSelects() {
  document.getElementById('mc-tipo').innerHTML =
    state.productTypes.map(t => `<option>${t}</option>`).join('');
  document.getElementById('mc-uom').innerHTML =
    state.unitOfMeasures.map(u => `<option value="${u.unitId}">${u.name} (${u.code})</option>`).join('');
  document.getElementById('mc-categoria').innerHTML =
    '<option value="">Sin categoría</option>' +
    state.categoryTree.map(c => `<option value="${c.categoryId}">${c.name}</option>`).join('');
}

// ============ MODAL: BUSCAR PRODUCTO ============
function bindBuscarModal() {
  const mbBuscar = document.getElementById('mb-buscar');
  const mbResultados = document.getElementById('mb-resultados');
  const mbAceptar = document.getElementById('mb-aceptar');

  mbBuscar.addEventListener('input', () => {
    const q = mbBuscar.value.trim().toLowerCase();
    const results = state.inventoryDirectory.filter(p =>
      p.name.toLowerCase().includes(q)
    );
    mbResultados.innerHTML = results.length === 0
      ? '<div class="modal-result-item" style="color:var(--gray-500);cursor:default">Sin resultados</div>'
      : results.map(p => `<div class="modal-result-item" data-product-id="${p.productId}">${p.name}</div>`).join('');
    document.querySelectorAll('.modal-result-item:not([style])').forEach(el => el.classList.remove('selected'));
    state.selectedProduct = null;
    mbAceptar.disabled = true;
  });

  mbResultados.addEventListener('click', (e) => {
    const item = e.target.closest('.modal-result-item');
    if (!item || !item.dataset.productId) return;
    document.querySelectorAll('.modal-result-item').forEach(el => el.classList.remove('selected'));
    item.classList.add('selected');
    state.selectedProduct = parseInt(item.dataset.productId);
    mbAceptar.disabled = false;
  });

  mbAceptar.addEventListener('click', () => {
    if (!state.selectedProduct) return;
    const product = state.inventoryDirectory.find(p => p.productId === state.selectedProduct);
    showToast(`Producto "${product.name}" seleccionado (simulado)`);
    state.selectedProduct = null;
    mbBuscar.value = '';
    mbResultados.innerHTML = '';
    mbAceptar.disabled = true;
    closeModal('modal-buscar');
  });

  document.getElementById('mb-buscar').value = '';
  document.getElementById('mb-resultados').innerHTML = '';
  document.getElementById('mb-aceptar').disabled = true;
}

// ============ MODAL: ASIGNAR CATEGORÍA ============
function buildMacCategoryNodes(tree, parentId = null, search = '') {
  const q = search.toLowerCase();
  const roots = tree.filter(c => c.parentId === parentId);
  return roots
    .filter(cat => !search || cat.name.toLowerCase().includes(q) || hasMatchingDescendant(cat, tree, q))
    .map(cat => {
      const children = tree.filter(c => c.parentId === cat.categoryId);
      const hasChildren = children.length > 0;
      const toggleSymbol = hasChildren ? '▸' : '○';
      const childUl = hasChildren
        ? `<ul>${buildMacCategoryNodes(tree, cat.categoryId, search)}</ul>`
        : '';
      return `<li class="tree-node mac-tree-node" data-name="${cat.name}" data-category-id="${cat.categoryId}">
        <span class="tree-toggle">${toggleSymbol}</span> ${cat.name}
        ${childUl}
      </li>`;
    }).join('');
}

function hasMatchingDescendant(cat, tree, q) {
  const children = tree.filter(c => c.parentId === cat.categoryId);
  return children.some(c => c.name.toLowerCase().includes(q) || hasMatchingDescendant(c, tree, q));
}

function bindMacTreeEvents() {
  document.querySelectorAll('.mac-tree-node').forEach(node => {
    node.addEventListener('click', (e) => {
      e.stopPropagation();
      document.querySelectorAll('.mac-tree-node').forEach(n => n.classList.remove('selected'));
      node.classList.add('selected');
      state.selectedMacCategoryId = parseInt(node.dataset.categoryId);
      document.getElementById('mac-seleccionado').textContent = node.dataset.name;
      document.getElementById('mac-aceptar').disabled = false;
    });
  });

  document.querySelectorAll('#mac-category-tree .tree-toggle').forEach(toggle => {
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
}

function openAsignarCategoriaModal() {
  state.selectedMacCategoryId = null;
  document.getElementById('mac-seleccionado').textContent = '—';
  document.getElementById('mac-aceptar').disabled = true;
  document.getElementById('mac-buscar').value = '';
  document.getElementById('mac-category-tree').innerHTML = buildMacCategoryNodes(state.categoryTree);
  bindMacTreeEvents();

  const macBuscar = document.getElementById('mac-buscar');
  macBuscar.oninput = () => {
    const q = macBuscar.value.trim();
    document.getElementById('mac-category-tree').innerHTML = buildMacCategoryNodes(state.categoryTree, null, q);
    bindMacTreeEvents();
  };

  openModal('modal-asignar-categoria');
}

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
let pendingCount = 0;

function updatePendingCount(count) {
  pendingCount = Math.max(0, count);
  pendingCountEl.textContent = `${pendingCount} pendientes`;
}

itemsTable.addEventListener('click', (e) => {
  const row = e.target.closest('tr[data-row]');
  if (!row || row.classList.contains('row-resolved')) return;

  if (e.target.classList.contains('act-emparejar')) {
    row.classList.add('row-resolved');
    updatePendingCount(pendingCount - 1);
    showToast('Ítem emparejado correctamente');
  } else if (e.target.classList.contains('act-crear')) {
    openModal('modal-crear');
  } else if (e.target.classList.contains('act-buscar')) {
    openModal('modal-buscar');
  }
});

document.querySelector('#view-directorio .btn-primary').addEventListener('click', () => {
  openModal('modal-crear');
});

document.getElementById('btn-validar-todo').addEventListener('click', () => {
  document.querySelectorAll('#items-table tr[data-row]:not(.row-resolved)').forEach(row => {
    row.classList.add('row-resolved');
  });
  updatePendingCount(0);
  showToast('Todos los ítems fueron validados');
});

// ============ MODAL CREAR: ACEPTAR ============
document.getElementById('mc-aceptar').addEventListener('click', () => {
  const nombre = document.getElementById('mc-nombre').value.trim();
  if (!nombre) {
    showToast('El nombre es obligatorio');
    return;
  }
  showToast('Producto creado (simulado)');
  ['mc-nombre','mc-descripcion','mc-barcode','mc-marca'].forEach(id => document.getElementById(id).value = '');
  closeModal('modal-crear');
});

// ============ DASHBOARD: RANGE SELECT ============
document.querySelector('.range-select').addEventListener('change', (e) => {
  const range = e.target.value.includes('jul') ? 'jul_2026' : 'ago_2026';
  state.currentRange = range;
  const m = state.dashboardMetricsByRange[range] || state.dashboardMetrics;
  renderDashboardKPIs(m);
  renderReorderTable(m.reorderSuggestions);
  renderDeadStockTable(m.deadStock);
});

// ============ ASISTENTE IA (MCP) ============
const aiForm = document.getElementById('ai-form');
const aiInput = document.getElementById('ai-input');
const aiMessages = document.getElementById('ai-messages');

const aiResponses = [
  {
    match: /90 d|no se venden|inventario muerto/i,
    reply: () => {
      const m = state.dashboardMetrics;
      return `Hay ${m.deadStock.length} ítems sin movimiento >90 días, valor total $${m.deadStock.reduce((s,d)=>s+d.value,0).toLocaleString('es-CO')}. <a href="#" data-view-link="directorio">Ver lista →</a>`;
    }
  },
  {
    match: /reponer|reorden|stock/i,
    reply: () => {
      const r = state.dashboardMetrics.reorderSuggestions;
      const names = r.map(x => x.productName).join(', ');
      return `Detecté ${r.length} productos bajo el punto de reorden: ${names}. <a href="#" data-view-link="directorio">Ver el directorio →</a>`;
    }
  },
  {
    match: /valor|valoriz/i,
    reply: () => {
      const m = state.dashboardMetrics;
      return `La valorización total del inventario es de $${m.totalValuation.toLocaleString('es-CO')} (${m.currency}, costo local).`;
    }
  },
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
    const reply = found ? found.reply() : 'Consultando el modelo de datos… no encontré una métrica exacta para eso, pero puedo revisar el directorio de inventario contigo.';
    addBubble(reply, 'bot');
  }, 500);
});

// ============ DIRECTORIO: SELECCIÓN EN BLOQUE ============
function bindBulkBarEvents() {
  const checkAll = document.getElementById('check-all');

  function refreshBulkBar() {
    const rowChecks = document.querySelectorAll('.row-check');
    const checked = document.querySelectorAll('.row-check:checked').length;
    const bulkBar = document.getElementById('bulk-bar');
    bulkBar.hidden = checked === 0;
    document.getElementById('bulk-count').textContent = `${checked} seleccionado${checked === 1 ? '' : 's'}`;
    checkAll.checked = checked === rowChecks.length && rowChecks.length > 0;
  }

  checkAll.addEventListener('change', () => {
    document.querySelectorAll('.row-check').forEach(cb => cb.checked = checkAll.checked);
    refreshBulkBar();
  });

  document.querySelectorAll('.row-check').forEach(cb => cb.addEventListener('change', refreshBulkBar));

  document.getElementById('bulk-cancel').addEventListener('click', () => {
    document.querySelectorAll('.row-check').forEach(cb => cb.checked = false);
    checkAll.checked = false;
    refreshBulkBar();
  });

  document.getElementById('btn-asignar-categoria').addEventListener('click', () => {
    openAsignarCategoriaModal();
  });
}

// Re-bind when directory table re-renders (called from renderDirectoryTable)
function bindDirectoryRowEvents() {
  const checkAll = document.getElementById('check-all');
  const rowChecks = document.querySelectorAll('.row-check');
  const bulkBar = document.getElementById('bulk-bar');
  const bulkCount = document.getElementById('bulk-count');

  function refreshBulkBar() {
    const checked = document.querySelectorAll('.row-check:checked').length;
    bulkBar.hidden = checked === 0;
    bulkCount.textContent = `${checked} seleccionado${checked === 1 ? '' : 's'}`;
    checkAll.checked = checked === rowChecks.length && rowChecks.length > 0;
  }

  checkAll.onchange = () => {
    rowChecks.forEach(cb => cb.checked = checkAll.checked);
    refreshBulkBar();
  };
  rowChecks.forEach(cb => { cb.onchange = refreshBulkBar; });
  document.getElementById('bulk-cancel').onclick = () => {
    rowChecks.forEach(cb => cb.checked = false);
    checkAll.checked = false;
    refreshBulkBar();
  };
  document.getElementById('btn-asignar-categoria').onclick = openAsignarCategoriaModal;
}

// ============ CONFIGURACIÓN: TABS ============
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');

    const tabId = tab.dataset.tab;
    document.querySelectorAll('.tab-content').forEach(tc => tc.hidden = true);
    document.getElementById(`tab-${tabId}`).hidden = false;

    if (tabId === 'ubicaciones') {
      renderLocationTree();
    } else if (tabId === 'politicas') {
      state.rpPage = 1;
      state.rpSearch = '';
      document.getElementById('rp-buscar').value = '';
      renderReorderPolicies();
    } else if (tabId !== 'categorias') {
      showToast(`Sección "${tab.textContent}" — pendiente de maquetar`);
    }
  });
});

// ============ CONFIGURACIÓN: ÁRBOL DE CATEGORÍAS ============
const editName = document.getElementById('edit-name');
const editNameInput = document.getElementById('edit-name-input');
const editParentInput = document.getElementById('edit-parent-input');
const editCount = document.getElementById('edit-count');

function bindTreeEvents() {
  document.querySelectorAll('#category-tree .tree-node').forEach(node => {
    node.onclick = (e) => {
      e.stopPropagation();
      document.querySelectorAll('#category-tree .tree-node').forEach(n => n.classList.remove('selected'));
      node.classList.add('selected');
      editName.textContent = node.dataset.name;
      editNameInput.value = node.dataset.name;
      editParentInput.value = node.dataset.parent;
      editCount.textContent = node.dataset.count;
    };
  });

  document.querySelectorAll('#category-tree .tree-toggle').forEach(toggle => {
    toggle.onclick = (e) => {
      e.stopPropagation();
      const li = toggle.parentElement;
      const childUl = li.querySelector(':scope > ul');
      if (!childUl) return;
      const collapsed = childUl.style.display === 'none';
      childUl.style.display = collapsed ? '' : 'none';
      toggle.textContent = collapsed ? '▾' : '▸';
    };
  });
}

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

// ============ CONFIGURACIÓN: ÁRBOL DE UBICACIONES ============
const locEditName = document.getElementById('loc-edit-name');
const locEditNameInput = document.getElementById('loc-edit-name-input');
const locEditParentInput = document.getElementById('loc-edit-parent-input');
const locEditCount = document.getElementById('loc-edit-count');

function bindLocationTreeEvents() {
  document.querySelectorAll('#location-tree .tree-node').forEach(node => {
    node.onclick = (e) => {
      e.stopPropagation();
      document.querySelectorAll('#location-tree .tree-node').forEach(n => n.classList.remove('selected'));
      node.classList.add('selected');
      state.selectedLocationId = parseInt(node.dataset.locationId);
      locEditName.textContent = node.dataset.name;
      locEditNameInput.value = node.dataset.name;
      locEditParentInput.value = node.dataset.parent;
      locEditCount.textContent = node.dataset.count;
    };
  });

  document.querySelectorAll('#location-tree .tree-toggle').forEach(toggle => {
    toggle.onclick = (e) => {
      e.stopPropagation();
      const li = toggle.parentElement;
      const childUl = li.querySelector(':scope > ul');
      if (!childUl) return;
      const collapsed = childUl.style.display === 'none';
      childUl.style.display = collapsed ? '' : 'none';
      toggle.textContent = collapsed ? '▾' : '▸';
    };
  });
}

document.getElementById('loc-btn-guardar').addEventListener('click', () => {
  locEditName.textContent = locEditNameInput.value || locEditName.textContent;
  showToast('Ubicación guardada');
});

document.getElementById('loc-btn-eliminar').addEventListener('click', () => {
  showToast('Ubicación eliminada (simulado)');
});

// ============ MODAL MAC: ACEPTAR ============
document.getElementById('mac-aceptar').addEventListener('click', () => {
  if (!state.selectedMacCategoryId) return;
  const cat = state.categoryTree.find(c => c.categoryId === state.selectedMacCategoryId);
  showToast(`Categoría "${cat.name}" asignada (simulado)`);
  closeModal('modal-asignar-categoria');
});

// ============ REORDER POLICY: EDIT MODAL ============
function openEditarPoliticaModal(policyId) {
  const policy = state.reorderPolicies.find(p => p.policyId === policyId);
  if (!policy) return;
  document.getElementById('mep-producto').value = policy.productName;
  document.getElementById('mep-nivel').value = policy.reorderLevel;
  document.getElementById('mep-cantidad').value = policy.reorderQuantity;
  state.editingPolicyId = policyId;
  openModal('modal-editar-politica');
}

document.getElementById('rp-lista').addEventListener('click', (e) => {
  const btn = e.target.closest('[data-edit-policy]');
  if (!btn) return;
  openEditarPoliticaModal(parseInt(btn.dataset.editPolicy));
});

document.getElementById('mep-aceptar').addEventListener('click', () => {
  const nivel = parseInt(document.getElementById('mep-nivel').value);
  const cantidad = parseInt(document.getElementById('mep-cantidad').value);
  const policy = state.reorderPolicies.find(p => p.policyId === state.editingPolicyId);
  if (!policy) return;
  policy.reorderLevel = nivel;
  policy.reorderQuantity = cantidad;
  showToast(`Política de "${policy.productName}" actualizada (simulado)`);
  closeModal('modal-editar-politica');
  renderReorderPolicies();
});

// ============ MODAL LOCATION EDIT: ACEPTAR ============
document.getElementById('ml-aceptar').addEventListener('click', () => {
  const nombre = document.getElementById('ml-nombre').value.trim();
  if (!nombre) {
    showToast('El nombre es obligatorio');
    return;
  }
  showToast('Ubicación guardada (simulado)');
  closeModal('modal-location-edit');
});

// ============ REORDER POLICIES: SEARCH + PAGINATION ============
document.getElementById('rp-buscar').addEventListener('input', (e) => {
  state.rpSearch = e.target.value;
  state.rpPage = 1;
  renderReorderPolicies();
});

document.addEventListener('click', (e) => {
  if (!document.getElementById('tab-politicas') || document.getElementById('tab-politicas').hidden) return;
  if (e.target.id === 'rp-prev' || e.target.closest('#rp-prev')) {
    if (state.rpPage > 1) { state.rpPage--; renderReorderPolicies(); }
  } else if (e.target.id === 'rp-next' || e.target.closest('#rp-next')) {
    const filtered = state.reorderPolicies.filter(p => p.productName.toLowerCase().includes(state.rpSearch.toLowerCase()));
    const totalPages = Math.ceil(filtered.length / RP_ITEMS_PER_PAGE) || 1;
    if (state.rpPage < totalPages) { state.rpPage++; renderReorderPolicies(); }
  }
});

// ============ MODAL: CLOSE ON BACKDROP / ESC ============
document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
  backdrop.addEventListener('click', (e) => {
    if (e.target === backdrop) closeModal(backdrop.id);
  });
});
document.querySelectorAll('[data-close-modal]').forEach(btn => {
  btn.addEventListener('click', () => {
    const backdrop = btn.closest('.modal-backdrop');
    if (backdrop) closeModal(backdrop.id);
  });
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeAllModals();
});

// ============ BOOT ============
loadMockData().catch(err => {
  console.error('Error loading mock data:', err);
  showToast('Error al cargar datos. Ver consola.');
});
