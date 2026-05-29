(() => {
  'use strict';

  const API_BASE = new URL('../api', window.location.href).href.replace(/\/$/, '');
  const STORAGE_TOKEN = 'souma_manager_token';
  const STORAGE_USER = 'souma_manager_user';
  const STORAGE_REMEMBER_USER = 'souma_manager_remember_username';
  const STORAGE_SAVED_USERNAME = 'souma_manager_saved_username';
  const i18n = window.ManagerI18n;
  const t = i18n.t;
  const pn = i18n.productName;
  const cn = i18n.categoryName;

  let currentReturnId = null;
  const DEFAULT_PANEL = 'pos';
  let currentPanel = DEFAULT_PANEL;
  let menuBadges = { alerts: 0, returns: 0 };

  const ICONS = {
    pos: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 18c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zM1 2v2h2l3.6 7.59-1.35 2.45c-.16.28-.25.61-.25.96 0 1.1.9 2 2 2h12v-2H7.42c-.14 0-.25-.11-.25-.25l.03-.12.9-1.63h7.45c.75 0 1.41-.41 1.75-1.03l3.58-6.49A1 1 0 0020 4H5.21l-.94-2H1zm16 16c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z" fill="currentColor"/></svg>',
    products: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M21 8l-9-5-9 5v10l9 5 9-5V8zm-9 1.49l6.16 3.43L12 16.35 5.84 12.92 12 9.49zM5 10.36l6 3.35v6.49l-6-3.34v-6.5zm14 3.35v6.5l-6 3.34v-6.49l6-3.35z" fill="currentColor"/></svg>',
    categories: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M10 4H4c-1.1 0-2 .9-2 2v6c0 1.1.9 2 2 2h6c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm10 0h-6c-1.1 0-2 .9-2 2v6c0 1.1.9 2 2 2h6c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zM10 14H4c-1.1 0-2 .9-2 2v6c0 1.1.9 2 2 2h6c1.1 0 2-.9 2-2v-6c0-1.1-.9-2-2-2zm10 0h-6c-1.1 0-2 .9-2 2v6c0 1.1.9 2 2 2h6c1.1 0 2-.9 2-2v-6c0-1.1-.9-2-2-2z" fill="currentColor"/></svg>',
    alerts: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z" fill="currentColor"/></svg>',
    sales: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 14H7v-2h5v2zm5-4H7v-2h10v2zm0-4H7V7h10v2z" fill="currentColor"/></svg>',
    returns: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0020 13c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 004 13c0 4.42 3.58 8 8 8v4l5-5-5-5v4z" fill="currentColor"/></svg>',
    clients: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" fill="currentColor"/></svg>',
    expenses: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" fill="currentColor"/></svg>',
    reports: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 9.2h3V19H5V9.2zM10.6 5h2.8v14h-2.8V5zm5.6 8H19v6h-2.8v-6z" fill="currentColor"/></svg>',
    suppliers: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 8h-3V4H3c-1.1 0-2 .9-2 2v11h2c0 1.66 1.34 3 3 3s3-1.34 3-3h6c0 1.66 1.34 3 3 3s3-1.34 3-3h2v-5l-3-4zm-6 0H5V6h9v2zm-9 11.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm12 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z" fill="currentColor"/></svg>',
    users: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4zm7.5-6.5a2.5 2.5 0 010-5 2.5 2.5 0 010 5zM5.5 8.5a2.5 2.5 0 010-5 2.5 2.5 0 010 5z" fill="currentColor"/></svg>',
    settings: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M19.14 12.94c.04-.31.06-.63.06-.94 0-.31-.02-.63-.06-.94l2.03-1.58a.49.49 0 00.12-.61l-1.92-3.32a.488.488 0 00-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54a.484.484 0 00-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.04.31-.06.63-.06.94s.02.63.06.94l-2.03 1.58a.49.49 0 00-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z" fill="currentColor"/></svg>',
  };

  const NAV = [
    { id: 'pos', i18n: 'navPos', icon: 'pos' },
    { id: 'products', i18n: 'navProducts', icon: 'products' },
    { id: 'categories', i18n: 'navCategories', icon: 'categories' },
    { id: 'alerts', i18n: 'navAlerts', icon: 'alerts', badge: 'alerts' },
    { id: 'sales', i18n: 'navSales', icon: 'sales' },
    { id: 'returns', i18n: 'navReturns', icon: 'returns', badge: 'returns' },
    { id: 'clients', i18n: 'navClients', icon: 'clients' },
    { id: 'expenses', i18n: 'navExpenses', icon: 'expenses' },
    { id: 'reports', i18n: 'navReports', icon: 'reports' },
    { id: 'suppliers', i18n: 'navSuppliers', icon: 'suppliers' },
    { id: 'users', i18n: 'navUsers', icon: 'users' },
    { id: 'settings', i18n: 'navSettings', icon: 'settings' },
  ];

  const NAV_GROUPS = [
    { label: 'navGroupShop', items: ['pos', 'products', 'categories', 'alerts'] },
    { label: 'navGroupSales', items: ['sales', 'returns', 'clients'] },
    { label: 'navGroupFinance', items: ['expenses', 'reports'] },
    { label: 'navGroupAdmin', items: ['suppliers', 'users', 'settings'] },
  ];
  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => document.querySelectorAll(sel);

  const fmtMoney = (v) => {
    const n = Number(v) || 0;
    const loc = i18n.getLang() === 'ar' ? 'ar-TD' : 'fr-FR';
    return n.toLocaleString(loc, { maximumFractionDigits: 0 }) + ' FCFA';
  };

  const fmtDate = (iso) => {
    if (!iso) return '—';
    const loc = i18n.getLang() === 'ar' ? 'ar-TD' : 'fr-FR';
    return new Date(iso).toLocaleString(loc, {
      day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
    });
  };

  const fmtDay = (iso) => {
    if (!iso) return '—';
    const loc = i18n.getLang() === 'ar' ? 'ar-TD' : 'fr-FR';
    return new Date(iso).toLocaleDateString(loc, { day: '2-digit', month: 'short', year: 'numeric' });
  };

  const fmtMonth = (iso) => {
    if (!iso) return '—';
    const loc = i18n.getLang() === 'ar' ? 'ar-TD' : 'fr-FR';
    return new Date(iso).toLocaleDateString(loc, { month: 'long', year: 'numeric' });
  };

  const paymentLabel = (m) => ({
    cash: t('paymentCash'), card: t('paymentCard'), mobile: t('paymentMobile'), mixed: t('paymentMixed'),
  }[m] || m || '—');

  const today = () => new Date().toISOString().slice(0, 10);
  const daysAgo = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return d.toISOString().slice(0, 10); };
  const esc = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

  window.PortalApp = {
    api, t, pn, cn, fmtMoney, fmtDate, fmtDay, fmtMonth, paymentLabel,
    today, daysAgo, esc, showLoader, toast, $, $$, getToken, getUser,
    setReturnId: (id) => { currentReturnId = id; },
  };

  function showLoader(on) { $('#loader').classList.toggle('hidden', !on); }

  function toast(msg, isError = false) {
    const el = $('#toast');
    el.textContent = msg;
    el.classList.toggle('error', isError);
    el.classList.remove('hidden');
    setTimeout(() => el.classList.add('hidden'), 3500);
  }

  function getToken() { return localStorage.getItem(STORAGE_TOKEN); }
  function getUser() {
    try { return JSON.parse(localStorage.getItem(STORAGE_USER) || 'null'); } catch { return null; }
  }
  function saveSession(token, user) {
    localStorage.setItem(STORAGE_TOKEN, token);
    localStorage.setItem(STORAGE_USER, JSON.stringify(user));
  }
  function clearSession() {
    localStorage.removeItem(STORAGE_TOKEN);
    localStorage.removeItem(STORAGE_USER);
  }

  async function api(path, options = {}) {
    const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;
    const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
    const data = await res.json().catch(() => ({}));
    if (res.status === 401) { clearSession(); showLogin(); throw new Error(t('sessionExpired')); }
    if (!res.ok || data.success === false) throw new Error(data.message || `Erreur ${res.status}`);
    return data;
  }

  function showLogin() {
    $('#login-view').classList.remove('hidden');
    $('#main-view').classList.add('hidden');
  }

  function showMain() {
    $('#login-view').classList.add('hidden');
    $('#main-view').classList.remove('hidden');
    const user = getUser();
    if (user) {
      const name = user.full_name || user.username;
      $('#user-name').textContent = name;
      const sideUser = $('#sidebar-user-name');
      if (sideUser) sideUser.textContent = name;
    }
  }

  function navItemHtml(item) {
    const badge = item.badge && menuBadges[item.badge] > 0
      ? `<span class="sidebar-badge">${menuBadges[item.badge] > 99 ? '99+' : menuBadges[item.badge]}</span>` : '';
    const active = item.id === currentPanel ? ' active' : '';
    const icon = ICONS[item.icon] || '';
    return `<button type="button" class="sidebar-link${active}" data-panel="${item.id}">
      <span class="sidebar-icon">${icon}</span>
      <span class="sidebar-label" data-i18n="${item.i18n}">${t(item.i18n)}</span>${badge}
    </button>`;
  }

  function panelTitle(panel) {
    const item = NAV.find((n) => n.id === panel);
    return item ? t(item.i18n) : '';
  }

  function setPageTitle(panel) {
    const el = $('#page-title');
    if (!el) return;
    const label = panelTitle(panel);
    el.textContent = label;
    el.classList.toggle('hidden', !label);
  }

  function closeSidebar() {
    const sidebar = $('#sidebar');
    const backdrop = $('#sidebar-backdrop');
    sidebar?.classList.remove('open');
    backdrop?.classList.add('hidden');
    backdrop?.setAttribute('aria-hidden', 'true');
    document.body.classList.remove('sidebar-open');
  }

  function openSidebar() {
    const sidebar = $('#sidebar');
    const backdrop = $('#sidebar-backdrop');
    sidebar?.classList.add('open');
    backdrop?.classList.remove('hidden');
    backdrop?.setAttribute('aria-hidden', 'false');
    document.body.classList.add('sidebar-open');
  }

  function isMobileNav() {
    return window.matchMedia('(max-width: 768px)').matches;
  }

  function buildSidebar() {
    const nav = $('#sidebar-nav');
    if (!nav) return;
    const byId = Object.fromEntries(NAV.map((n) => [n.id, n]));
    nav.innerHTML = NAV_GROUPS.map((group) => {
      const items = group.items.map((id) => byId[id]).filter(Boolean);
      if (!items.length) return '';
      return `<div class="sidebar-group">
        <div class="sidebar-group-label" data-i18n="${group.label}">${t(group.label)}</div>
        <div class="sidebar-group-items">${items.map(navItemHtml).join('')}</div>
      </div>`;
    }).join('');
    $$('.sidebar-link').forEach((btn) => {
      btn.onclick = () => switchPanel(btn.dataset.panel);
    });
    setPageTitle(currentPanel);
    i18n.init();
  }

  async function refreshMenuBadges() {
    try {
      const { data } = await api('/manager/menu');
      menuBadges = data;
      buildSidebar();
    } catch (_) { /* ignore */ }
  }

  function switchPanel(panel) {
    currentPanel = panel;
    $$('.sidebar-link').forEach((b) => b.classList.toggle('active', b.dataset.panel === panel));
    setPageTitle(panel);
    if (isMobileNav()) closeSidebar();
    if (window.PortalModules) {
      window.PortalModules.load(panel);
      window._pendingPanel = null;
    } else {
      window._pendingPanel = panel;
    }
  }

  function flushPendingPanel() {
    const panel = window._pendingPanel;
    if (!panel || !window.PortalModules) return;
    window._pendingPanel = null;
    window.PortalModules.load(panel);
  }

  function loadRememberedUsername() {
    const remember = localStorage.getItem(STORAGE_REMEMBER_USER) !== '0';
    const checkbox = $('#remember-username');
    if (checkbox) checkbox.checked = remember;
    if (remember) {
      const saved = localStorage.getItem(STORAGE_SAVED_USERNAME);
      if (saved) $('#username').value = saved;
    }
  }

  function persistRememberedUsername(username) {
    const remember = $('#remember-username')?.checked ?? false;
    if (remember) {
      localStorage.setItem(STORAGE_REMEMBER_USER, '1');
      localStorage.setItem(STORAGE_SAVED_USERNAME, username);
    } else {
      localStorage.setItem(STORAGE_REMEMBER_USER, '0');
      localStorage.removeItem(STORAGE_SAVED_USERNAME);
    }
  }

  async function login(username, password) {
    const data = await api('/auth/login', { method: 'POST', body: JSON.stringify({ username, password }) });
    if (data.user?.role !== 'manager') throw new Error(t('managerOnly'));
    persistRememberedUsername(username);
    saveSession(data.token, data.user);
    showMain();
    buildSidebar();
    refreshMenuBadges();
    switchPanel(DEFAULT_PANEL);
  }

  async function approveReturn() {
    if (!currentReturnId) return;
    showLoader(true);
    try {
      await api('/manager/returns/approve', { method: 'POST', body: JSON.stringify({ sale_id: currentReturnId }) });
      $('#detail-modal').close();
      toast(t('returnApproved'));
      if (window.PortalModules?.reloadReturns) window.PortalModules.reloadReturns();
      else if (window.PortalModules) window.PortalModules.load('returns');
      refreshMenuBadges();
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  async function rejectReturn() {
    if (!currentReturnId || !confirm(t('rejectConfirm'))) return;
    showLoader(true);
    try {
      await api('/manager/returns/reject', { method: 'POST', body: JSON.stringify({ sale_id: currentReturnId }) });
      $('#detail-modal').close();
      toast(t('returnRejected'));
      if (window.PortalModules?.reloadReturns) window.PortalModules.reloadReturns();
      else if (window.PortalModules) window.PortalModules.load('returns');
      refreshMenuBadges();
    } catch (e) { toast(e.message, true); }
    finally { showLoader(false); }
  }

  function setupLangButtons() {
    $$('.lang-btn').forEach((btn) => {
      btn.onclick = () => {
        i18n.setLang(btn.dataset.lang);
        $$('.lang-btn').forEach((b) => b.classList.toggle('active', b.dataset.lang === btn.dataset.lang));
        if (!$('#main-view').classList.contains('hidden')) switchPanel(currentPanel);
      };
    });
  }

  function initEvents() {
    const passwordInput = $('#password');
    const passwordToggle = $('#password-toggle');
    if (passwordToggle && passwordInput) {
      passwordToggle.onclick = () => {
        const visible = passwordInput.type === 'text';
        passwordInput.type = visible ? 'password' : 'text';
        passwordToggle.setAttribute('aria-pressed', visible ? 'false' : 'true');
        passwordToggle.setAttribute('aria-label', visible ? t('showPassword') : t('hidePassword'));
        passwordToggle.querySelector('.icon-eye-open')?.classList.toggle('hidden', !visible);
        passwordToggle.querySelector('.icon-eye-closed')?.classList.toggle('hidden', visible);
      };
      passwordToggle.setAttribute('aria-label', t('showPassword'));
      passwordToggle.tabIndex = 0;
    }

    $('#login-form').onsubmit = async (e) => {
      e.preventDefault();
      $('#login-error').classList.add('hidden');
      $('#login-btn').disabled = true;
      try {
        await login($('#username').value.trim(), $('#password').value);
      } catch (ex) {
        $('#login-error').textContent = ex.message;
        $('#login-error').classList.remove('hidden');
      } finally { $('#login-btn').disabled = false; }
    };

    const doLogout = () => { closeSidebar(); clearSession(); showLogin(); };
    $$('.logout-btn').forEach((btn) => { btn.onclick = doLogout; });
    $('#sidebar-toggle')?.addEventListener('click', () => {
      if ($('#sidebar')?.classList.contains('open')) closeSidebar();
      else openSidebar();
    });
    $('#sidebar-backdrop')?.addEventListener('click', closeSidebar);

    $$('.modal-close').forEach((b) => { b.onclick = () => $('#detail-modal').close(); });
    $('#modal-approve').onclick = approveReturn;
    $('#modal-reject').onclick = rejectReturn;
    $('#detail-modal').onclick = (e) => { if (e.target === $('#detail-modal')) $('#detail-modal').close(); };

    $('#form-modal-save').onclick = async () => {
      if (window._formSaveHandler) await window._formSaveHandler();
    };
    $$('.form-modal-close').forEach((b) => { b.onclick = () => $('#form-modal').close(); });
  }

  function init() {
    window._formSaveHandler = null;
    i18n.init();
    setupLangButtons();
    initEvents();
    loadRememberedUsername();
    if (getToken() && getUser()?.role === 'manager') {
      showMain();
      buildSidebar();
      refreshMenuBadges();
      switchPanel(DEFAULT_PANEL);
    } else showLogin();
  }

  init();
})();
