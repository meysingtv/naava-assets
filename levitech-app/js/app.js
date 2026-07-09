/* ==========================================================================
   LEVITECH — App-Logik: Rendering, Routing, Interaktionen
   ========================================================================== */

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];

/* ---------- kleine Helfer ---------- */
function el(html) { const t = document.createElement('template'); t.innerHTML = html.trim(); return t.content.firstElementChild; }

function toast(msg) {
  let t = $('#toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(t._t);
  t._t = setTimeout(() => t.classList.remove('show'), 1900);
}

/* ==========================================================================
   SCREEN-RENDERER
   ========================================================================== */
const Screens = {

  /* ---- 01 Dashboard ---- */
  dashboard() {
    const s = Screens._new('dashboard');
    s.innerHTML = `
      <div class="app-header">
        <div class="brand">
          <div class="logo">Ł</div>
          <div class="name">LEVITECH</div>
        </div>
        <div class="avatar"><span class="badge">3</span></div>
      </div>

      <div class="hero">
        <div class="hi">Guten Morgen,</div>
        <div class="who">${DATA.user.name}! 👋</div>
        <div class="clock-row">
          <div>
            <div class="lbl">Eingestempelt seit</div>
            <div class="val live">${DATA.user.checkedInSince}</div>
          </div>
          <button class="btn btn-red" onclick="actions.stamp(this)">Ausstempeln</button>
        </div>
      </div>

      <div class="stat-grid">
        ${DATA.dashboardStats.map(x => `
          <div class="stat ${x.cls}"><div class="n">${x.n}</div><div class="l">${x.l}</div></div>`).join('')}
      </div>

      <div class="section-head"><h3>Nächster Termin</h3></div>
      <div class="card">
        <div class="appt">
          <div class="time">${DATA.nextAppt.time}</div>
          <div class="info">
            <div class="t">${DATA.nextAppt.title}</div>
            <div class="s">${DATA.nextAppt.sub}</div>
            <div class="a">${DATA.nextAppt.addr}</div>
          </div>
          <div class="go" onclick="toast('Navigation gestartet…')">${icon('nav')}</div>
        </div>
      </div>

      <div class="section-head"><h3>Aktuelle TimeCard</h3></div>
      <div class="card timecard-row">
        <div class="metrics">
          <div class="metric"><div class="k">Arbeitszeit heute</div><div class="v">${DATA.timecardToday.work}</div></div>
          <div class="metric"><div class="k">Pause</div><div class="v">${DATA.timecardToday.pause}</div></div>
        </div>
        ${ring(DATA.timecardToday.pct, 'Ziel erreicht')}
      </div>`;
    return s;
  },

  /* ---- 02 Tickets ---- */
  tickets() {
    const s = Screens._new('tickets');
    const filters = ['Meine Tickets', 'Offen', 'Neu', 'Dringend'];
    s.innerHTML = `
      <h1 class="page-title">Tickets</h1>
      <div class="search">${icon('search')}<input placeholder="Suchen" oninput="actions.filterTickets(this.value)"></div>
      <div class="chips">
        ${filters.map((f, i) => `<button class="chip ${i === 0 ? 'active' : ''}" onclick="actions.chip(this)">${f}</button>`).join('')}
      </div>
      <div id="ticketList">${DATA.tickets.map(ticketCard).join('')}</div>`;
    return s;
  },

  /* ---- 03 Ticket Details ---- */
  ticketDetail() {
    const s = Screens._new('ticketDetail');
    const t = DATA.ticketDetail;
    s.innerHTML = `
      <div class="detail-head">
        <button class="link-back" onclick="nav.go('tickets')">${icon('back')} Zurück</button>
        <span class="badge-pill b-${t.prio}">${t.prioLabel}</span>
      </div>
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:2px">
        <span class="tiny muted">${t.id}</span>
      </div>
      <h1 class="page-title" style="margin-top:2px">${t.title}</h1>
      <div class="muted" style="margin-top:-10px;margin-bottom:8px">${t.cust}</div>

      <div class="tabs">
        <div class="tab active" onclick="actions.tab(this)">Details</div>
        <div class="tab" onclick="actions.tab(this)">Verlauf</div>
        <div class="tab" onclick="actions.tab(this)">Anhänge</div>
        <div class="tab" onclick="actions.tab(this)">Zeiten</div>
      </div>

      <div class="card">
        <div class="tiny muted" style="margin-bottom:6px">Kunde</div>
        <div style="font-weight:700;font-size:16px;margin-bottom:10px">${t.cust}</div>
        <div class="tiny muted">Ansprechpartner</div>
        <div class="contact-line">${icon('user')} ${t.contactName}
          <span style="margin-left:auto">${icon('phone')} ${t.phone}</span></div>
        <div class="contact-line">${icon('mail')} ${t.email}</div>
        <div class="tiny muted" style="margin-top:8px">Adresse</div>
        <div class="contact-line">${icon('pin')} ${t.address.join(', ')}</div>
        <div style="display:flex;gap:10px;margin-top:14px">
          <button class="btn btn-ghost btn-full" onclick="toast('Anruf wird gestartet…')">${icon('phone')} Anrufen</button>
          <button class="btn btn-ghost btn-full" onclick="toast('Navigation gestartet…')">${icon('nav')} Navigation</button>
        </div>
      </div>

      <div class="card">
        <div class="tiny muted" style="margin-bottom:6px">Beschreibung</div>
        <div style="font-size:14px;line-height:1.5">${t.description}</div>
        <div style="margin-top:12px">
          <div class="kv"><span class="k">Priorität</span><span class="v red">${t.priority}</span></div>
          <div class="kv"><span class="k">SLA</span><span class="v">${t.sla}</span></div>
          <div class="kv"><span class="k">Erstellt am</span><span class="v">${t.created}</span></div>
          <div class="kv"><span class="k">Status</span><span class="v red">${t.status}</span></div>
        </div>
      </div>

      <button class="btn btn-red btn-full btn-lg" onclick="nav.go('ticketEdit')">Arbeitsbeginn</button>`;
    return s;
  },

  /* ---- 04 Ticket bearbeiten ---- */
  ticketEdit() {
    const s = Screens._new('ticketEdit');
    const t = DATA.ticketDetail;
    s.innerHTML = `
      <div class="detail-head">
        <button class="icon-btn" onclick="nav.go('ticketDetail')">${icon('back')}</button>
        <div style="text-align:center;flex:1">
          <div style="font-weight:800;font-size:17px">Ticket bearbeiten</div>
          <div class="tiny muted">${t.id}</div>
        </div>
        <div style="width:40px"></div>
      </div>

      <div class="timer-card">
        <div class="tt">${icon('clock')} Arbeitszeit läuft</div>
        <div class="big" id="workTimer">00:35:42</div>
        <div class="run">— Arbeitszeit läuft</div>
      </div>

      <div class="card action-list">
        ${DATA.ticketActions.map(a => `
          <div class="row" onclick="actions.ticketAction('${a.label}')">
            <span class="ic">${icon(a.icon)}</span>
            <span class="lbl">${a.label}</span>
            ${a.count ? `<span class="cnt">${a.count}</span>` : ''}
            ${a.chev || a.count ? '' : ''}
            <span class="chev">${icon('chev')}</span>
          </div>`).join('')}
      </div>

      <button class="btn btn-red btn-full btn-lg" onclick="actions.saveTicket()">Speichern</button>`;
    Screens._startTimer();
    return s;
  },

  /* ---- 05 Kundenübersicht ---- */
  customer() {
    const s = Screens._new('customer');
    const c = DATA.customer;
    s.innerHTML = `
      <div class="detail-head">
        <button class="cust-hero" style="border:none;background:none;padding:0;cursor:default">
          <span class="lg">${icon('building')}</span>
          <span style="text-align:left"><span class="nm" style="display:block">${c.name}</span>
          <span class="since">${c.since}</span></span>
        </button>
        <button class="icon-btn" onclick="toast('Zu Favoriten')" style="background:none;border:none">${icon('star')}</button>
      </div>

      <div class="quick-actions">
        <div class="qa" onclick="toast('Anruf…')"><div class="c">${icon('phone')}</div><div class="t">Anrufen</div></div>
        <div class="qa" onclick="toast('Mail…')"><div class="c">${icon('mail')}</div><div class="t">Mail</div></div>
        <div class="qa" onclick="toast('Navigation…')"><div class="c">${icon('nav')}</div><div class="t">Navigation</div></div>
        <div class="qa" onclick="toast('Website…')"><div class="c">${icon('web')}</div><div class="t">Website</div></div>
        <div class="qa" onclick="toast('Mehr…')"><div class="c">${icon('dots')}</div><div class="t">Mehr</div></div>
      </div>

      <div class="tabs">
        <div class="tab active" onclick="actions.tab(this)">Übersicht</div>
        <div class="tab" onclick="actions.tab(this)">Systeme</div>
        <div class="tab" onclick="actions.tab(this)">Verträge</div>
        <div class="tab" onclick="actions.tab(this)">Historie</div>
      </div>

      <div class="card">
        <div class="tiny muted">Ansprechpartner</div>
        <div style="font-weight:700;margin:4px 0">${c.contactName}</div>
        <div class="contact-line">${icon('phone')} ${c.phone}</div>
        <div class="contact-line">${icon('mail')} ${c.email}</div>
        <div class="tiny muted" style="margin-top:10px">Adresse</div>
        <div class="contact-line">${icon('pin')} ${c.address.join(', ')}</div>
      </div>

      <div class="card list-row" style="cursor:pointer" onclick="toast('Systeme öffnen')">
        <span class="ic">${icon('monitor')}</span>
        <span class="lbl" style="color:var(--text)"><b>Installierte Systeme</b><br><span class="muted tiny">${c.systems}</span></span>
        <span class="chev">${icon('chev')}</span>
      </div>
      <div class="card list-row" style="cursor:pointer" onclick="toast('Einsatz öffnen')">
        <span class="ic">${icon('clock')}</span>
        <span class="lbl" style="color:var(--text)"><b>Letzter Einsatz</b><br><span class="muted tiny">${c.lastVisit}</span></span>
        <span class="chev">${icon('chev')}</span>
      </div>
      <div class="card list-row" style="cursor:pointer" onclick="nav.go('tickets')">
        <span class="ic">${icon('ticket')}</span>
        <span class="lbl" style="color:var(--text)"><b>Offene Tickets</b><br><span class="muted tiny">${c.openTickets}</span></span>
        <span class="chev">${icon('chev')}</span>
      </div>`;
    return s;
  },

  /* ---- 06 TimeCard ---- */
  timecard() {
    const s = Screens._new('timecard');
    const tc = DATA.timecard;
    s.innerHTML = `
      <div class="app-header"><h1 class="page-title" style="margin:0">TimeCard</h1>
        <button class="icon-btn" onclick="toast('Kalender')">${icon('calendar')}</button></div>

      <div class="tc-hero">
        <div><div class="lbl">Eingestempelt seit</div><div class="val">${tc.since}</div></div>
        <button class="btn stamp" onclick="actions.stamp(this)">Ausstempeln</button>
      </div>

      <div class="section-head"><h3>Heute</h3></div>
      <div class="card">
        ${tc.today.map(r => `<div class="list-row"><span class="ic">${icon(r.icon)}</span><span class="lbl">${r.label}</span><span class="val">${r.val}</span></div>`).join('')}
      </div>
      <button class="btn btn-red btn-full btn-lg" onclick="actions.pause(this)">${icon('plus')} Pause starten</button>

      <div class="section-head" style="margin-top:18px"><h3>Diese Woche</h3></div>
      <div class="card">
        ${tc.week.map(r => `<div class="list-row"><span class="ic">${icon(r.icon)}</span><span class="lbl">${r.label}</span><span class="val ${r.cls || ''}">${r.val}</span></div>`).join('')}
      </div>`;
    return s;
  },

  /* ---- 07 Zeiterfassung ---- */
  zeiterfassung() {
    const s = Screens._new('zeiterfassung');
    const z = DATA.timeline;
    s.innerHTML = `
      <h1 class="page-title">Zeiterfassung</h1>
      <div class="tabs">
        <div class="tab active" onclick="actions.tab(this)">Tag</div>
        <div class="tab" onclick="actions.tab(this)">Woche</div>
        <div class="tab" onclick="actions.tab(this)">Monat</div>
      </div>
      <div class="date-nav">
        <button>${icon('chevL')}</button>
        <span class="d">${z.date}</span>
        <button>${icon('chev')}</button>
      </div>
      <div class="card">
        <div class="timeline">
          ${z.items.map(i => `
            <div class="tl-item c-${i.color}">
              <div class="tl-dot"></div>
              <div class="tl-body"><div class="tt">${i.time}</div><div class="st">${i.label}</div></div>
            </div>`).join('')}
        </div>
      </div>
      <div class="card">
        <div class="list-row"><span class="ic">${icon('clock')}</span><span class="lbl">Arbeitszeit</span><span class="val">${z.work}</span></div>
        <div class="list-row"><span class="ic">${icon('pause')}</span><span class="lbl">Pause</span><span class="val">${z.pause}</span></div>
      </div>`;
    return s;
  },

  /* ---- 08 Benachrichtigungen ---- */
  notifications() {
    const s = Screens._new('notifications');
    s.innerHTML = `
      <div class="app-header">
        <h1 class="page-title" style="margin:0">Benachrichtigungen</h1>
        <div style="display:flex;gap:8px;align-items:center">
          <span class="badge-pill b-niedrig" style="cursor:pointer">Alle ▾</span>
          <button class="icon-btn" onclick="toast('Alle gelesen')">${icon('check')}</button>
        </div>
      </div>
      <div class="card">
        ${DATA.notifications.map(n => `
          <div class="notif n-${n.type}">
            <div class="ic">${icon(n.icon)}</div>
            <div class="body"><div class="t">${n.title}</div><div class="s">${n.sub}</div></div>
            <div class="when">${n.when}</div>
          </div>`).join('')}
      </div>`;
    return s;
  },

  /* ---- 09 Passwortmanager ---- */
  passwords() {
    const s = Screens._new('passwords');
    s.innerHTML = `
      <div class="app-header"><h1 class="page-title" style="margin:0">Passwörter</h1>
        <button class="icon-btn" onclick="toast('Neues Passwort')">${icon('plus')}</button></div>
      <div class="search">${icon('search')}<input placeholder="Suchen"></div>
      <div class="card">
        ${DATA.passwords.map((p, i) => `
          <div class="pw">
            <div class="ic">${icon(p.icon)}</div>
            <div class="body"><div class="t">${p.title}</div><div class="s">${p.sub}</div></div>
            <span class="dots" id="pw${i}">••••••</span>
            <button class="eye" onclick="actions.togglePw(${i},'${p.sub.replace(/'/g,'')}')">${icon(p.star ? 'star' : 'eye')}</button>
          </div>`).join('')}
      </div>`;
    // Sterne nachträglich einfärben
    setTimeout(() => DATA.passwords.forEach((p, i) => { if (p.star) $$('.pw .eye svg')[i]?.classList.add('star'); }), 0);
    return s;
  },

  /* ---- 10 KI Assistent ---- */
  ki() {
    const s = Screens._new('ki');
    s.classList.add('ki-screen');
    s.innerHTML = `
      <div class="ki-hero">
        <div class="title">LEVITECH KI <span class="beta">Beta</span></div>
      </div>
      <div id="kiIntro">
        <div class="bot-wrap">
          <div class="bot-glow"></div>
          <img class="bot" src="img/bot.svg" alt="KI Roboter">
        </div>
        <div class="ki-greet">Hallo <span>${DATA.user.first}</span>,<br>wie kann ich dir heute helfen?</div>
        <div class="ki-suggest">
          ${DATA.kiSuggestions.map(q => `
            <button class="ki-q" onclick="actions.kiAsk(\`${q}\`)"><span>${q}</span>${icon('chev')}</button>`).join('')}
        </div>
      </div>
      <div class="chat" id="kiChat" style="display:none"></div>

      <div class="ki-input">
        <div class="field">
          <input id="kiInput" placeholder="Frage stellen…" onkeydown="if(event.key==='Enter')actions.kiSend()">
        </div>
        <button class="send" onclick="actions.kiSend()">${icon('send')}</button>
      </div>`;
    return s;
  },

  /* ---- 11 Checklisten ---- */
  checklists() {
    const s = Screens._new('checklists');
    const c = DATA.checklist;
    const pct = Math.round(c.done / c.total * 100);
    s.innerHTML = `
      <h1 class="page-title">Checklisten</h1>
      <div class="card">
        <div style="font-weight:700;font-size:17px">${c.title}</div>
        <div class="tiny muted"><span id="clDone">${c.done}</span> / ${c.total} erledigt</div>
        <div class="progress-bar"><i id="clBar" style="width:${pct}%"></i></div>
      </div>
      <div class="card" id="clList">
        ${c.items.map((it, i) => `
          <div class="check-row ${it.done ? 'done' : ''}" onclick="actions.toggleCheck(${i})">
            <div class="check-box">${icon('check')}</div>
            <div class="lbl">${it.label}</div>
            <span class="chev">${icon('chev')}</span>
          </div>`).join('')}
      </div>`;
    return s;
  },

  /* ---- 12 Dokumente ---- */
  documents() {
    const s = Screens._new('documents');
    s.innerHTML = `
      <div class="app-header"><h1 class="page-title" style="margin:0">Dokumente</h1></div>
      <div class="search">${icon('search')}<input placeholder="Suchen"></div>
      <div class="card">
        ${DATA.documents.map(d => `
          <div class="doc" onclick="toast('Öffne ${d.name}')">
            <div class="ic ${d.type}">${d.type.toUpperCase()}</div>
            <div class="body"><div class="t">${d.name}</div><div class="s">${d.meta}</div></div>
            <span class="chev" style="fill:var(--text-3);width:18px">${icon('chev')}</span>
          </div>`).join('')}
      </div>`;
    return s;
  },

  /* ---- 13 Profil & Mehr ---- */
  profile() {
    const s = Screens._new('profile');
    s.innerHTML = `
      <div class="profile-hero">
        <div class="av"></div>
        <div><div class="nm">${DATA.user.name}</div><div class="rl">${DATA.user.role}</div></div>
      </div>
      <div class="card">
        ${DATA.profileMenu.map(m => `
          <div class="menu-row" onclick="toast('${m.label}')">
            <span class="ic">${icon(m.icon)}</span>
            <span class="lbl">${m.label}${m.sub ? `<br><span class="sub">${m.sub}</span>` : ''}</span>
            <span class="chev">${icon('chev')}</span>
          </div>`).join('')}
      </div>
      <button class="btn btn-red btn-full btn-lg" onclick="toast('Abgemeldet')">Abmelden</button>`;
    return s;
  },

  /* ---- Mehr (Feature-Übersicht + Direktzugriffe) ---- */
  more() {
    const s = Screens._new('more');
    const links = [
      ['zeiterfassung', 'clock', 'Zeiterfassung'],
      ['notifications', 'alert', 'Benachrichtigungen'],
      ['passwords', 'shield', 'Passwörter'],
      ['ki', 'chat', 'KI Assistent'],
      ['checklists', 'check', 'Checklisten'],
      ['documents', 'box', 'Dokumente'],
      ['customer', 'building', 'Kunden'],
      ['profile', 'user', 'Profil'],
    ];
    s.innerHTML = `
      <h1 class="page-title">Mehr</h1>
      <div class="card" style="padding:6px 16px">
        ${links.map(([r, ic, lbl]) => `
          <div class="menu-row" onclick="nav.go('${r}')">
            <span class="ic">${icon(ic)}</span><span class="lbl">${lbl}</span><span class="chev">${icon('chev')}</span>
          </div>`).join('')}
      </div>
      <div class="section-head" style="margin-top:16px"><h3>Funktionen</h3></div>
      <div class="feature-grid">
        ${DATA.features.map(f => `
          <div class="feat">
            <div class="ic">${icon(f.icon)}</div>
            <div class="t">${f.title}</div>
            <div class="s">${f.sub}</div>
          </div>`).join('')}
      </div>`;
    return s;
  },

  /* ---- Hilfen ---- */
  _new(name) {
    const s = document.createElement('section');
    s.className = 'screen';
    s.dataset.screen = name;
    return s;
  },
  _startTimer() {
    clearInterval(Screens._t);
    let sec = 35 * 60 + 42;
    Screens._t = setInterval(() => {
      sec++;
      const h = String(Math.floor(sec / 3600)).padStart(2, '0');
      const m = String(Math.floor(sec % 3600 / 60)).padStart(2, '0');
      const ss = String(sec % 60).padStart(2, '0');
      const t = $('#workTimer'); if (t) t.textContent = `${h}:${m}:${ss}`; else clearInterval(Screens._t);
    }, 1000);
  },
};

/* Ring-Grafik (SVG) */
function ring(pct, sub) {
  const r = 34, c = 2 * Math.PI * r, off = c * (1 - pct / 100);
  return `<div class="ring">
    <svg width="84" height="84">
      <circle cx="42" cy="42" r="${r}" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="8"/>
      <circle cx="42" cy="42" r="${r}" fill="none" stroke="#e51f2e" stroke-width="8"
        stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${off}"/>
    </svg>
    <div class="pct">${pct}%</div>
    <div class="sub">${sub}</div>
  </div>`;
}

/* Ticket-Karte */
function ticketCard(t) {
  const statusCls = t.status === 'offen' ? 'b-offen' : t.status === 'neu' ? 'b-neu' : 'b-bearbeitung';
  return `<div class="ticket p-${t.prio}" data-title="${t.title.toLowerCase()} ${t.cust.toLowerCase()}" onclick="nav.go('ticketDetail')">
    <div class="top"><span class="id">${t.id}</span><span class="badge-pill b-${t.prio}">${t.prioLabel}</span></div>
    <div class="title">${t.title}</div>
    <div class="foot"><span class="cust">${t.cust}</span><span class="badge-pill ${statusCls}">${t.statusLabel}</span></div>
  </div>`;
}

/* ==========================================================================
   NAVIGATION / ROUTING
   ========================================================================== */
const nav = {
  current: null,
  // welche Tabbar-Taste bei welchem Screen aktiv ist
  tabMap: {
    dashboard: 'dashboard', tickets: 'tickets', ticketDetail: 'tickets', ticketEdit: 'tickets',
    timecard: 'timecard', zeiterfassung: 'timecard',
    customer: 'customer',
    more: 'more', notifications: 'more', passwords: 'more', ki: 'more',
    checklists: 'more', documents: 'more', profile: 'more',
  },
  go(name) {
    const vp = $('#viewport');
    // FAB nur auf Tickets
    $('#fab').style.display = name === 'tickets' ? 'grid' : 'none';
    const built = Screens[name] ? Screens[name]() : Screens.dashboard();
    vp.querySelectorAll('.screen').forEach(x => x.remove());
    vp.appendChild(built);
    requestAnimationFrame(() => built.classList.add('active'));
    vp.scrollTop = 0;
    this.current = name;
    // Tabbar markieren
    const tab = this.tabMap[name] || 'more';
    $$('.tabbtn').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
  },
};

/* ==========================================================================
   INTERAKTIONEN
   ========================================================================== */
const actions = {
  stamp(btn) {
    const out = btn.textContent.trim() === 'Ausstempeln';
    btn.textContent = out ? 'Einstempeln' : 'Ausstempeln';
    toast(out ? 'Ausgestempelt ✓' : 'Eingestempelt ✓');
    const live = btn.closest('.hero, .tc-hero')?.querySelector('.live');
    if (live) live.classList.toggle('live');
  },
  pause(btn) {
    const on = btn.textContent.includes('starten');
    btn.innerHTML = `${icon('plus')} ${on ? 'Pause beenden' : 'Pause starten'}`;
    toast(on ? 'Pause gestartet' : 'Pause beendet');
  },
  chip(btn) {
    $$('.chip', btn.parentElement).forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    toast(`Filter: ${btn.textContent}`);
  },
  tab(el) {
    $$('.tab', el.parentElement).forEach(t => t.classList.remove('active'));
    el.classList.add('active');
  },
  filterTickets(q) {
    q = q.toLowerCase();
    $$('#ticketList .ticket').forEach(t => {
      t.style.display = t.dataset.title.includes(q) ? '' : 'none';
    });
  },
  ticketAction(label) {
    if (label === 'Ticket abschließen') { toast('Ticket abgeschlossen ✓'); return; }
    if (label === 'Checkliste') { nav.go('checklists'); return; }
    toast(label + '…');
  },
  saveTicket() { toast('Gespeichert ✓'); setTimeout(() => nav.go('ticketDetail'), 500); },
  togglePw(i, val) {
    const el = $('#pw' + i);
    el.textContent = el.textContent.includes('•') ? val : '••••••';
  },
  toggleCheck(i) {
    DATA.checklist.items[i].done = !DATA.checklist.items[i].done;
    const rows = $$('#clList .check-row');
    rows[i].classList.toggle('done');
    const done = DATA.checklist.items.filter(x => x.done).length;
    DATA.checklist.done = done;
    $('#clDone').textContent = done;
    $('#clBar').style.width = Math.round(done / DATA.checklist.total * 100) + '%';
  },

  /* ---- KI-Bot ---- */
  kiAsk(q) {
    $('#kiInput').value = q;
    actions.kiSend();
  },
  kiSend() {
    const inp = $('#kiInput');
    const q = inp.value.trim();
    if (!q) return;
    inp.value = '';
    $('#kiIntro').style.display = 'none';
    const chat = $('#kiChat');
    chat.style.display = 'flex';
    chat.appendChild(el(`<div class="msg user">${escapeHtml(q)}</div>`));
    scrollChat();

    // Tipp-Animation
    const typing = el(`<div class="msg bot"><div class="who">🤖 LEVITECH KI</div><div class="typing"><span></span><span></span><span></span></div></div>`);
    chat.appendChild(typing);
    scrollChat();

    setTimeout(() => {
      const answer = kiAnswer(q);
      typing.querySelector('.typing').outerHTML = `<div>${answer.replace(/\n/g, '<br>')}</div>`;
      scrollChat();
    }, 900 + Math.random() * 500);
  },
};

function escapeHtml(s) { return s.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c])); }
function scrollChat() { const v = $('#viewport'); v.scrollTop = v.scrollHeight; }

