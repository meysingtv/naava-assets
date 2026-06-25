/* ===========================================================
   Naava Wissensdatenbank — Logik
   Speicherung: localStorage (kein Backend nötig).
   =========================================================== */
(function () {
  "use strict";

  const STORAGE_KEY = "naava_wissensdatenbank_v1";

  /* --- Seed-Daten (Beispiele, beim ersten Start) --- */
  const SEED = [
    {
      id: "seed-1",
      title: "VPN verbindet nicht – Fehler 809",
      category: "Supportfall",
      customer: "Mustermann GmbH",
      tags: ["vpn", "netzwerk", "windows"],
      problem: "Beim Verbindungsaufbau erscheint Fehler 809. Der Client hängt bei \"Verbindung wird hergestellt\".",
      solution:
        "1. Sicherstellen, dass UDP-Ports 500 und 4500 in der Firewall freigegeben sind.\n" +
        "2. Registry-Key anlegen:\n   HKLM\\SYSTEM\\CurrentControlSet\\Services\\PolicyAgent\n   DWORD \"AssumeUDPEncapsulationContextOnSendRule\" = 2\n" +
        "3. Rechner neu starten und Verbindung erneut testen.",
      author: "Leon",
      created: "2026-05-12T09:20:00.000Z",
      updated: "2026-05-12T09:20:00.000Z",
    },
    {
      id: "seed-2",
      title: "Neuen Mitarbeiter einrichten (Onboarding)",
      category: "Einrichtungsanleitung",
      customer: "Mustermann GmbH",
      tags: ["onboarding", "konto", "email"],
      problem: "Checkliste für die Ersteinrichtung eines neuen Arbeitsplatzes.",
      solution:
        "1. AD-Benutzerkonto anlegen, Gruppen zuweisen.\n" +
        "2. E-Mail-Postfach (Exchange) erstellen, Lizenz zuweisen.\n" +
        "3. Notebook mit Standard-Image aufsetzen.\n" +
        "4. VPN-Profil + Drucker installieren.\n" +
        "5. Zugangsdaten sicher übergeben, MFA aktivieren.",
      author: "Sascha",
      created: "2026-05-20T13:00:00.000Z",
      updated: "2026-06-02T08:15:00.000Z",
    },
    {
      id: "seed-3",
      title: "Netzwerkdrucker wird nicht erkannt",
      category: "Supportfall",
      customer: "Mustermann GmbH",
      tags: ["drucker", "netzwerk"],
      problem: "Drucker erscheint nicht in der Geräteliste, Testdruck schlägt fehl.",
      solution:
        "1. IP des Druckers anpingen – erreichbar?\n" +
        "2. Drucker per TCP/IP-Port manuell hinzufügen (Standard-Port 9100).\n" +
        "3. Aktuellen Treiber des Herstellers installieren.\n" +
        "4. Testseite drucken.",
      author: "Leon",
      created: "2026-06-10T10:45:00.000Z",
      updated: "2026-06-10T10:45:00.000Z",
    },
  ];

  /* ---------- State ---------- */
  let entries = load();
  let activeCategory = "Alle";
  let query = "";
  let sortBy = "recent";

  /* ---------- DOM ---------- */
  const $ = (s) => document.querySelector(s);
  const grid = $("#entryGrid");
  const emptyState = $("#emptyState");
  const resultCount = $("#resultCount");
  const categoryFilters = $("#categoryFilters");
  const searchInput = $("#searchInput");
  const sortSelect = $("#sortSelect");

  /* ---------- Storage ---------- */
  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) return JSON.parse(raw);
    } catch (e) { /* ignore */ }
    save(SEED);
    return SEED.slice();
  }
  function save(data) {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(data || entries)); }
    catch (e) { /* storage voll / privat */ }
  }

  /* ---------- Helpers ---------- */
  function esc(str) {
    return String(str == null ? "" : str)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }
  function uid() { return "e-" + Math.random().toString(36).slice(2, 9) + Date.now().toString(36); }
  function nowISO() { return new Date().toISOString(); }
  function fmtDate(iso) {
    try {
      return new Date(iso).toLocaleDateString("de-DE", { day: "2-digit", month: "short", year: "numeric" });
    } catch (e) { return ""; }
  }
  function isSetup(cat) { return cat === "Einrichtungsanleitung"; }
  function parseTags(str) {
    return String(str || "")
      .split(",").map((t) => t.trim().toLowerCase()).filter(Boolean)
      .filter((t, i, a) => a.indexOf(t) === i).slice(0, 10);
  }

  /* ---------- Render: Filter-Chips ---------- */
  function renderFilters() {
    const cats = ["Alle", "Supportfall", "Einrichtungsanleitung"];
    const counts = entries.reduce((m, e) => { m[e.category] = (m[e.category] || 0) + 1; return m; }, {});
    counts["Alle"] = entries.length;
    const label = { "Alle": "Alle", "Supportfall": "Supportfälle", "Einrichtungsanleitung": "Anleitungen" };
    categoryFilters.innerHTML = cats.map((c) =>
      `<button class="chip ${c === activeCategory ? "is-active" : ""}" data-cat="${esc(c)}">
         ${esc(label[c])}<span class="chip__count">${counts[c] || 0}</span>
       </button>`
    ).join("");
  }

  /* ---------- Filter + Sort ---------- */
  function visibleEntries() {
    const q = query.trim().toLowerCase();
    let list = entries.filter((e) => {
      if (activeCategory !== "Alle" && e.category !== activeCategory) return false;
      if (!q) return true;
      const hay = [e.title, e.customer, e.problem, e.solution, e.author, (e.tags || []).join(" ")]
        .join(" ").toLowerCase();
      return hay.includes(q);
    });
    list.sort((a, b) => {
      if (sortBy === "az") return a.title.localeCompare(b.title, "de");
      if (sortBy === "category") return a.category.localeCompare(b.category, "de") || a.title.localeCompare(b.title, "de");
      return new Date(b.updated || b.created) - new Date(a.updated || a.created);
    });
    return list;
  }

  /* ---------- Render: Liste ---------- */
  function render() {
    renderFilters();
    const list = visibleEntries();
    resultCount.textContent =
      list.length + (list.length === 1 ? " Eintrag" : " Einträge");

    if (!list.length) {
      grid.innerHTML = "";
      emptyState.hidden = false;
      return;
    }
    emptyState.hidden = true;
    grid.innerHTML = list.map(cardHTML).join("");
  }

  function cardHTML(e) {
    const setup = isSetup(e.category);
    const badge = setup
      ? `<span class="badge badge--setup">Anleitung</span>`
      : `<span class="badge badge--support">Supportfall</span>`;
    const tags = (e.tags || []).slice(0, 4)
      .map((t) => `<span class="tag">#${esc(t)}</span>`).join("");
    const excerpt = e.problem || e.solution || "";
    return `
      <button class="card" data-id="${esc(e.id)}">
        <div class="card__top">
          ${badge}
          ${e.customer ? `<span class="card__customer">${esc(e.customer)}</span>` : ""}
        </div>
        <h3 class="card__title">${esc(e.title)}</h3>
        <p class="card__excerpt">${esc(excerpt)}</p>
        ${tags ? `<div class="card__tags">${tags}</div>` : ""}
        <div class="card__meta">
          ${e.author ? esc(e.author) + " · " : ""}aktualisiert ${fmtDate(e.updated || e.created)}
        </div>
      </button>`;
  }

  /* ---------- Detail ---------- */
  function openDetail(id) {
    const e = entries.find((x) => x.id === id);
    if (!e) return;
    const setup = isSetup(e.category);
    const badge = setup
      ? `<span class="badge badge--setup">Anleitung</span>`
      : `<span class="badge badge--support">Supportfall</span>`;
    const tags = (e.tags || []).map((t) => `<span class="tag">#${esc(t)}</span>`).join("");
    $("#detailContent").innerHTML = `
      <div class="detail__head">
        <div class="card__top">${badge}${e.customer ? `<span class="card__customer">${esc(e.customer)}</span>` : ""}</div>
        <h2 class="detail__title">${esc(e.title)}</h2>
        <div class="detail__meta">
          <span>${e.author ? "von " + esc(e.author) : "ohne Autor"}</span>
          <span>erstellt ${fmtDate(e.created)}</span>
          <span>aktualisiert ${fmtDate(e.updated || e.created)}</span>
        </div>
        ${tags ? `<div class="detail__tags">${tags}</div>` : ""}
      </div>
      ${e.problem ? `<section><h4>Problem / Ausgangslage</h4><div class="detail__body">${esc(e.problem)}</div></section>` : ""}
      <section><h4>Lösung / Schritte</h4><div class="detail__body">${esc(e.solution)}</div></section>
      <div class="detail__actions">
        <button class="linkbtn" data-copy="${esc(e.id)}">In Zwischenablage kopieren</button>
        <span class="spacer"></span>
        <button class="linkbtn" data-edit="${esc(e.id)}">Bearbeiten</button>
        <button class="linkbtn" data-delete="${esc(e.id)}">Löschen</button>
      </div>`;
    showModal("#detailModal");
  }

  function copyEntry(id) {
    const e = entries.find((x) => x.id === id);
    if (!e) return;
    const text =
      `${e.title}\n[${e.category}${e.customer ? " · " + e.customer : ""}]\n\n` +
      (e.problem ? `Problem:\n${e.problem}\n\n` : "") +
      `Lösung:\n${e.solution}`;
    if (navigator.clipboard) navigator.clipboard.writeText(text);
  }

  /* ---------- Editor ---------- */
  const editorModal = $("#editorModal");
  const entryForm = $("#entryForm");
  let editingId = null;

  function openEditor(id) {
    editingId = id || null;
    entryForm.reset();
    $("#editorTitle").textContent = id ? "Eintrag bearbeiten" : "Neuer Eintrag";
    if (id) {
      const e = entries.find((x) => x.id === id);
      if (e) {
        entryForm.title.value = e.title || "";
        entryForm.category.value = e.category || "Supportfall";
        entryForm.customer.value = e.customer || "";
        entryForm.tags.value = (e.tags || []).join(", ");
        entryForm.problem.value = e.problem || "";
        entryForm.solution.value = e.solution || "";
        entryForm.author.value = e.author || "";
      }
    }
    showModal("#editorModal");
    setTimeout(() => entryForm.title.focus(), 50);
  }

  entryForm.addEventListener("submit", (ev) => {
    ev.preventDefault();
    const data = {
      title: entryForm.title.value.trim(),
      category: entryForm.category.value,
      customer: entryForm.customer.value.trim(),
      tags: parseTags(entryForm.tags.value),
      problem: entryForm.problem.value.trim(),
      solution: entryForm.solution.value.trim(),
      author: entryForm.author.value.trim(),
    };
    if (!data.title || !data.solution) return;

    if (editingId) {
      const e = entries.find((x) => x.id === editingId);
      if (e) { Object.assign(e, data, { updated: nowISO() }); }
    } else {
      entries.unshift(Object.assign(data, { id: uid(), created: nowISO(), updated: nowISO() }));
    }
    save();
    closeModals();
    render();
  });

  function deleteEntry(id) {
    if (!confirm("Diesen Eintrag wirklich löschen?")) return;
    entries = entries.filter((x) => x.id !== id);
    save();
    closeModals();
    render();
  }

  /* ---------- Modal-Steuerung ---------- */
  function showModal(sel) { $(sel).hidden = false; document.body.style.overflow = "hidden"; }
  function closeModals() {
    $("#detailModal").hidden = true;
    editorModal.hidden = true;
    document.body.style.overflow = "";
  }

  /* ---------- Events ---------- */
  $("#newEntryBtn").addEventListener("click", () => openEditor(null));

  categoryFilters.addEventListener("click", (e) => {
    const chip = e.target.closest(".chip");
    if (!chip) return;
    activeCategory = chip.dataset.cat;
    render();
  });

  grid.addEventListener("click", (e) => {
    const card = e.target.closest(".card");
    if (card) openDetail(card.dataset.id);
  });

  document.addEventListener("click", (e) => {
    if (e.target.closest("[data-close]")) closeModals();
    const ed = e.target.closest("[data-edit]"); if (ed) { closeModals(); openEditor(ed.dataset.edit); }
    const del = e.target.closest("[data-delete]"); if (del) deleteEntry(del.dataset.delete);
    const cp = e.target.closest("[data-copy]"); if (cp) { copyEntry(cp.dataset.copy); cp.textContent = "Kopiert ✓"; }
    const nav = e.target.closest('[data-nav="home"]');
    if (nav) { e.preventDefault(); activeCategory = "Alle"; query = ""; searchInput.value = ""; render(); window.scrollTo({ top: 0, behavior: "smooth" }); }
  });

  searchInput.addEventListener("input", (e) => { query = e.target.value; render(); });
  sortSelect.addEventListener("change", (e) => { sortBy = e.target.value; render(); });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeModals();
    if (e.key === "/" && document.activeElement !== searchInput &&
        !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); searchInput.focus();
    }
  });

  /* ---------- Start ---------- */
  render();
})();
