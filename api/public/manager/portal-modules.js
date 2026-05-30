/** Modules portail Manager — parité app desktop */
(() => {
  'use strict';

  const A = () => window.PortalApp;
  let reportCache = null;
  let charts = [];
  let posCart = [];

  const shell = (title, body) =>
    `<div class="page-head"><h2>${title}</h2></div>${body}`;

  function page(html) {
    A().$('#content-area').innerHTML = html;
  }

  function table(h, rows) {
    if (!rows?.length) return `<p class="empty">${A().t('noData')}</p>`;
    return `<table class="report-table"><thead><tr>${h.map((x) => `<th>${x}</th>`).join('')}</tr></thead><tbody>${rows.join('')}</tbody></table>`;
  }

  function escAttr(v) {
    return String(v ?? '')
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/</g, '&lt;');
  }

  function formField({
    id, label, type = 'text', value = '', required = false, half = false,
    hint = '', placeholder = '', inputHtml = null, options = [],
  }) {
    const req = required ? ' required' : '';
    const ph = placeholder ? ` placeholder="${escAttr(placeholder)}"` : '';
    let control = inputHtml;
    if (!control) {
      if (type === 'select') {
        control = `<select id="${id}" class="form-control"${req}>${options.map((o) =>
          `<option value="${escAttr(o.value)}"${o.selected ? ' selected' : ''}>${o.label}</option>`).join('')}</select>`;
      } else if (type === 'textarea') {
        control = `<textarea id="${id}" class="form-control" rows="3"${req}${ph}>${escAttr(value)}</textarea>`;
      } else {
        control = `<input type="${type}" id="${id}" class="form-control" value="${escAttr(value)}"${req}${ph}>`;
      }
    }
    return `<div class="form-field${half ? ' form-field--half' : ''}">
      <label class="form-label" for="${id}">${label}${required ? '<span class="form-required">*</span>' : ''}</label>
      ${control}
      ${hint ? `<p class="form-hint">${hint}</p>` : ''}
    </div>`;
  }

  function formSection(title, innerHtml) {
    return `<fieldset class="form-section">
      <legend class="form-section-title">${title}</legend>
      <div class="form-grid">${innerHtml}</div>
    </fieldset>`;
  }

  function openForm(title, fieldsHtml, onSave, { mode = 'add', subtitle = '' } = {}) {
    const { t, $ } = A();
    const isEdit = mode === 'edit';
    const modal = $('#form-modal');
    const badge = $('#form-modal-badge');
    $('#form-modal-title').textContent = title;
    if (badge) {
      badge.textContent = isEdit ? t('edit') : t('add');
      badge.className = `form-mode-badge form-mode-badge--${isEdit ? 'edit' : 'add'}`;
    }
    const sub = $('#form-modal-subtitle');
    if (sub) sub.textContent = subtitle || (isEdit ? t('formEditHint') : t('formAddHint'));
    $('#form-modal-body').innerHTML = `<form id="portal-form" class="form-pro" novalidate>${fieldsHtml}</form>`;

    const runSave = async () => {
      const form = document.getElementById('portal-form');
      if (form && !form.checkValidity()) {
        form.reportValidity();
        return;
      }
      const saveBtn = $('#form-modal-save');
      saveBtn?.setAttribute('disabled', 'true');
      saveBtn?.classList.add('is-loading');
      try {
        await onSave();
      } finally {
        saveBtn?.removeAttribute('disabled');
        saveBtn?.classList.remove('is-loading');
      }
    };

    window._formSaveHandler = runSave;
    document.getElementById('portal-form')?.addEventListener('submit', (e) => {
      e.preventDefault();
      runSave();
    });

    modal?.showModal();
    requestAnimationFrame(() => {
      document.querySelector('#portal-form .form-control')?.focus();
    });
  }

  async function load(panel) {
    const map = {
      pos: loadPos,
      products: loadProducts,
      categories: loadCategories,
      alerts: loadAlerts,
      sales: loadSales,
      returns: loadReturns,
      clients: loadClients,
      expenses: loadExpenses,
      reports: loadReports,
      suppliers: loadSuppliers,
      users: loadUsers,
      settings: loadSettings,
    };
    if (map[panel]) await map[panel]();
  }

  // ——— Dashboard ———
  async function loadDashboard() {
    const { api, t, fmtMoney, fmtDate, esc, paymentLabel, showLoader, toast } = A();
    page(shell(t('dashboard'), `
      <div class="kpi-grid" id="dash-kpis"></div>
      <section class="section card"><h3>${t('recentSales')}</h3><div id="dash-sales" class="list"></div></section>`));
    showLoader(true);
    try {
      const { data } = await api('/manager/dashboard');
      const td = data.today || {};
      document.getElementById('dash-kpis').innerHTML = [
        [t('revenue'), fmtMoney(td.revenue)],
        [t('transactions'), td.transactions ?? 0],
        [t('avgBasket'), fmtMoney(td.avg_basket)],
        [t('itemsSold'), td.items_sold ?? 0],
        [t('pendingReturns'), data.pending_returns ?? 0],
        [t('returnsToday'), data.returns_today?.returns_today ?? 0],
      ].map(([l, v]) => `<div class="kpi"><div class="kpi-label">${l}</div><div class="kpi-value">${v}</div></div>`).join('');
      const sales = data.recent_sales || [];
      document.getElementById('dash-sales').innerHTML = sales.length
        ? sales.map((s) => saleRow(s, fmtDate, esc, paymentLabel, fmtMoney)).join('')
        : `<p class="empty">${t('noSalesToday')}</p>`;
      bindSales('#dash-sales');
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  function saleRow(s, fmtDate, esc, paymentLabel, fmtMoney) {
    return `<div class="list-item" data-sale-id="${s.id}"><div class="list-item-row">
      <div><div class="list-item-title">${esc(s.invoice_number)}</div>
      <div class="list-item-meta">${fmtDate(s.sold_at)} · ${esc(s.full_name || s.cashier_name || '')}</div></div>
      <div class="list-item-amount">${fmtMoney(s.total)}</div></div></div>`;
  }

  function bindSales(sel) {
    A().$$(`${sel} .list-item[data-sale-id]`).forEach((el) => {
      el.onclick = () => openSaleDetail(el.dataset.saleId);
    });
  }

  async function openSaleDetail(id) {
    const { api, t, fmtDate, esc, pn, fmtMoney, paymentLabel, showLoader, toast } = A();
    showLoader(true);
    try {
      const { data } = await api(`/manager/sale?id=${encodeURIComponent(id)}`);
      const s = data.sale;
      A().$('#modal-title').textContent = s.invoice_number;
      A().$('#modal-actions').classList.add('hidden');
      let html = `<div class="detail-row"><span>${t('date')}</span><span>${fmtDate(s.sold_at)}</span></div>
        <div class="detail-row"><span>${t('cashier')}</span><span>${esc(s.cashier_name)}</span></div>
        <div class="detail-row"><span>${t('amount')}</span><strong>${fmtMoney(s.total)}</strong></div>`;
      (data.lines || []).forEach((l) => {
        html += `<div class="line-item">${esc(pn(l))} × ${l.quantity} — ${fmtMoney(l.line_total)}</div>`;
      });
      A().$('#modal-body').innerHTML = html;
      A().$('#detail-modal').showModal();
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  // ——— Caisse POS ———
  async function loadPos() {
    const { t } = A();
    posCart = [];
    page(shell(t('navPos'), `
      <div class="pos-layout">
        <div class="card filters">
          <input type="search" id="pos-search" placeholder="${t('searchProduct')}">
          <button type="button" class="btn btn-secondary btn-sm" id="pos-search-btn">${t('filter')}</button>
        </div>
        <div class="pos-grid">
          <div id="pos-products" class="pos-products"></div>
          <div class="card pos-cart">
            <h3>${t('cart')}</h3>
            <div id="pos-cart-lines"></div>
            <label><span>${t('clientPhone')}</span><input id="pos-phone" type="tel"></label>
            <div class="detail-row"><span>${t('total')}</span><strong id="pos-total">0 FCFA</strong></div>
            <label><span>${t('payment')}</span>
              <select id="pos-pay"><option value="cash">${t('paymentCash')}</option>
              <option value="card">${t('paymentCard')}</option><option value="mobile">${t('paymentMobile')}</option></select></label>
            <label><span>${t('amountPaid')}</span><input type="number" id="pos-paid"></label>
            <button type="button" class="btn btn-primary" id="pos-checkout">${t('validateSale')}</button>
          </div>
        </div>
      </div>`));
    document.getElementById('pos-search-btn').onclick = searchPosProducts;
    document.getElementById('pos-checkout').onclick = checkoutPos;
    searchPosProducts();
  }

  async function searchPosProducts() {
    const { api, t, pn, esc, fmtMoney, toast } = A();
    const q = document.getElementById('pos-search').value.trim();
    try {
      const { data } = await api(`/manager/pos/products?q=${encodeURIComponent(q)}`);
      document.getElementById('pos-products').innerHTML = data.map((p) => `
        <div class="list-item" data-pos-id="${p.id}" data-price="${p.sale_price}" data-name="${esc(pn(p))}">
          <div class="list-item-row">
            <div><div class="list-item-title">${esc(pn(p))}</div>
            <div class="list-item-meta">${esc(p.barcode || '')} · ${t('qty')}: ${p.quantity}</div></div>
            <div class="list-item-amount">${fmtMoney(p.sale_price)}</div>
          </div>
        </div>`).join('') || `<p class="empty">${t('noData')}</p>`;
      A().$$('#pos-products .list-item[data-pos-id]').forEach((el) => {
        el.onclick = () => addToCart(el.dataset.posId, el.dataset.name, Number(el.dataset.price));
      });
    } catch (e) { toast(e.message, true); }
  }

  function addToCart(id, name, price) {
    const line = posCart.find((l) => l.product_id === id);
    if (line) line.quantity += 1;
    else posCart.push({ product_id: id, name, unit_price: price, quantity: 1 });
    renderPosCart();
  }

  function renderPosCart() {
    const { fmtMoney, t } = A();
    let total = 0;
    document.getElementById('pos-cart-lines').innerHTML = posCart.map((l, i) => {
      const lt = l.unit_price * l.quantity;
      total += lt;
      return `<div class="line-item">${l.name} × ${l.quantity} = ${fmtMoney(lt)}
        <button type="button" class="btn btn-ghost btn-sm" data-rm="${i}">−</button></div>`;
    }).join('') || `<p class="muted">${t('cartEmpty')}</p>`;
    document.getElementById('pos-total').textContent = fmtMoney(total);
    document.getElementById('pos-paid').value = Math.ceil(total);
    A().$$('[data-rm]').forEach((b) => {
      b.onclick = () => { posCart.splice(Number(b.dataset.rm), 1); renderPosCart(); };
    });
  }

  async function checkoutPos() {
    const { api, t, fmtMoney, toast, showLoader } = A();
    if (!posCart.length) { toast(t('cartEmpty'), true); return; }
    const total = posCart.reduce((s, l) => s + l.unit_price * l.quantity, 0);
    const paid = Number(document.getElementById('pos-paid').value) || total;
    showLoader(true);
    try {
      const { data } = await api('/manager/pos/sale', {
        method: 'POST',
        body: JSON.stringify({
          lines: posCart.map((l) => ({
            product_id: l.product_id,
            quantity: l.quantity,
            unit_price: l.unit_price,
            line_total: l.unit_price * l.quantity,
          })),
          subtotal: total,
          total,
          amount_paid: paid,
          change_given: Math.max(0, paid - total),
          payment_method: document.getElementById('pos-pay').value,
          client_phone: document.getElementById('pos-phone').value.trim(),
        }),
      });
      toast(`${t('saleOk')} ${data.invoice_number}`);
      posCart = [];
      renderPosCart();
      searchPosProducts();
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  // ——— Produits ———
  async function loadProducts() {
    const { t } = A();
    page(shell(t('navProducts'), `
      <div class="toolbar card">
        <input type="search" id="prod-search" placeholder="${t('searchProduct')}">
        <button class="btn btn-secondary btn-sm" id="prod-search-btn">${t('filter')}</button>
        <button class="btn btn-primary btn-sm" id="prod-add">${t('add')}</button>
      </div>
      <div id="prod-list" class="list"></div>`));
    document.getElementById('prod-search-btn').onclick = fetchProducts;
    document.getElementById('prod-add').onclick = () => openProductForm();
    fetchProducts();
  }

  async function fetchProducts() {
    const { api, t, pn, esc, fmtMoney, toast } = A();
    try {
      const q = document.getElementById('prod-search').value.trim();
      const { data } = await api(`/manager/products?search=${encodeURIComponent(q)}`);
      window._productsCache = data;
      document.getElementById('prod-list').innerHTML = data.map((p, i) => `
        <div class="list-item" data-prod-idx="${i}">
          <div class="list-item-row">
            <div><div class="list-item-title">${esc(pn(p))}</div>
            <div class="list-item-meta">${esc(p.barcode || '')} · ${t('qty')}: ${p.quantity}</div></div>
            <div class="list-item-amount">${fmtMoney(p.sale_price)}</div>
          </div>
        </div>`).join('') || `<p class="empty">${t('noData')}</p>`;
      A().$$('#prod-list .list-item[data-prod-idx]').forEach((el) => {
        el.onclick = () => openProductForm(window._productsCache[Number(el.dataset.prodIdx)]);
      });
    } catch (e) { toast(e.message, true); }
  }

  async function openProductForm(p = null) {
    const { api, t } = A();
    const { data: cats } = await api('/manager/categories');
    const opts = cats.map((c) => `<option value="${c.id}" ${p?.category_id === c.id ? 'selected' : ''}>${A().pn(c)}</option>`).join('');
    openForm(
      p ? t('editProduct') : t('addProduct'),
      `${formSection(t('formSectionGeneral'),
        formField({ id: 'f-cat', label: t('category'), inputHtml: `<select id="f-cat" class="form-control" required>${opts}</select>`, half: true })
        + formField({ id: 'f-barcode', label: t('barcode'), value: p?.barcode || '', half: true, placeholder: 'EAN…' }),
      )}${formSection(t('formSectionNames'),
        formField({ id: 'f-name-fr', label: t('nameFr'), value: p?.name_fr || '', required: true, half: true })
        + formField({ id: 'f-name-ar', label: t('nameAr'), value: p?.name_ar || '', half: true }),
      )}${formSection(t('formSectionPricing'),
        formField({ id: 'f-sale', label: t('salePrice'), type: 'number', value: p?.sale_price || '', required: true, half: true, hint: 'FCFA' })
        + formField({ id: 'f-purchase', label: t('purchasePrice'), type: 'number', value: p?.purchase_price || '', half: true, hint: 'FCFA' })
        + formField({ id: 'f-stock', label: t('stock'), type: 'number', value: p?.quantity ?? 0, half: true })
        + formField({ id: 'f-min', label: t('minStock'), type: 'number', value: p?.min_stock_level ?? 5, half: true }),
      )}<input type="hidden" id="f-id" value="${escAttr(p?.id || '')}">`,
      async () => {
      const { api } = A();
      const body = {
        id: document.getElementById('f-id').value || undefined,
        category_id: document.getElementById('f-cat').value,
        barcode: document.getElementById('f-barcode').value,
        name_fr: document.getElementById('f-name-fr').value,
        name_ar: document.getElementById('f-name-ar').value,
        sale_price: document.getElementById('f-sale').value,
        purchase_price: document.getElementById('f-purchase').value,
        stock_quantity: document.getElementById('f-stock').value,
        min_stock_level: document.getElementById('f-min').value,
      };
      await api('/manager/products', { method: 'POST', body: JSON.stringify(body) });
      A().$('#form-modal').close();
      A().toast(A().t('saved'));
      fetchProducts();
    },
    { mode: p ? 'edit' : 'add' },
    );
  }

  // ——— Catégories ———
  async function loadCategories() {
    const { t } = A();
    page(shell(t('navCategories'), `
      <button class="btn btn-primary btn-sm toolbar-btn" id="cat-add">${t('add')}</button>
      <div id="cat-list" class="list"></div>`));
    document.getElementById('cat-add').onclick = () => openCategoryForm();
    fetchCategories();
  }

  async function fetchCategories() {
    const { api, t, pn, esc, toast } = A();
    try {
      const { data } = await api('/manager/categories');
      document.getElementById('cat-list').innerHTML = data.map((c) => `
        <div class="list-item" data-cat='${JSON.stringify(c).replace(/'/g, "&#39;")}'>
          <div class="list-item-title">${esc(pn(c))}</div>
        </div>`).join('');
      A().$$('#cat-list .list-item').forEach((el) => {
        el.onclick = () => openCategoryForm(JSON.parse(el.dataset.cat.replace(/&#39;/g, "'")));
      });
    } catch (e) { toast(e.message, true); }
  }

  function openCategoryForm(c = null) {
    const { api, t, toast } = A();
    openForm(
      c ? t('edit') : t('addCategory'),
      formSection(t('formSectionNames'),
        formField({ id: 'fc-fr', label: t('nameFr'), value: c?.name_fr || '', required: true, half: true })
        + formField({ id: 'fc-ar', label: t('nameAr'), value: c?.name_ar || '', half: true }),
      ) + `<input type="hidden" id="fc-id" value="${escAttr(c?.id || '')}">`,
      async () => {
      await api('/manager/categories', {
        method: 'POST',
        body: JSON.stringify({
          id: document.getElementById('fc-id').value || undefined,
          name_fr: document.getElementById('fc-fr').value,
          name_ar: document.getElementById('fc-ar').value,
        }),
      });
      A().$('#form-modal').close();
      toast(t('saved'));
      fetchCategories();
    },
    { mode: c ? 'edit' : 'add' },
    );
  }

  // ——— Alertes, ventes, retours, clients (similaire app.js) ———
  async function loadAlerts() {
    const { api, t, pn, esc, fmtDay, toast, showLoader } = A();
    page(shell(t('navAlerts'), '<div id="alerts-wrap"></div>'));
    showLoader(true);
    try {
      const { data } = await api('/manager/alerts');
      const c = data.counts || {};
      let html = `<div class="alert-section"><h3>${t('lowStockAlert')} (${c.low_stock || 0})</h3>`;
      html += (data.low_stock || []).map((p) => `<div class="list-item"><strong>${esc(pn(p))}</strong> — ${p.quantity}</div>`).join('') || `<p class="empty">${t('stockOk')}</p>`;
      html += `</div><div class="alert-section"><h3>${t('expiringAlert')} (${c.expiring || 0})</h3>`;
      html += (data.expiring || []).map((p) => `<div class="list-item"><strong>${esc(pn(p))}</strong> — ${fmtDay(p.expires_at)}</div>`).join('') || '';
      html += '</div>';
      document.getElementById('alerts-wrap').innerHTML = html;
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  async function loadSales() {
    const { t, today, daysAgo } = A();
    page(shell(t('navSales'), `
      <div class="filters card">
        <label>${t('from')}<input type="date" id="sales-from" value="${daysAgo(30)}"></label>
        <label>${t('to')}<input type="date" id="sales-to" value="${today()}"></label>
        <button class="btn btn-secondary btn-sm" id="sales-btn">${t('filter')}</button>
      </div>
      <div id="sales-list" class="list"></div>`));
    document.getElementById('sales-btn').onclick = async () => {
      const { api, toast, showLoader } = A();
      showLoader(true);
      try {
        const from = document.getElementById('sales-from').value;
        const to = document.getElementById('sales-to').value;
        const { data } = await api(`/manager/sales?from=${from}&to=${to}&limit=200`);
        document.getElementById('sales-list').innerHTML = data.length
          ? data.map((s) => saleRow(s, A().fmtDate, A().esc, A().paymentLabel, A().fmtMoney)).join('')
          : `<p class="empty">${A().t('noData')}</p>`;
        bindSales('#sales-list');
      } catch (e) { toast(e.message, true); }
      finally { showLoader(false); }
    };
    document.getElementById('sales-btn').click();
  }

  let returnStatusFilter = '';

  function returnStatusLabel(status) {
    const { t } = A();
    return ({
      pending: t('returnFilterPending'),
      approved: t('returnFilterApproved'),
      rejected: t('returnFilterRejected'),
    })[status] || status || '—';
  }

  function returnStatusBadge(status) {
    const cls = {
      pending: 'badge-warn',
      approved: 'badge-success',
      rejected: 'badge-danger',
    }[status] || '';
    return `<span class="badge ${cls}">${returnStatusLabel(status)}</span>`;
  }

  async function loadReturns() {
    const { t } = A();
    returnStatusFilter = '';
    page(shell(t('navReturns'), `
      <div class="segmented return-filters" id="ret-filters">
        <button type="button" class="seg-btn active" data-ret="">${t('returnFilterAll')}</button>
        <button type="button" class="seg-btn" data-ret="pending">${t('returnFilterPending')}</button>
        <button type="button" class="seg-btn" data-ret="approved">${t('returnFilterApproved')}</button>
        <button type="button" class="seg-btn" data-ret="rejected">${t('returnFilterRejected')}</button>
      </div>
      <div id="ret-list" class="list"></div>`));
    A().$$('#ret-filters .seg-btn').forEach((btn) => {
      btn.onclick = () => {
        A().$$('#ret-filters .seg-btn').forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        returnStatusFilter = btn.dataset.ret;
        fetchReturns(returnStatusFilter);
      };
    });
    fetchReturns('');
  }

  async function fetchReturns(status) {
    const { api, t, fmtDate, esc, fmtMoney, toast, showLoader } = A();
    showLoader(true);
    try {
      const qs = status ? `?status=${encodeURIComponent(status)}` : '';
      const { data } = await api(`/manager/returns/history${qs}`);
      document.getElementById('ret-list').innerHTML = data.length ? data.map((r) => `
        <div class="list-item" data-return-id="${r.id}">
          <div class="list-item-row">
            <div>
              <div class="list-item-title">${esc(r.invoice_number)} ${returnStatusBadge(r.return_status)}</div>
              <div class="list-item-meta">${fmtDate(r.return_requested_at || r.return_approved_at)}
                · ${esc(r.return_requester_name || r.cashier_name || '')}</div>
            </div>
            <div class="list-item-amount">${fmtMoney(r.total)}</div>
          </div>
        </div>`).join('') : `<p class="empty">${t('noData')}</p>`;
      A().$$('#ret-list [data-return-id]').forEach((el) => {
        el.onclick = () => openReturnDetail(el.dataset.returnId);
      });
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  async function openReturnDetail(id) {
    const { api, t, fmtDate, pn, esc, fmtMoney, showLoader, toast } = A();
    showLoader(true);
    try {
      const { data } = await api(`/manager/return?id=${encodeURIComponent(id)}`);
      const s = data.sale;
      const isPending = s.return_status === 'pending';
      if (isPending) A().setReturnId(s.id);
      else A().setReturnId(null);
      A().$('#modal-title').textContent = s.invoice_number;
      A().$('#modal-actions').classList.toggle('hidden', !isPending);
      const dateIso = s.return_requested_at || s.return_approved_at;
      let html = `<div class="detail-row"><span>${t('status')}</span><span>${returnStatusBadge(s.return_status)}</span></div>
        <div class="detail-row"><span>${t('date')}</span><span>${fmtDate(dateIso)}</span></div>
        <div class="detail-row"><span>${t('amount')}</span><strong>${fmtMoney(s.total)}</strong></div>`;
      if (s.return_reason) {
        html += `<div class="detail-row"><span>${t('returnReason')}</span><span>${esc(s.return_reason)}</span></div>`;
      }
      const lines = data.return_lines?.length ? data.return_lines : data.all_lines || [];
      lines.forEach((l) => {
        const qty = l.quantity_to_return ?? l.quantity;
        html += `<div class="line-item">${esc(pn(l))}${qty ? ` × ${qty}` : ''}</div>`;
      });
      A().$('#modal-body').innerHTML = html;
      A().$('#detail-modal').showModal();
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  async function loadClients() {
    const { t } = A();
    page(shell(t('navClients'), `
      <div class="toolbar card">
        <input type="search" id="cli-search" placeholder="${t('searchClient')}">
        <button class="btn btn-secondary btn-sm" id="cli-btn">${t('filter')}</button>
        <button class="btn btn-primary btn-sm" id="cli-add">${t('add')}</button>
      </div>
      <div id="cli-list" class="list"></div>`));
    document.getElementById('cli-btn').onclick = fetchClients;
    document.getElementById('cli-add').onclick = () => openClientForm();
    fetchClients();
  }

  async function fetchClients() {
    const { api, t, esc, toast } = A();
    try {
      const q = document.getElementById('cli-search').value.trim();
      const { data } = await api(`/manager/clients?search=${encodeURIComponent(q)}`);
      document.getElementById('cli-list').innerHTML = data.map((c) => `
        <div class="list-item" data-cid="${c.id}">
          <div class="list-item-title">${esc(c.name || c.phone)}</div>
          <div class="list-item-meta">${esc(c.phone)} · ${t('loyalty')}: ${c.loyalty_points}/10</div>
        </div>`).join('') || `<p class="empty">${t('noData')}</p>`;
      A().$$('[data-cid]').forEach((el) => {
        el.onclick = () => openClientDetail(el.dataset.cid);
      });
    } catch (e) { toast(e.message, true); }
  }

  async function openClientForm(c = null) {
    const { api, t, toast } = A();
    openForm(
      c ? t('editClient') : t('addClient'),
      formSection(t('formSectionContact'),
        formField({ id: 'cl-phone', label: t('phone'), type: 'tel', value: c?.phone || '', required: true, half: true, placeholder: '+235…' })
        + formField({ id: 'cl-name', label: t('name'), value: c?.name || '', half: true }),
      ) + `<input type="hidden" id="cl-id" value="${escAttr(c?.id || '')}">`,
      async () => {
      await api('/manager/clients', {
        method: 'POST',
        body: JSON.stringify({
          id: document.getElementById('cl-id').value || undefined,
          phone: document.getElementById('cl-phone').value,
          name: document.getElementById('cl-name').value,
        }),
      });
      A().$('#form-modal').close();
      toast(t('saved'));
      fetchClients();
    },
    { mode: c ? 'edit' : 'add' },
    );
  }

  async function openClientDetail(id) {
    const { api, t, esc, fmtDate, fmtMoney, toast, showLoader } = A();
    showLoader(true);
    try {
      const { data } = await api(`/manager/client?id=${encodeURIComponent(id)}`);
      const c = data.client;
      A().$('#modal-title').textContent = c.name || c.phone;
      A().$('#modal-actions').classList.add('hidden');
      let html = `<div class="detail-row"><span>${t('phone')}</span><span>${esc(c.phone)}</span></div>
        <div class="detail-row"><span>${t('loyalty')}</span><span>${c.loyalty_points}</span></div>`;
      if (c.gift_eligible) {
        html += `<button class="btn btn-primary btn-sm" id="gift-btn" style="margin-top:1rem">${t('redeemGift')}</button>`;
      }
      (data.recent_sales || []).forEach((s) => {
        html += `<div class="line-item">${esc(s.invoice_number)} — ${fmtMoney(s.total)}</div>`;
      });
      A().$('#modal-body').innerHTML = html;
      const gb = document.getElementById('gift-btn');
      if (gb) gb.onclick = async () => {
        await api('/manager/clients/redeem-gift', { method: 'POST', body: JSON.stringify({ client_id: id }) });
        toast(t('saved'));
        A().$('#detail-modal').close();
      };
      A().$('#detail-modal').showModal();
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  // ——— Dépenses ———
  async function loadExpenses() {
    const { t, today, daysAgo } = A();
    page(shell(t('navExpenses'), `
      <div class="toolbar card">
        <button class="btn btn-primary btn-sm" id="exp-add">${t('add')}</button>
      </div>
      <div id="exp-list" class="list"></div>`));
    document.getElementById('exp-add').onclick = () => openExpenseForm();
    fetchExpenses();
  }

  async function fetchExpenses() {
    const { api, t, esc, fmtMoney, fmtDay, toast } = A();
    try {
      const { data } = await api('/manager/expenses');
      document.getElementById('exp-list').innerHTML = data.map((e) => `
        <div class="list-item" data-exp='${JSON.stringify(e).replace(/'/g, "&#39;")}'>
          <div class="list-item-row">
            <div><div class="list-item-title">${esc(e.category)}</div>
            <div class="list-item-meta">${fmtDay(e.expense_date)} · ${esc(e.description || '')}</div></div>
            <div class="list-item-amount">${fmtMoney(e.amount)}</div>
          </div>
        </div>`).join('') || `<p class="empty">${t('noData')}</p>`;
      A().$$('[data-exp]').forEach((el) => {
        el.onclick = () => openExpenseForm(JSON.parse(el.dataset.exp.replace(/&#39;/g, "'")));
      });
    } catch (e) { toast(e.message, true); }
  }

  function openExpenseForm(e = null) {
    const { api, t, toast } = A();
    const cat = e?.category || 'other';
    const catOpts = [
      { value: 'cash_send', label: t('expenseCatCashSend'), selected: cat === 'cash_send' },
      { value: 'purchase', label: t('expenseCatPurchase'), selected: cat === 'purchase' },
      { value: 'supply', label: t('expenseCatSupply'), selected: cat === 'supply' },
      { value: 'other', label: t('expenseCatOther'), selected: cat === 'other' },
    ];
    openForm(
      e ? t('editExpense') : t('addExpense'),
      formSection(t('formSectionGeneral'),
        formField({ id: 'fe-date', label: t('date'), type: 'date', value: (e?.expense_date || '').toString().slice(0, 10) || A().today(), required: true, half: true })
        + formField({ id: 'fe-amt', label: t('amount'), type: 'number', value: e?.amount || '', required: true, half: true, hint: 'FCFA' })
        + formField({ id: 'fe-cat', label: t('category'), type: 'select', options: catOpts, half: true })
        + formField({ id: 'fe-desc', label: t('description'), value: e?.description || '', half: true, placeholder: t('optional') }),
      ) + `<input type="hidden" id="fe-id" value="${escAttr(e?.id || '')}">`,
      async () => {
      await api('/manager/expenses', {
        method: 'POST',
        body: JSON.stringify({
          id: document.getElementById('fe-id').value || undefined,
          expense_date: document.getElementById('fe-date').value,
          amount: document.getElementById('fe-amt').value,
          category: document.getElementById('fe-cat').value,
          description: document.getElementById('fe-desc').value,
        }),
      });
      A().$('#form-modal').close();
      toast(t('saved'));
      fetchExpenses();
    },
    { mode: e ? 'edit' : 'add' },
    );
  }

  // ——— Fournisseurs, utilisateurs, paramètres ———
  async function loadSuppliers() {
    const { t } = A();
    page(shell(t('navSuppliers'), `
      <button class="btn btn-primary btn-sm toolbar-btn" id="sup-add">${t('add')}</button>
      <div id="sup-list" class="list"></div>`));
    document.getElementById('sup-add').onclick = () => openSupplierForm();
    fetchSuppliers();
  }

  async function fetchSuppliers() {
    const { api, esc, toast } = A();
    try {
      const { data } = await api('/manager/suppliers');
      document.getElementById('sup-list').innerHTML = data.map((s) => `
        <div class="list-item" data-sup='${JSON.stringify(s).replace(/'/g, "&#39;")}'>
          <div class="list-item-title">${esc(s.name)}</div>
          <div class="list-item-meta">${esc(s.phone || '')}</div>
        </div>`).join('');
      A().$$('[data-sup]').forEach((el) => {
        el.onclick = () => openSupplierForm(JSON.parse(el.dataset.sup.replace(/&#39;/g, "'")));
      });
    } catch (e) { toast(e.message, true); }
  }

  function openSupplierForm(s = null) {
    const { api, t, toast } = A();
    openForm(
      s ? t('editSupplier') : t('addSupplier'),
      formSection(t('formSectionContact'),
        formField({ id: 'fs-name', label: t('name'), value: s?.name || '', required: true })
        + formField({ id: 'fs-phone', label: t('phone'), type: 'tel', value: s?.phone || '', half: true })
        + formField({ id: 'fs-email', label: t('email'), type: 'email', value: s?.email || '', half: true }),
      ) + `<input type="hidden" id="fs-id" value="${escAttr(s?.id || '')}">`,
      async () => {
      await api('/manager/suppliers', {
        method: 'POST',
        body: JSON.stringify({
          id: document.getElementById('fs-id').value || undefined,
          name: document.getElementById('fs-name').value,
          phone: document.getElementById('fs-phone').value,
          email: document.getElementById('fs-email').value,
        }),
      });
      A().$('#form-modal').close();
      toast(t('saved'));
      fetchSuppliers();
    },
    { mode: s ? 'edit' : 'add' },
    );
  }

  async function loadUsers() {
    const { t } = A();
    page(shell(t('navUsers'), `
      <button class="btn btn-primary btn-sm toolbar-btn" id="usr-add">${t('add')}</button>
      <div id="usr-list" class="list"></div>`));
    document.getElementById('usr-add').onclick = () => openUserForm();
    fetchUsers();
  }

  async function fetchUsers() {
    const { api, esc, toast } = A();
    try {
      const { data } = await api('/manager/users');
      document.getElementById('usr-list').innerHTML = data.map((u) => `
        <div class="list-item" data-usr='${JSON.stringify(u).replace(/'/g, "&#39;")}'>
          <div class="list-item-title">${esc(u.full_name)}</div>
          <div class="list-item-meta">${esc(u.username)} · ${u.role_code}</div>
        </div>`).join('');
      A().$$('[data-usr]').forEach((el) => {
        el.onclick = () => openUserForm(JSON.parse(el.dataset.usr.replace(/&#39;/g, "'")));
      });
    } catch (e) { toast(e.message, true); }
  }

  async function openUserForm(u = null) {
    const { api, t, toast } = A();
    const accountFields = u ? '' : formSection(t('formSectionAccount'),
      formField({ id: 'fu-user', label: t('username'), required: true, half: true, placeholder: 'login' })
      + formField({ id: 'fu-pass', label: t('password'), type: 'password', required: true, half: true }),
    );
    openForm(
      u ? t('editUser') : t('addUser'),
      `${accountFields}${formSection(t('formSectionGeneral'),
        formField({ id: 'fu-name', label: t('name'), value: u?.full_name || '', required: true })
        + formField({
          id: 'fu-role',
          label: t('role'),
          type: 'select',
          options: [
            { value: 'manager', label: 'Manager', selected: u?.role_code === 'manager' },
            { value: 'gestionnaire', label: 'Gestionnaire', selected: u?.role_code === 'gestionnaire' },
          ],
        }),
      )}<input type="hidden" id="fu-id" value="${escAttr(u?.id || '')}">`,
      async () => {
      const body = {
        id: document.getElementById('fu-id').value || undefined,
        full_name: document.getElementById('fu-name').value,
        role_code: document.getElementById('fu-role').value,
      };
      if (!u) {
        body.username = document.getElementById('fu-user').value;
        body.password = document.getElementById('fu-pass').value;
      }
      await api('/manager/users', { method: 'POST', body: JSON.stringify(body) });
      A().$('#form-modal').close();
      toast(t('saved'));
      fetchUsers();
    },
    { mode: u ? 'edit' : 'add' },
    );
  }

  async function loadSettings() {
    const { api, t, toast, showLoader } = A();
    page(shell(t('navSettings'), '<div id="set-form"></div>'));
    showLoader(true);
    try {
      const { data } = await api('/manager/settings');
      document.getElementById('set-form').innerHTML = `
        <div class="card page-form">
          ${formSection(t('formSectionGeneral'),
            formField({ id: 'st-fr', label: t('storeNameFr'), value: data.name_fr || '', half: true })
            + formField({ id: 'st-ar', label: t('storeNameAr'), value: data.name_ar || '', half: true })
            + formField({ id: 'st-addr', label: t('address'), value: data.address || '' })
            + formField({ id: 'st-phone', label: t('phone'), type: 'tel', value: data.phone || '', half: true })
            + formField({ id: 'st-email', label: t('email'), type: 'email', value: data.email || '', half: true }),
          )}
          <div class="modal-footer" style="border-radius:0 0 12px 12px">
            <button type="button" class="btn btn-primary" id="st-save">${t('save')}</button>
          </div>
        </div>`;
      document.getElementById('st-save').onclick = async () => {
        await api('/manager/settings', {
          method: 'POST',
          body: JSON.stringify({
            name_fr: document.getElementById('st-fr').value,
            name_ar: document.getElementById('st-ar').value,
            address: document.getElementById('st-addr').value,
            phone: document.getElementById('st-phone').value,
            email: document.getElementById('st-email').value,
          }),
        });
        toast(t('saved'));
      };
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  // ——— Rapports (graphiques) ———
  async function loadReports() {
    const { t, today, daysAgo } = A();
    const y = new Date().getFullYear();
    let yearOpts = '';
    for (let i = y; i >= y - 5; i--) yearOpts += `<option value="${i}">${i}</option>`;
    page(shell(t('navReports'), `
      <div class="toolbar card row-between">
        <div class="segmented">
          <button class="seg-btn active" data-rpt="period">${t('period')}</button>
          <button class="seg-btn" data-rpt="yearly">${t('yearly')}</button>
        </div>
        <button class="btn btn-primary btn-sm" id="rpt-pdf">${t('exportPdf')}</button>
      </div>
      <div id="rpt-filters" class="filters card">
        <label>${t('from')}<input type="date" id="rpt-from" value="${daysAgo(30)}"></label>
        <label>${t('to')}<input type="date" id="rpt-to" value="${today()}"></label>
        <button class="btn btn-secondary btn-sm" id="rpt-load">${t('refresh')}</button>
      </div>
      <div id="rpt-yearly" class="filters card hidden">
        <label>${t('year')}<select id="rpt-year">${yearOpts}</select></label>
        <button class="btn btn-secondary btn-sm" id="rpt-yload">${t('refresh')}</button>
      </div>
      <div id="rpt-body"></div>`));
    let mode = 'period';
    A().$$('.seg-btn').forEach((b) => {
      b.onclick = () => {
        A().$$('.seg-btn').forEach((x) => x.classList.remove('active'));
        b.classList.add('active');
        mode = b.dataset.rpt;
        document.getElementById('rpt-filters').classList.toggle('hidden', mode !== 'period');
        document.getElementById('rpt-yearly').classList.toggle('hidden', mode !== 'yearly');
        runReports(mode);
      };
    });
    document.getElementById('rpt-load').onclick = () => runReports('period');
    document.getElementById('rpt-yload').onclick = () => runReports('yearly');
    document.getElementById('rpt-pdf').onclick = exportPdf;
    runReports('period');
  }

  async function runReports(mode) {
    const { api, t, fmtMoney, fmtDay, fmtMonth, esc, paymentLabel, pn, cn, showLoader, toast } = A();
    showLoader(true);
    try {
      let data;
      if (mode === 'yearly') {
        data = (await api(`/manager/reports/yearly?year=${document.getElementById('rpt-year').value}`)).data;
        reportCache = { data, yearly: true };
        document.getElementById('rpt-body').innerHTML = renderYearlyHtml(data, t, fmtMoney, fmtMonth, table);
      } else {
        const from = document.getElementById('rpt-from').value;
        const to = document.getElementById('rpt-to').value;
        data = (await api(`/manager/reports?from=${from}&to=${to}`)).data;
        reportCache = { data, yearly: false, from, to };
        document.getElementById('rpt-body').innerHTML = renderPeriodHtml(data, t, fmtMoney, table);
      }
      requestAnimationFrame(() => drawCharts(data, mode === 'yearly', t, fmtDay, fmtMonth, paymentLabel, pn, cn));
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  function renderPeriodHtml(d, t, fmtMoney, table) {
    const s = d.summary || {};
    const cmp = d.comparison || {};
    const rs = d.returns;
    let returnsBlock = '';
    if (rs && (rs.requested > 0 || rs.pending > 0 || rs.approved > 0 || rs.rejected > 0)) {
      returnsBlock = `<div class="report-block"><h4>${t('returnsPeriod')}</h4>${table(
        [t('status'), t('qty'), t('amount')],
        [
          [t('requested'), rs.requested ?? 0, '—'],
          [t('pending'), rs.pending ?? 0, '—'],
          [t('approved'), rs.approved ?? 0, fmtMoney(rs.approved_amount)],
          [t('rejected'), rs.rejected ?? 0, '—'],
        ].map((r) => `<tr><td>${r[0]}</td><td class="num">${r[1]}</td><td class="num">${r[2]}</td></tr>`),
      )}</div>`;
    }
    return `<div class="kpi-grid">${[
      [t('revenue'), fmtMoney(s.revenue)], [t('profit'), fmtMoney(d.profit)],
      [t('transactions'), s.transactions], [t('avgBasket'), fmtMoney(s.avg_basket)],
      [t('expenses'), fmtMoney(d.expenses?.total)], [t('discounts'), fmtMoney(s.total_discounts)],
    ].map(([l, v]) => `<div class="kpi"><div class="kpi-label">${l}</div><div class="kpi-value">${v}</div></div>`).join('')}
      </div>
      <div class="report-block"><h4>${t('comparison')}</h4>${table(
        [t('comparison'), t('revenue'), t('transactions')],
        [
          [t('currentPeriod'), fmtMoney(cmp.current?.revenue), cmp.current?.transactions ?? 0],
          [t('previousPeriod'), fmtMoney(cmp.previous?.revenue), cmp.previous?.transactions ?? 0],
        ].map((r) => `<tr><td>${r[0]}</td><td class="num">${r[1]}</td><td class="num">${r[2]}</td></tr>`),
      )}</div>
      ${returnsBlock}
      <div class="chart-grid chart-grid-2">
        <div class="report-block"><h4>${t('revenueByDay')}</h4><div class="chart-wrap"><canvas id="ch-day"></canvas></div></div>
        <div class="report-block"><h4>${t('byCategory')}</h4><div class="chart-wrap"><canvas id="ch-cat"></canvas></div></div>
        <div class="report-block"><h4>${t('payments')}</h4><div class="chart-wrap"><canvas id="ch-payments"></canvas></div></div>
        <div class="report-block"><h4>${t('byCashier')}</h4><div class="chart-wrap"><canvas id="ch-cashier"></canvas></div></div>
        <div class="report-block"><h4>${t('monthlyRevenue')}</h4><div class="chart-wrap"><canvas id="ch-monthly"></canvas></div></div>
        <div class="report-block"><h4>${t('topProducts')}</h4><div class="chart-wrap"><canvas id="ch-top"></canvas></div></div>
      </div>
      <div class="report-block"><h4>${t('topProducts')}</h4>${table([t('product'), t('qty'), t('amount')],
        (d.top_products || []).map((p) => `<tr><td>${A().esc(A().pn(p))}</td><td class="num">${p.qty_sold}</td><td class="num">${fmtMoney(p.revenue)}</td></tr>`))}
      </div>`;
  }

  function renderYearlyHtml(d, t, fmtMoney, fmtMonth, tableFn) {
    const s = d.summary || {};
    const cmp = d.comparison || {};
    const prevRev = cmp.previous?.revenue;
    const curRev = cmp.current?.revenue ?? s.revenue;
    let yoy = '';
    if (prevRev > 0) {
      const pct = ((Number(curRev) - Number(prevRev)) / Number(prevRev)) * 100;
      yoy = `${pct >= 0 ? '+' : ''}${pct.toFixed(1)} % vs ${d.year - 1}`;
    }
    return `<div class="kpi-grid">${[
      [t('revenue'), fmtMoney(s.revenue)], [t('transactions'), s.transactions],
      [t('avgBasket'), fmtMoney(s.avg_basket)], [t('profit'), fmtMoney(d.profit)],
      [t('expenses'), fmtMoney(d.expenses?.total)], ...(yoy ? [[t('annualComparison'), yoy]] : []),
    ].map(([l, v]) => `<div class="kpi"><div class="kpi-label">${l}</div><div class="kpi-value">${v}</div></div>`).join('')}
      </div>
      <div class="chart-grid chart-grid-2">
        <div class="report-block"><h4>${t('monthlyDetail')}</h4><div class="chart-wrap"><canvas id="ch-month"></canvas></div></div>
        <div class="report-block"><h4>${t('payments')}</h4><div class="chart-wrap"><canvas id="ch-payments"></canvas></div></div>
        <div class="report-block"><h4>${t('topProducts')}</h4><div class="chart-wrap"><canvas id="ch-top"></canvas></div></div>
      </div>
      <div class="report-block"><h4>${t('monthlyDetail')}</h4>${tableFn(
        [t('date'), t('transactions'), t('revenue'), t('avgBasket')],
        (d.monthly_breakdown || []).map((m) => `<tr><td>${fmtMonth(m.month)}</td><td class="num">${m.transactions ?? 0}</td><td class="num">${fmtMoney(m.revenue)}</td><td class="num">${fmtMoney(m.avg_basket)}</td></tr>`),
      )}</div>
      <div class="report-block"><h4>${t('topProducts')}</h4>${tableFn([t('product'), t('qty'), t('amount')],
        (d.top_products || []).slice(0, 15).map((p) => `<tr><td>${A().esc(A().pn(p))}</td><td class="num">${p.qty_sold}</td><td class="num">${fmtMoney(p.revenue)}</td></tr>`))}
      </div>`;
  }

  function drawCharts(d, yearly, t, fmtDay, fmtMonth, paymentLabel, pn, cn) {
    charts.forEach((c) => c.destroy());
    charts = [];
    const colors = ['#C9A227', '#1A1A2E', '#4A6FA5', '#6B8E6B', '#6B7280', '#0D7A4E', '#8B4513', '#9370DB'];
    const baseOpt = {
      responsive: true,
      maintainAspectRatio: false,
      animation: false,
      layout: { padding: { top: 4, bottom: 4, left: 4, right: 4 } },
      plugins: {
        legend: {
          display: true,
          position: 'bottom',
          labels: { boxWidth: 10, boxHeight: 10, padding: 12, font: { size: 11 } },
        },
      },
    };
    const doughnutDs = (data) => [{
      data,
      backgroundColor: colors,
      borderColor: '#FFFFFF',
      borderWidth: 2,
      hoverOffset: 0,
    }];
    const doughnutOpt = {
      cutout: '58%',
      plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, padding: 14 } } },
    };
    const mk = (id, type, labels, ds, opt = {}) => {
      const el = document.getElementById(id);
      if (!el || typeof Chart === 'undefined') return;
      charts.push(new Chart(el, { type, data: { labels, datasets: ds }, options: { ...baseOpt, ...opt } }));
    };
    const pay = d.payment_breakdown || [];
    if (pay.length) {
      mk('ch-payments', 'doughnut', pay.map((p) => paymentLabel(p.payment_method)),
        doughnutDs(pay.map((p) => +p.total)), doughnutOpt);
    }
    const top = (d.top_products || []).slice(0, 10);
    if (top.length) {
      mk('ch-top', 'bar', top.map((p) => pn(p).slice(0, 18)),
        [{ data: top.map((p) => +p.revenue), backgroundColor: '#C9A227', borderRadius: 3 }],
        { indexAxis: 'y', plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true, grid: { display: false } }, y: { grid: { display: false } } } });
    }
    if (!yearly) {
      const rd = d.revenue_by_day || [];
      if (rd.length) mk('ch-day', 'line', rd.map((r) => fmtDay(r.day)),
        [{ label: t('revenue'), data: rd.map((r) => +r.revenue), borderColor: '#C9A227', backgroundColor: 'rgba(201,162,39,0.12)', fill: true, tension: 0.35, pointRadius: 2 }],
        { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } });
      const sc = d.sales_by_category || [];
      if (sc.length) mk('ch-cat', 'doughnut', sc.map((c) => cn(c)),
        doughnutDs(sc.map((c) => +c.revenue)), doughnutOpt);
      const cash = d.sales_by_cashier || [];
      if (cash.length) mk('ch-cashier', 'bar', cash.map((c) => (c.cashier_name || '—').slice(0, 14)),
        [{ data: cash.map((c) => +c.revenue), backgroundColor: '#1A1A2E', borderRadius: 3 }],
        { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, grid: { display: false } }, x: { grid: { color: 'rgba(0,0,0,0.06)' } } } });
      const mr = d.monthly_revenue || [];
      if (mr.length) mk('ch-monthly', 'bar', mr.map((m) => fmtMonth(m.month)),
        [{ data: mr.map((m) => +m.revenue), backgroundColor: '#4A6FA5', borderRadius: 3 }],
        { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true }, x: { grid: { display: false } } } });
    } else {
      const mb = d.monthly_breakdown || [];
      if (mb.length) mk('ch-month', 'bar', mb.map((m) => fmtMonth(m.month)),
        [{ data: mb.map((m) => +m.revenue), backgroundColor: '#1A1A2E', borderRadius: 3 }],
        { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true }, x: { grid: { display: false } } } });
    }
    charts.forEach((c) => c.update('none'));
  }

  async function exportPdf() {
    if (!reportCache?.data) {
      A().toast(A().t('noData'), true);
      return;
    }
    if (typeof window.ReportPdfExport === 'undefined' || typeof jspdf === 'undefined') {
      A().toast(A().t('pdfExportFailed'), true);
      return;
    }
    A().showLoader(true);
    try {
      charts.forEach((c) => c.update('none'));
      await new Promise((r) => setTimeout(r, 120));
      const build = await window.ReportPdfExport.export(reportCache);
      A().toast(`${A().t('pdfExportReady')} (${build || 'v4'})`);
    } catch (e) {
      A().toast(e.message || A().t('pdfExportFailed'), true);
    } finally {
      A().showLoader(false);
    }
  }

  function reloadReturns() {
    if (document.getElementById('ret-list')) fetchReturns(returnStatusFilter);
    else loadReturns();
  }

  window.PortalModules = { load, openSaleDetail, openReturnDetail, reloadReturns };

  // app.js s'exécute avant ce fichier : charger le panneau en attente après refresh
  if (window._pendingPanel) {
    load(window._pendingPanel);
    window._pendingPanel = null;
  } else {
    const main = document.getElementById('main-view');
    const content = document.getElementById('content-area');
    if (main && !main.classList.contains('hidden') && content && !content.innerHTML.trim()) {
      load('pos');
    }
  }
})();