function kiAnswer(q) {
  q = q.toLowerCase();
  const a = DATA.kiAnswers;
  if (q.includes('vpn')) return a.vpn;
  if (q.includes('firewall') || q.includes('dokumentation')) return a.firewall;
  if (q.includes('backup') || q.includes('server')) return a.backup;
  if (q.includes('passwort') || q.includes('switch')) return a.passwort;
  return a.default;
}

/* ==========================================================================
   UHR (Statusbar) + START
   ========================================================================== */
function bootTabbar() {
  const tabs = [
    ['dashboard', 'home', 'Dashboard'],
    ['tickets', 'ticket', 'Tickets'],
    ['timecard', 'timecard', 'TimeCard'],
    ['customer', 'users', 'Kunden'],
    ['more', 'more', 'Mehr'],
  ];
  $('#tabbar').innerHTML = tabs.map(([r, ic, lbl]) =>
    `<button class="tabbtn" data-tab="${r}" onclick="nav.go('${r}')">${icon(ic)}<span class="lbl">${lbl}</span></button>`
  ).join('');
}

function initStatusbar() {
  $('#sb-icons').innerHTML = icon('signal') + icon('wifi') + icon('battery');
}

// global verfügbar machen (inline-Handler + Debug)
window.nav = nav;
window.actions = actions;
window.toast = toast;

document.addEventListener('DOMContentLoaded', () => {
  initStatusbar();
  bootTabbar();
  nav.go('dashboard');
  $('#fab').innerHTML = icon('plus');
});
