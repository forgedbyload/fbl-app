# CLAUDE.md – forgedbyload / fbl-app

## Projektübersicht

Eine PWA (Progressive Web App) als Trainings-Timer und Übungsverwaltung.
Installierbar auf Android (GrapheneOS) via Vanadium/Firefox als Homescreen-App.
Langfristiges Ziel: Monetarisierung via Freemium-Modell.
App-Name ist noch nicht definiert – alle Komponenten sind branding-neutral benannt.

---

## Technischer Stack

- **Frontend:** Vanilla HTML/CSS/JS (single file zu Beginn, später modular)
- **Backend:** Supabase (PostgreSQL + Auth + RLS aktiviert)
- **Hosting:** GitHub Pages → PWA installierbar
- **GIF-Speicherung:** Base64 in Supabase DB (keine externen Dienste, vollständig lokal)
- **Deployment:** git push → GitHub Pages auto-deploy

## Supabase Konfiguration

- **Org:** forgedbyload
- **Region:** Europe (Frankfurt)
- **RLS:** aktiviert
- **Auto-expose tables:** deaktiviert
- **Credentials:** in `.env` Datei (niemals in Git committen)

```
SUPABASE_URL=deine_url
SUPABASE_ANON_KEY=dein_key
```

---

## Design System

Konsistent durch alle Module:

- **Font Display:** Bebas Neue (Google Fonts)
- **Font Body:** DM Sans (Google Fonts)
- **Theme:** Dark
- **Background:** #0d0d0d
- **Surface:** #161616
- **Border:** #242424
- **Text:** #f0ece4
- **Muted:** #666666

### Akzentfarben pro Modus

| Modus | Farbe |
|---|---|
| Kraft | #c8a96e |
| Hypertrophie | #5daab0 |
| Volumen | #9b8ab4 |
| Snack | #a8c5a0 |

---

## Trainingskonzept

### DUP – Daily Undulating Periodization

4 Session-Typen:

| Modus | Schema | Pause | Besonderheit |
|---|---|---|---|
| Kraft | 4–6 Wdh. rep-basiert | 3 Min. Countdown | Zählt als Volleinheit |
| Hypertrophie | 40s Arbeit | 90s | Zählt als Volleinheit |
| Volumen | 40s Arbeit | 60s | Zählt als Volleinheit |
| Snack | 30s Arbeit | 45s | Kein DUP-Tag, auch So. möglich |

### Rolling Schedule

- Volleinheiten rotieren fortlaufend: Kraft → Hyper → Vol → Kraft → ...
- Kein fixer Wochentag – ~48h Pause zwischen Volleinheiten
- **Sonntag:** Volleinheiten gesperrt (hard constraint)
- Snack-Mode: jederzeit möglich, auch Sonntag, verschiebt DUP-Index nicht
- Wenn 48h-Fenster auf Sonntag fällt → automatisch Montag vorschlagen

### Woche A / B System

- Gleiche Muskelgruppen, andere Übungen
- Wechsel alle 2 Wochen automatisch
- Übungen werden bei Erstellung Woche A, B oder Snack zugewiesen
- Snack-Übungen erscheinen nicht im A/B Wochenplan

---

## App-Module (Buildpriorität)

### Modul 1: Übungsbibliothek

- Übung erstellen: Name, GIF (Base64 Upload vom Gerät), Muskelgruppen-Tags, DUP-Modi, Wochenzuweisung
- Muskelgruppen-Tags: Push, Pull, Hinge, Squat, Core, Isometrie, Mobility (erweiterbar)
- DUP-Modi pro Übung: Kraft / Hyper / Vol / mehrere möglich
- Wochenzuweisung: A / B / Snack
- CRUD: erstellen, bearbeiten, löschen
- Persistenz: Supabase

### Modul 2: Wochenplan-Builder (A/B)

- Übungen aus Bibliothek → Woche A oder B zuweisen
- Bias-Score Visualisierung: welche Muskelgruppen sind über-/unterrepräsentiert
- Nur Volleinheiten fliessen in Bias-Score ein (keine Snack-Übungen)
- Vor jedem Training: aktuelle Übungsauswahl anzeigen + manuell modifizieren

