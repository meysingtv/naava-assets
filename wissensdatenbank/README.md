# Naava Wissensdatenbank

Gemeinsame Wissensdatenbank für **Supportfälle** und **Einrichtungsanleitungen** –
gedacht für die Zusammenarbeit zwischen Naava und dem Kunden.

## Was ist das?

Eine schlanke, eigenständige Web-App im Naava-Design (Weiß/Rot), in der wiederkehrende
Supportfälle und Anleitungen dokumentiert, durchsucht und nachgeschlagen werden können.

## Features

- 🔎 Volltextsuche (Titel, Kunde, Problem, Lösung, Tags) – Shortcut `/`
- 🏷️ Filter nach Kategorie (Supportfälle / Anleitungen) und Tags
- ↕️ Sortierung nach Aktualität, A–Z oder Kategorie
- ➕ Einträge anlegen, bearbeiten, löschen
- 📋 Eintrag als Text in die Zwischenablage kopieren
- 💾 Speicherung lokal im Browser (`localStorage`) – kein Backend nötig

## Nutzung

`index.html` im Browser öffnen – oder den Ordner als statische Seite hosten
(z. B. GitHub Pages). Beim ersten Start werden ein paar Beispiel-Einträge angelegt.

## Hinweis zur Datenhaltung

Aktuell werden die Daten **lokal im Browser** gespeichert (Prototyp). Für eine echte
*gemeinsame* Datenbank über mehrere Personen/den Kunden hinweg muss noch ein
gemeinsamer Speicher (z. B. eine kleine API/DB oder ein gehosteter Dienst) angebunden
werden – siehe offene Frage der Claude-Lizenz mit Sascha.

## Aufbau

| Datei        | Inhalt                          |
|--------------|---------------------------------|
| `index.html` | Struktur                        |
| `style.css`  | Design (Weiß/Rot)               |
| `app.js`     | Logik, Suche, Speicherung       |
| `img/`       | Logo                            |
