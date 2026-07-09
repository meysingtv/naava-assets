/* ==========================================================================
   LEVITECH — App-Daten (aus den Design-Screens 1:1 übernommen)
   ========================================================================== */

const DATA = {
  user: {
    name: "Max Mustermann",
    first: "Max",
    role: "Servicetechniker",
    checkedInSince: "07:18 Uhr",
  },

  dashboardStats: [
    { n: 8, l: "Offene Tickets", cls: "" },
    { n: 2, l: "Dringend", cls: "s-red" },
    { n: 1, l: "Termine heute", cls: "s-amber" },
    { n: 1, l: "Bereitschaft", cls: "s-blue" },
  ],

  nextAppt: {
    time: "10:00",
    title: "Muster GmbH",
    sub: "Firewall Check",
    addr: "Hauptstraße 12, 12345 Musterstadt",
  },

  timecardToday: { work: "07:18 h", pause: "00:45 h", pct: 75 },

  tickets: [
    { id: "#2024-1001", title: "Server ausgefallen", cust: "Muster GmbH", prio: "dringend", prioLabel: "Dringend", status: "bearbeitung", statusLabel: "In Bearbeitung" },
    { id: "#2024-1002", title: "VPN funktioniert nicht", cust: "Schmidt & Partner", prio: "hoch", prioLabel: "Hoch", status: "bearbeitung", statusLabel: "In Bearbeitung" },
    { id: "#2024-1003", title: "Backup überprüfen", cust: "Beispiel KG", prio: "mittel", prioLabel: "Mittel", status: "offen", statusLabel: "Offen" },
    { id: "#2024-1004", title: "PC Einrichtung neuer MA", cust: "Muster GmbH", prio: "niedrig", prioLabel: "Niedrig", status: "offen", statusLabel: "Offen" },
    { id: "#2024-1005", title: "Drucker Probleme", cust: "ABC GmbH", prio: "mittel", prioLabel: "Mittel", status: "offen", statusLabel: "Offen" },
  ],

  ticketDetail: {
    id: "#2024-1001",
    title: "Server ausgefallen",
    cust: "Muster GmbH",
    prio: "dringend",
    prioLabel: "Dringend",
    contactName: "Herr Max Beispiel",
    phone: "01234 567890",
    email: "m.beispiel@muster-gmbh.de",
    address: ["Hauptstraße 12", "12345 Musterstadt"],
    description: "Der FileServer FS01 ist seit heute Morgen ausgefallen. Zugriff für alle Mitarbeiter nicht möglich.",
    priority: "Dringend",
    sla: "24.05.2024 12:00",
    created: "24.05.2024 08:15",
    status: "In Bearbeitung",
  },

  ticketActions: [
    { icon: "comment", label: "Kommentar hinzufügen" },
    { icon: "image", label: "Fotos & Dateien", count: 3 },
    { icon: "clock", label: "Zeit buchen", chev: true },
    { icon: "box", label: "Material hinzufügen", count: 2 },
    { icon: "check", label: "Checkliste", count: "2/6" },
    { icon: "sign", label: "Kundenunterschrift" },
    { icon: "flag", label: "Ticket abschließen" },
  ],

  customer: {
    name: "Muster GmbH",
    since: "Kunde seit 2018",
    contactName: "Herr Max Beispiel",
    phone: "01234 567890",
    email: "m.beispiel@muster-gmbh.de",
    address: ["Hauptstraße 12", "12345 Musterstadt"],
    systems: "24 Systeme",
    lastVisit: "23.05.2024 – Backup Check",
    openTickets: "2 Tickets",
  },

  timecard: {
    since: "07:18 Uhr",
    today: [
      { icon: "clock", label: "Arbeitszeit", val: "07:18 h" },
      { icon: "pause", label: "Pause", val: "00:45 h" },
      { icon: "target", label: "Sollzeit", val: "08:00 h" },
    ],
    week: [
      { icon: "clock", label: "Arbeitszeit", val: "39:15 h" },
      { icon: "target", label: "Sollzeit", val: "40:00 h" },
      { icon: "bolt", label: "Überstunden", val: "-00:45 h", cls: "neg" },
    ],
  },

  timeline: {
    date: "Freitag, 24.05.2024",
    items: [
      { time: "07:18", label: "Eingestempelt", color: "green" },
      { time: "12:00 – 12:30", label: "Pause", color: "amber" },
      { time: "12:30", label: "Weitergearbeitet", color: "green" },
      { time: "17:03", label: "Ausgestempelt", color: "red" },
    ],
    work: "07:15 h",
    pause: "00:30 h",
  },

  notifications: [
    { type: "new", icon: "plus", title: "Neues Ticket", sub: "#2024-1006 wurde erstellt", when: "Jetzt" },
    { type: "edit", icon: "edit", title: "Ticket geändert", sub: "#2024-1002 wurde aktualisiert", when: "5 Min." },
    { type: "msg", icon: "chat", title: "Kunde antwortet", sub: "Muster GmbH hat geantwortet", when: "15 Min." },
    { type: "warn", icon: "alert", title: "SLA Warnung", sub: "SLA für Ticket #2024-0999 läuft in 1 Stunde ab", when: "30 Min." },
    { type: "warn", icon: "wrench", title: "Wartungsfenster", sub: "Wartung bei Kunde ABC GmbH morgen 22:00 Uhr", when: "1 Std." },
  ],

  passwords: [
    { icon: "shield", title: "Firewall Hauptstandort", sub: "admin · Firewall", star: false },
    { icon: "cloud", title: "Microsoft 365", sub: "admin@muster-gmbh.de", star: true },
    { icon: "vpn", title: "VPN Zugang", sub: "m.muster", star: false },
    { icon: "server", title: "Server FS01", sub: "administrator", star: false },
    { icon: "wifi", title: "WLAN Office", sub: "levitech@2024", star: false },
  ],

  kiSuggestions: [
    "Wie richte ich VPN bei Kunde X ein?",
    "Wo finde ich die Firewall Dokumentation?",
    "Wie mache ich ein Backup vom Server?",
    "Passwort für Switch im Büro?",
  ],

  kiAnswers: {
    vpn: `Für die VPN-Einrichtung bei einem Kunden:
1. Öffne die Firewall-Konfiguration
2. Erstelle ein neues VPN-Profil (IKEv2 empfohlen)
3. Trage das Kunden-Subnetz ein
4. Exportiere die .ovpn-Datei und teste die Verbindung

Die Zugangsdaten findest du im Passwortmanager unter »VPN Zugang«.`,
    firewall: `Die Firewall-Dokumentation liegt unter Dokumente → »Firewall Regeln.xlsx«. Dort sind alle Portfreigaben und Regelwerke pro Standort hinterlegt. Für den Hauptstandort findest du die Zugangsdaten im Passwortmanager.`,
    backup: `Server-Backup Schritt für Schritt:
1. Prüfe zuerst den letzten Backup-Status im Monitoring
2. Starte ein manuelles Voll-Backup über das Backup-Tool
3. Verifiziere die Integrität nach Abschluss
4. Dokumentiere es in der Checkliste »Serverwartung«

Siehe auch »Backup Konzept.pdf« in den Dokumenten.`,
    passwort: `Passwörter findest du sicher verschlüsselt im Passwortmanager (Reiter »Mehr«). Für den Switch im Büro: Kategorie Netzwerk. Aus Sicherheitsgründen kann ich Passwörter hier nicht im Klartext anzeigen – tippe im Passwortmanager auf das Augen-Symbol.`,
    default: `Gute Frage! Ich durchsuche die Wissensdatenbank und die Kundendokumentation für dich. Du findest die meisten Anleitungen unter Dokumente. Möchtest du, dass ich ein Ticket dazu erstelle oder die passende Checkliste öffne?`,
  },

  checklist: {
    title: "Serverwartung",
    done: 3,
    total: 8,
    items: [
      { label: "Backup prüfen", done: true },
      { label: "Windows Updates", done: false },
      { label: "SMART prüfen", done: true },
      { label: "Eventlogs prüfen", done: false },
      { label: "Dienste prüfen", done: false },
      { label: "Virenscanner prüfen", done: false },
      { label: "Firewall prüfen", done: true },
      { label: "Dokumentation prüfen", done: false },
    ],
  },

  documents: [
    { type: "pdf", name: "Netzwerkplan.pdf", meta: "PDF · 2.4 MB" },
    { type: "xls", name: "Firewall Regeln.xlsx", meta: "XLSX · 1.1 MB" },
    { type: "pdf", name: "Backup Konzept.pdf", meta: "PDF · 1.2 MB" },
    { type: "pdf", name: "Wartungsvertrag.pdf", meta: "PDF · 1.2 MB" },
    { type: "doc", name: "Übergabeprotokoll.docx", meta: "DOCX · 708 KB" },
    { type: "pdf", name: "Anleitung VPN.pdf", meta: "PDF · 1.5 MB" },
  ],

  profileMenu: [
    { icon: "user", label: "Persönliche Daten" },
    { icon: "clock", label: "Arbeitszeiten" },
    { icon: "sun", label: "Urlaub", sub: "12 Tage verfügbar" },
    { icon: "bolt", label: "Überstundenkonto", sub: "+08:15 h" },
    { icon: "cert", label: "Zertifikate", sub: "5 Zertifikate" },
    { icon: "gear", label: "Einstellungen" },
  ],

  features: [
    { icon: "offline", title: "Offline Modus", sub: "Arbeiten auch ohne Internet. Daten werden automatisch synchronisiert." },
    { icon: "camera", title: "Kamera & Scanner", sub: "Fotos aufnehmen, QR-Codes scannen und direkt zum Ticket hinzufügen." },
    { icon: "box", title: "Material & Lager", sub: "Verbrauchtes Material erfassen und Lagerbestände prüfen." },
    { icon: "nav", title: "Navigation", sub: "Direkt zum Kunden navigieren mit Google Maps oder Apple Karten." },
    { icon: "team", title: "Team & Kommunikation", sub: "Kollegen anrufen, chatten und Verfügbarkeit sehen." },
    { icon: "shield", title: "Sicherheit", sub: "Alles verschlüsselt. Zugriff nur für autorisierte Mitarbeiter." },
  ],
};
