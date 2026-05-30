/** Export PDF rapports v4 — en-tête navy Flutter. */
window.ReportPdfExport = (() => {
  'use strict';

  const PDF_BUILD = '20260530-v4';

  const PRIMARY = [26, 26, 46];
  const PANEL = [37, 37, 66];
  const ACCENT = [201, 162, 39];
  const PHONE = [184, 184, 200];
  const SURFACE = [248, 246, 241];
  const MUTED = [107, 114, 128];
  const BORDER = [224, 224, 224];
  const MARGIN = 14;
  const PAGE_W = 210;
  const PAGE_H = 297;
  const FOOTER_H = 14;
  const CONTENT_W = PAGE_W - MARGIN * 2;

  const A = () => window.PortalApp;

  function fmtDateFr(iso) {
    if (!iso) return '—';
    const d = new Date(iso);
    return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  function nowLabel() {
    const loc = A().i18n?.getLang?.() === 'ar' ? 'ar-TD' : 'fr-FR';
    return new Date().toLocaleString(loc, {
      day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit',
    });
  }

  async function loadLogo() {
    try {
      const res = await fetch('assets/logo.jpg');
      const blob = await res.blob();
      return await new Promise((resolve) => {
        const fr = new FileReader();
        fr.onload = () => resolve(fr.result);
        fr.onerror = () => resolve(null);
        fr.readAsDataURL(blob);
      });
    } catch {
      return null;
    }
  }

  /** Logo circulaire sans carré noir JPEG — fond = couleur en-tête. */
  async function prepareCircularLogo(dataUrl, pxSize, bgRgb) {
    const img = await new Promise((resolve, reject) => {
      const el = new Image();
      el.onload = () => resolve(el);
      el.onerror = reject;
      el.src = dataUrl;
    });
    const canvas = document.createElement('canvas');
    canvas.width = pxSize;
    canvas.height = pxSize;
    const ctx = canvas.getContext('2d');
    const r = pxSize / 2;

    ctx.beginPath();
    ctx.arc(r, r, r - 1, 0, Math.PI * 2);
    ctx.fillStyle = `rgb(${bgRgb.join(',')})`;
    ctx.fill();

    ctx.save();
    ctx.beginPath();
    ctx.arc(r, r, r - 3, 0, Math.PI * 2);
    ctx.clip();
    const scale = Math.max(pxSize / img.width, pxSize / img.height);
    const w = img.width * scale;
    const h = img.height * scale;
    ctx.drawImage(img, r - w / 2, r - h / 2, w, h);

    try {
      const imgData = ctx.getImageData(0, 0, pxSize, pxSize);
      const [br, bg, bb] = bgRgb;
      for (let i = 0; i < imgData.data.length; i += 4) {
        const pr = imgData.data[i];
        const pg = imgData.data[i + 1];
        const pb = imgData.data[i + 2];
        const dx = (i / 4) % pxSize - r;
        const dy = Math.floor(i / 4 / pxSize) - r;
        const inCircle = dx * dx + dy * dy <= (r - 3) * (r - 3);
        if (!inCircle) {
          imgData.data[i + 3] = 0;
          continue;
        }
        if (pr < 55 && pg < 55 && pb < 55) {
          imgData.data[i] = br;
          imgData.data[i + 1] = bg;
          imgData.data[i + 2] = bb;
        }
      }
      ctx.putImageData(imgData, 0, 0);
    } catch {
      /* getImageData indisponible — clip circulaire suffit */
    }
    ctx.restore();

    ctx.beginPath();
    ctx.arc(r, r, r - 2, 0, Math.PI * 2);
    ctx.strokeStyle = `rgb(${ACCENT.join(',')})`;
    ctx.lineWidth = 3;
    ctx.stroke();

    return canvas.toDataURL('image/png');
  }

  function canvasMeta(id) {
    const el = document.getElementById(id);
    if (!el || !el.toDataURL) return null;
    try {
      return {
        data: el.toDataURL('image/png', 1.0),
        w: el.width || el.offsetWidth || 1,
        h: el.height || el.offsetHeight || 1,
      };
    } catch {
      return null;
    }
  }

  function maxY(doc) {
    return doc.internal.pageSize.getHeight() - FOOTER_H;
  }

  function newPageIfNeeded(doc, y, need) {
    if (y + need > maxY(doc)) {
      doc.addPage();
      return MARGIN;
    }
    return y;
  }

  function drawFooter(doc) {
    const pages = doc.internal.getNumberOfPages();
    const isAr = A().i18n?.getLang?.() === 'ar';
    for (let i = 1; i <= pages; i++) {
      doc.setPage(i);
      doc.setFontSize(8);
      doc.setTextColor(...MUTED);
      doc.text(
        isAr ? `تم الإنشاء: ${nowLabel()}` : `Généré le ${nowLabel()}`,
        MARGIN,
        PAGE_H - 8,
      );
      doc.text(
        isAr ? `صفحة ${i} / ${pages}` : `Page ${i} / ${pages}`,
        PAGE_W - MARGIN,
        PAGE_H - 8,
        { align: 'right' },
      );
    }
    doc.setTextColor(0, 0, 0);
  }

  /** En-tête navy — logo · boutique · encadré rapport (style app Flutter). */
  function drawHeader(doc, y, store, meta) {
    const isAr = A().i18n?.getLang?.() === 'ar';
    const name = isAr ? (store.name_ar || store.name_fr) : (store.name_fr || store.name_ar);
    const headerH = 50;
    const pad = 8;
    const logoSize = 26;
    const reportW = 76;
    const reportX = PAGE_W - MARGIN - reportW;
    const logoX = MARGIN + pad;
    const storeX = logoX + logoSize + 7;
    const storeMaxW = reportX - storeX - 8;

    doc.setFillColor(...PRIMARY);
    doc.roundedRect(MARGIN, y, CONTENT_W, headerH, 5, 5, 'F');

    const logoY = y + (headerH - logoSize) / 2;
    if (meta.logoCircle) {
      try {
        doc.addImage(meta.logoCircle, 'PNG', logoX, logoY, logoSize, logoSize, undefined, 'FAST');
      } catch { /* ignore */ }
    }

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(15);
    doc.setTextColor(255, 255, 255);
    doc.text(name || 'Souma Parfumerie', storeX, y + 17, { maxWidth: storeMaxW });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(...ACCENT);
    let lineY = y + 25;
    if (store.address) {
      doc.text(store.address, storeX, lineY, { maxWidth: storeMaxW });
      lineY += 7;
    }
    if (store.phone) {
      doc.setTextColor(...PHONE);
      doc.setFontSize(8.5);
      doc.text(`${isAr ? 'هاتف' : 'Tél.'} ${store.phone}`, storeX, lineY, { maxWidth: storeMaxW });
    }

    const panelY = y + pad;
    const panelH = headerH - pad * 2;
    doc.setFillColor(...PANEL);
    doc.setDrawColor(...ACCENT);
    doc.setLineWidth(0.45);
    doc.roundedRect(reportX, panelY, reportW, panelH, 3, 3, 'FD');

    const textRight = reportX + reportW - 7;
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9.5);
    doc.setTextColor(...ACCENT);
    doc.text(meta.title.toUpperCase(), textRight, panelY + 10, { align: 'right' });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(255, 255, 255);
    const subLines = doc.splitTextToSize(meta.subtitle, reportW - 14);
    doc.text(subLines, textRight, panelY + 17, { align: 'right' });

    const sepY = panelY + panelH - 15;
    doc.setDrawColor(...ACCENT);
    doc.setLineWidth(0.3);
    doc.line(reportX + 7, sepY, reportX + reportW - 7, sepY);

    doc.setFontSize(8.5);
    doc.setTextColor(255, 255, 255);
    doc.text(meta.period, textRight, panelY + panelH - 6, { align: 'right' });

    doc.setTextColor(0, 0, 0);
    doc.setFont('helvetica', 'normal');
    return y + headerH + 10;
  }

  function sectionTitle(doc, y, title, subtitle) {
    y = newPageIfNeeded(doc, y, subtitle ? 22 : 16);
    doc.setFillColor(...ACCENT);
    doc.rect(MARGIN, y, 3.5, 12, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.setTextColor(...PRIMARY);
    doc.text(title, MARGIN + 8, y + 9);
    doc.setFont('helvetica', 'normal');
    if (subtitle) {
      doc.setFontSize(8);
      doc.setTextColor(...MUTED);
      doc.text(subtitle, MARGIN + 8, y + 15);
      y += 6;
    }
    doc.setTextColor(0, 0, 0);
    return y + 16;
  }

  function kpiGrid(doc, y, items) {
    y = newPageIfNeeded(doc, y, 28);
    const cols = 3;
    const gap = 4;
    const cellW = (CONTENT_W - gap * (cols - 1)) / cols;
    const cellH = 22;
    const rows = Math.ceil(items.length / cols);

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const idx = r * cols + c;
        if (idx >= items.length) break;
        const item = items[idx];
        const x = MARGIN + c * (cellW + gap);
        const cy = y + r * (cellH + gap);

        doc.setFillColor(...(item.highlight ? [245, 237, 214] : SURFACE));
        doc.setDrawColor(...(item.highlight ? ACCENT : BORDER));
        doc.setLineWidth(item.highlight ? 0.5 : 0.25);
        doc.roundedRect(x, cy, cellW, cellH, 2, 2, 'FD');

        doc.setFontSize(7);
        doc.setTextColor(...MUTED);
        doc.text(item.label.toUpperCase(), x + 4, cy + 7, { maxWidth: cellW - 8 });

        doc.setFont('helvetica', 'bold');
        doc.setFontSize(item.highlight ? 11 : 10);
        doc.setTextColor(...PRIMARY);
        doc.text(item.value, x + 4, cy + 16, { maxWidth: cellW - 8 });
        doc.setFont('helvetica', 'normal');
      }
    }
    return y + rows * (cellH + gap) + 6;
  }

  function dataTable(doc, y, head, body) {
    if (!body?.length) return y;
    y = newPageIfNeeded(doc, y, 18);
    doc.autoTable({
      startY: y,
      margin: { left: MARGIN, right: MARGIN },
      head: [head],
      body,
      styles: { font: 'helvetica', fontSize: 8, cellPadding: 3, lineColor: BORDER, lineWidth: 0.1 },
      headStyles: {
        fillColor: PRIMARY,
        textColor: [255, 255, 255],
        fontStyle: 'bold',
        fontSize: 7.5,
        halign: 'left',
      },
      alternateRowStyles: { fillColor: SURFACE },
      theme: 'grid',
    });
    return doc.lastAutoTable.finalY + 8;
  }

  function chartBlock(doc, y, canvasId, title, subtitle) {
    const meta = canvasMeta(canvasId);
    if (!meta) return y;

    y = sectionTitle(doc, y, title, subtitle);

    const pad = 5;
    const maxInnerW = CONTENT_W - pad * 2;
    const maxInnerH = 58;
    let imgW = maxInnerW;
    let imgH = imgW * (meta.h / meta.w);
    if (imgH > maxInnerH) {
      imgH = maxInnerH;
      imgW = imgH * (meta.w / meta.h);
    }
    const boxH = imgH + pad * 2;

    y = newPageIfNeeded(doc, y, boxH + 4);
    doc.setFillColor(...SURFACE);
    doc.setDrawColor(...BORDER);
    doc.setLineWidth(0.25);
    doc.roundedRect(MARGIN, y, CONTENT_W, boxH, 3, 3, 'FD');

    const imgX = MARGIN + (CONTENT_W - imgW) / 2;
    try {
      doc.addImage(meta.data, 'PNG', imgX, y + pad, imgW, imgH, undefined, 'FAST');
    } catch { /* ignore */ }

    return y + boxH + 12;
  }

  function sectionWithChartAndTable(doc, y, canvasId, title, head, body, subtitle) {
    y = chartBlock(doc, y, canvasId, title, subtitle);
    if (body?.length) y = dataTable(doc, y, head, body);
    return y;
  }

  async function exportReport(cache) {
    if (!cache?.data || typeof jspdf === 'undefined') {
      throw new Error(A().t('noData'));
    }
    const { jsPDF } = jspdf;
    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
    const t = A().t;
    const pn = A().pn;
    const cn = A().cn;
    const fmtMoney = A().fmtMoney;
    const paymentLabel = A().paymentLabel;
    const isAr = A().i18n?.getLang?.() === 'ar';

    const settings = (await A().api('/manager/settings')).data || {};
    const logoRaw = await loadLogo();
    let logoCircle = null;
    if (logoRaw) {
      try {
        logoCircle = await prepareCircularLogo(logoRaw, 256, [...PRIMARY]);
      } catch { /* ignore */ }
    }
    const d = cache.data;
    const s = d.summary || {};

    let meta;
    if (cache.yearly) {
      meta = {
        title: isAr ? 'تقرير سنوي' : 'Rapport annuel',
        subtitle: isAr ? `سنة ${d.year}` : `Année ${d.year}`,
        period: `01/01/${d.year} - 31/12/${d.year}`,
        logoCircle,
      };
    } else {
      meta = {
        title: isAr ? 'تقرير المبيعات' : 'Rapport ventes',
        subtitle: isAr ? 'الإيرادات والمصروفات' : 'Recettes, dépenses et caissiers',
        period: `${fmtDateFr(cache.from)} - ${fmtDateFr(cache.to)}`,
        logoCircle,
      };
    }

    let y = drawHeader(doc, MARGIN, settings, meta);

    if (cache.yearly) {
      const cmp = d.comparison || {};
      const prevRev = cmp.previous?.revenue;
      const curRev = cmp.current?.revenue ?? s.revenue;
      let yoy = '';
      if (prevRev > 0) {
        const pct = ((Number(curRev) - Number(prevRev)) / Number(prevRev)) * 100;
        yoy = `${pct >= 0 ? '+' : ''}${pct.toFixed(1)} % vs ${d.year - 1}`;
      }

      y = kpiGrid(doc, y, [
        { label: t('revenue'), value: fmtMoney(s.revenue), highlight: true },
        { label: t('transactions'), value: String(s.transactions ?? 0), highlight: false },
        { label: t('avgBasket'), value: fmtMoney(s.avg_basket), highlight: false },
        { label: t('profit'), value: fmtMoney(d.profit), highlight: true },
        { label: t('expenses'), value: fmtMoney(d.expenses?.total), highlight: false },
        ...(yoy ? [{ label: t('annualComparison'), value: yoy, highlight: true }] : []),
      ]);

      const monthRows = (d.monthly_breakdown || []).map((m) => [
        A().fmtMonth(m.month),
        String(m.transactions ?? 0),
        fmtMoney(m.revenue),
        fmtMoney(m.avg_basket),
      ]);

      y = sectionWithChartAndTable(
        doc, y, 'ch-month', t('monthlyDetail'),
        [t('date'), t('transactions'), t('revenue'), t('avgBasket')],
        monthRows,
        isAr ? 'من يناير إلى ديسمبر' : 'Janvier à décembre',
      );

      const payRows = (d.payment_breakdown || []).map((p) => [
        paymentLabel(p.payment_method),
        String(p.transactions ?? 0),
        fmtMoney(p.total),
      ]);
      y = sectionWithChartAndTable(
        doc, y, 'ch-payments', t('payments'),
        [t('payment'), t('transactions'), t('amount')],
        payRows,
      );

      const topRows = (d.top_products || []).slice(0, 15).map((p, i) => [
        String(i + 1),
        pn(p),
        String(p.qty_sold ?? 0),
        fmtMoney(p.revenue),
      ]);
      y = sectionWithChartAndTable(
        doc, y, 'ch-top', t('topProducts'),
        ['#', t('product'), t('qty'), t('amount')],
        topRows,
        isAr ? 'الأكثر مبيعاً' : 'Classés par quantité vendue',
      );
    } else {
      y = kpiGrid(doc, y, [
        { label: t('revenue'), value: fmtMoney(s.revenue), highlight: true },
        { label: t('profit'), value: fmtMoney(d.profit), highlight: true },
        { label: t('transactions'), value: String(s.transactions ?? 0), highlight: false },
        { label: t('avgBasket'), value: fmtMoney(s.avg_basket), highlight: false },
        { label: t('expenses'), value: fmtMoney(d.expenses?.total), highlight: false },
        { label: t('discounts'), value: fmtMoney(s.total_discounts), highlight: false },
      ]);

      const cmp = d.comparison || {};
      y = sectionTitle(doc, y, t('comparison'));
      y = dataTable(doc, y,
        [t('comparison'), t('revenue'), t('transactions')],
        [
          [t('currentPeriod'), fmtMoney(cmp.current?.revenue), String(cmp.current?.transactions ?? 0)],
          [t('previousPeriod'), fmtMoney(cmp.previous?.revenue), String(cmp.previous?.transactions ?? 0)],
        ],
      );

      const rs = d.returns;
      if (rs && (rs.requested > 0 || rs.pending > 0 || rs.approved > 0 || rs.rejected > 0)) {
        y = sectionTitle(doc, y, t('returnsPeriod'));
        y = dataTable(doc, y,
          [t('status'), t('qty'), t('amount')],
          [
            [t('requested'), String(rs.requested ?? 0), '—'],
            [t('pending'), String(rs.pending ?? 0), '—'],
            [t('approved'), String(rs.approved ?? 0), fmtMoney(rs.approved_amount)],
            [t('rejected'), String(rs.rejected ?? 0), '—'],
          ],
        );
      }

      const catRows = (d.sales_by_category || []).map((c) => [cn(c), fmtMoney(c.revenue)]);
      y = sectionWithChartAndTable(
        doc, y, 'ch-cat', t('byCategory'),
        [t('category'), t('amount')],
        catRows,
      );

      const payRows = (d.payment_breakdown || []).map((p) => [
        paymentLabel(p.payment_method),
        String(p.transactions ?? 0),
        fmtMoney(p.total),
      ]);
      y = sectionWithChartAndTable(
        doc, y, 'ch-payments', t('payments'),
        [t('payment'), t('transactions'), t('amount')],
        payRows,
      );

      y = chartBlock(doc, y, 'ch-day', t('revenueByDay'));

      const cashRows = (d.sales_by_cashier || []).map((c) => [
        c.cashier_name || '—',
        String(c.transactions ?? 0),
        fmtMoney(c.revenue),
      ]);
      y = sectionWithChartAndTable(
        doc, y, 'ch-cashier', t('byCashier'),
        [t('cashier'), t('transactions'), t('amount')],
        cashRows,
      );

      y = chartBlock(doc, y, 'ch-monthly', t('monthlyRevenue'), isAr ? 'الإيرادات حسب الشهر' : 'Recettes par mois');

      const topRows = (d.top_products || []).slice(0, 15).map((p, i) => [
        String(i + 1),
        pn(p),
        String(p.qty_sold ?? 0),
        fmtMoney(p.revenue),
      ]);
      y = sectionWithChartAndTable(
        doc, y, 'ch-top', t('topProducts'),
        ['#', t('product'), t('qty'), t('amount')],
        topRows,
      );
    }

    doc.setFontSize(7);
    doc.setTextColor(...MUTED);
    y = newPageIfNeeded(doc, y, 10);
    doc.text(
      isAr ? '© Expérience Tech' : 'Document généré par Souma Parfumerie — © Expérience Tech',
      PAGE_W / 2,
      y + 4,
      { align: 'center' },
    );

    drawFooter(doc);

    const fname = cache.yearly
      ? `souma-rapport-${d.year}.pdf`
      : `souma-rapport-${cache.from}_${cache.to}.pdf`;
    doc.save(fname);
    return PDF_BUILD;
  }

  return { export: exportReport, build: PDF_BUILD };
})();
