# LEVITECH Workspace App — macOS (SwiftUI)

Native macOS-App im Handy-Format. Vollständige Portierung der LEVITECH IT-Service App
aus der Web-Version — alle 13 Screens 1:1, inkl. KI-Assistent mit Roboter-Maskottchen
und Ein-/Ausstempeln.

## Öffnen

**Per Doppelklick (Finder):**
- `In Codex öffnen.command` — startet Codex CLI im Projektordner
- `In Xcode öffnen.command` — öffnet das Xcode-Projekt

**Per Terminal:**

```bash
cd levitech-macos

# In Codex öffnen (OpenAI Codex CLI):
codex

# oder in Xcode:
open LEVITECH.xcodeproj
```

> Falls `codex` fehlt: `npm install -g @openai/codex`

## Bauen & Starten

In Xcode einfach **⌘R** drücken. Oder im Terminal:

```bash
cd levitech-macos
xcodebuild -project LEVITECH.xcodeproj -scheme LEVITECH -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/LEVITECH-*/Build/Products/Debug/LEVITECH.app
```

**Voraussetzung:** macOS 13+, Xcode 16+ (das Projekt nutzt filesystem-synchronisierte
Gruppen — neue Swift-Dateien im Ordner `LEVITECH/` werden automatisch eingebunden).

## Aufbau

```
LEVITECH/
  LEVITECHApp.swift        App-Einstieg (@main, Fenster)
  Theme.swift              Farben & Stile (Dark/Rot)
  Store.swift              Datenmodelle, Beispieldaten, Zustand, KI-Logik
  Components.swift         Karten, Badges, Ring, Buttons, Header …
  RootView.swift           Handy-Rahmen, Statusbar, Router, Tab-Bar
  BotView.swift            KI-Roboter (in SwiftUI gezeichnet)
  Screens/
    DashboardView.swift          01 Dashboard
    TicketsView.swift            02 Tickets · 03 Details · 04 Bearbeiten
    CustomerTimeViews.swift      05 Kunden · 06 TimeCard · 07 Zeiterfassung
    ListViews.swift              08 Mitteilungen · 09 Passwörter · 11 Checklisten
                                 12 Dokumente · 13 Profil · Mehr
    KIAssistantView.swift        10 KI Assistent (Bot + Chat)
```

## Funktionen

- **Ein-/Ausstempeln** & Pause starten/beenden (Dashboard + TimeCard)
- **Tickets** filtern, durchsuchen, Detail- und Bearbeiten-Ansicht mit laufendem Timer
- **KI-Assistent** mit Vorschlägen, Tipp-Animation und Antwortlogik
- **Checklisten** abhaken mit Fortschrittsbalken
- **Passwörter** ein-/ausblenden
- Kunden, Zeiterfassung, Benachrichtigungen, Dokumente, Profil, Feature-Übersicht