### Modul 3: Timer

Bestehender Code vorhanden (workout-timer.html) – muss integriert werden:

- Lädt Übungen des jeweiligen Tags (Woche A oder B, korrekter DUP-Modus)
- Kraft-Modus: rep-basiert, 3 Min. Pause mit Countdown-Bar
- Hyper/Vol-Modus: 40s Arbeit / 90s oder 60s Pause, automatisch
- Snack-Modus: 30s Arbeit / 45s Pause, freie Übungsauswahl
- Features: Skip, Pause, Set-Dots, Fortschrittsring

### Modul 4: Rolling Schedule & Tracking

- Letztes Trainingsdatum speichern
- Nächsten empfohlenen Trainingstag berechnen (~48h, nie Sonntag für Volleinheiten)
- Aktuellen DUP-Modus anzeigen
- Aktuelle Woche (A oder B) tracken
- Trainingshistorie: Datum, Modus, Übungen, Sätze – Snacks separat geloggt

### Modul 5: Snack Mode

- Eigene Übungskategorie (snack-tagged)
- Freie Auswahl vor dem Training
- 30s/45s Schema, 15–20 Min. total
- Fokus: Mobility, Core, Kondition
- Zählt nicht als Volleinheit im Rolling Schedule
- Sonntag erlaubt

---

## Supabase Datenbankschema

```sql
-- Übungsbibliothek
create table exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  gif_base64 text,
  muscle_groups text[],        -- ['push','core','hinge']
  dup_modes text[],            -- ['kraft','hyper','vol']
  week_assignment text,        -- 'A', 'B', 'snack'
  created_at timestamptz default now()
);

-- Trainingshistorie
create table training_log (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  session_type text not null,  -- 'kraft','hyper','vol','snack'
  week text,                   -- 'A', 'B', null für snack
  exercises_done uuid[],
  sets_completed int,
  duration_minutes int,
  created_at timestamptz default now()
);

-- App-State (Rolling Schedule)
create table app_state (
  id uuid primary key default gen_random_uuid(),
  last_training_date date,
  current_dup_index int default 0,  -- 0=kraft, 1=hyper, 2=vol
  current_week text default 'A'     -- 'A' oder 'B'
);
```

---

## Monetarisierungs-Architektur (spätere Phase)

- Supabase Auth von Anfang an vorbereiten (auch wenn noch kein Login aktiv)
- RLS aktiviert → User sehen nur eigene Daten
- Freemium-Logik später: z.B. max. 10 Übungen gratis, unlimitiert bezahlt
- Migration zu React Native möglich – Supabase-Backend bleibt identisch
- App-Name und Branding komplett unabhängig von Datenbankstruktur

---

## PWA Konfiguration

```json
// manifest.json (App-Name später anpassen)
{
  "name": "fbl-app",
  "short_name": "fbl",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0d0d0d",
  "theme_color": "#0d0d0d",
  "icons": [...]
}
```

---

## Buildanweisungen für Claude Code

1. Immer mit Modul 1 beginnen – keine anderen Module ohne funktionierende Bibliothek
2. Nach jedem Modul: `git add . && git commit -m "modul X: beschreibung" && git push`
3. `.env` niemals committen – in `.gitignore` eintragen
4. Bestehender Timer-Code ist in `workout-timer.html` vorhanden – bei Modul 3 integrieren
5. Alle Texte auf Deutsch (UI-Labels, Kommentare)
6. Mobile-first: alle Komponenten für 380px Viewport optimiert
7. Kein externes CSS-Framework – alles vanilla

---

## Offene Entscheidungen

- [ ] Finaler App-Name (Branding)
- [ ] User Authentication (wann einführen?)
- [ ] Übungsanalyse via YouTube/Instagram Link (Claude analysiert → schlägt Klassifizierung vor)
- [ ] Konkrete Übungen für Woche A und B (werden sukzessive hinzugefügt)
