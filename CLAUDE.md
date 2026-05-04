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
| Flexibility | #e8a598 |

---

## Trainingskonzept

### DUP – Daily Undulating Periodization

4 Session-Typen:

| Modus | Schema | Pause | Besonderheit |
|---|---|---|---|
| Kraft | 4–6 Wdh. rep-basiert | konfigurierbar | Zählt als Volleinheit |
| Hypertrophie | konfigurierbar | konfigurierbar | Zählt als Volleinheit |
| Volumen | konfigurierbar | konfigurierbar | Zählt als Volleinheit |
| Flexibility | GIF-Navigation | keine Pause | Gesonderte Session, kein Timer |

### Woche A / B System

- Gleiche Muskelgruppen, andere Übungen – Wechsel alle 2 Wochen automatisch
- Sessions haben feste Wochentage (Mo–So), kein Rolling Schedule
- Mehrere Sessions am gleichen Tag möglich
- Übungen werden NICHT beim Erstellen zugewiesen – Zuweisung im Wochenplan-Builder
- Eine Übung kann gleichzeitig in Woche A und B sein (week_assignment = ['A','B'])

---

## App-Module (Buildpriorität)

### Modul 1: Übungsbibliothek

- Übung erstellen: Name, GIF (Base64 Upload), Dreistufige Klassifizierung, DUP-Modi
- CRUD: erstellen, bearbeiten, löschen – Persistenz: Supabase
- Keine Wochenzuweisung beim Erstellen – erfolgt im Wochenplan-Builder (Modul 2)

**DUP-Modi pro Übung (Mehrfachauswahl):**
`kraft` / `hyper` / `vol` / `flexibility`

**Kraft-spezifisch: Working Weight & PR**
Pro Übung mit DUP-Modus `kraft` können bis zu 5 Gewichtsfelder (in kg) gespeichert werden:
- Barbell
- Dumbbell (1x)
- Dumbbell (2x)
- Kettlebell (1x)
- Kettlebell (2x)
Jedes Feld hat zwei Werte: `working_weight` (kg) und `personal_record` (kg).
Felder sind optional – User fügt nur die hinzu, die er nutzt.

**Bibliotheks-Ansicht – Sortierung:**
Alphabetisch innerhalb dieser Gruppen (in dieser Reihenfolge):
1. `Komplex` – body_regions.length > 1
2. `Upper Body` – chest, back, shoulders, arms (einzeln)
   - Chest / Back / Shoulders / Arms
3. `Lower Body` – legs
4. `Core`
5. `Flexibility` – mobility

**Status-Badge neben jeder Übung:**
- `A` – in Woche A eingeplant
- `B` – in Woche B eingeplant
- `A+B` – in beiden Wochen
- Kein Badge – unzugewiesen

### Modul 2: Wochenplan-Builder (A/B)

**Struktur:**
- Zwei Tabs: Woche A / Woche B
- Pro Woche: Sessions an festen Wochentagen (Mo–So)
- Mehrere Sessions am gleichen Tag möglich
- Sessions hinzufügen / bearbeiten / löschen

**Session erstellen:**
1. Wochentag wählen (Mo / Di / Mi / Do / Fr / Sa / So)
2. DUP-Modus wählen: Kraft / Hyper / Vol / Flexibility
3. Übungen aus Bibliothek hinzufügen (Mehrfachauswahl mit Suche + Filter nach Kategorie)
4. Für Kraft / Hyper / Vol: Arbeitszeit und Pausenzeit konfigurieren (in Sekunden)
   - Flexibility: kein Timer, kein Pausenfeld
5. Reihenfolge der Übungen innerhalb einer Session nachträglich änderbar (Drag oder Pfeile)
6. Session-Titel wird automatisch generiert:
   Format: "[DUP-Modus], [Körperregionen aller Übungen]"
   Beispiel: "Kraft, Shoulders, Arms"

**Wochenzuweisung:**
- Übungen aus Bibliothek → einer oder beiden Wochen zuweisen
- week_assignment wird in Supabase sofort aktualisiert
- Eine Übung kann week_assignment = ['A','B'] haben

**Bias-Score (exkl. Flexibility-Sessions):**
- Ebene 1: body_regions Verteilung als Balken
- Ebene 2: movement_patterns Push/Pull Balance als Balken
- Kein Warnsystem – nur visuelle Darstellung

### Modul 3: Timer

- Lädt Session des gewählten Tags aus Modul 2
- Features: Skip, Pause, Set-Dots, Fortschrittsring

**Kraft / Hyper / Vol Modus:**
- Kraft: rep-basiert (4–6 Wdh.), Pausenzeit aus Session-Konfiguration
- Hyper / Vol: Arbeitszeit und Pausenzeit aus Session-Konfiguration
- GIF der aktuellen Übung: gross und prominent während Arbeitsphase
- Während Pausenphase: GIF + Titel der NÄCHSTEN Übung klein in Ecke sichtbar
- GIF der aktuellen Übung läuft weiterhin im Hintergrund während Pause

**Flexibility Modus:**
- Kein Timer, kein Countdown
- GIF der aktuellen Übung wird gross abgespielt
- Navigation: "Weiter" und "Zurück" Buttons
- Kein Pausenfeld

### Modul 4: Stats

Dieses Modul bleibt vorerst leer. Inhalte folgen später.

---

## Dreistufiges Muskelgruppen-Klassifizierungssystem

### Ebene 1: Körperregion (für schnellen Überblick)
```
chest       – Brust
back        – Rücken
shoulders   – Schultern
arms        – Arme
legs        – Beine
core        – Core
mobility    – Mobilität
```

### Ebene 2: Movement Pattern (für Bias-Score)
```
horizontal_push   – Liegestütz, Bench Press
vertical_push     – Shoulder Press, Pike Push-Up
horizontal_pull   – Row, Face Pull
vertical_pull     – Pull-Up, Lat Pulldown
hip_hinge         – Deadlift, RDL, Good Morning
squat             – Squat, Goblet Squat
lunge             – Ausfallschritt, Split Squat
carry             – Farmer's Walk
rotation          – Woodchopper
anti_rotation     – Dead Bug, Pallof Press
core_flexion      – McGill Curl-Up
isometrie         – Wandsitzen, Plank
mobility          – Cat-Cow, 90/90 Hip
```

### Ebene 3: Anatomische Muskeln (für Detailansicht & Übungsdifferenzierung)
```
-- Chest
pectoralis_major, pectoralis_minor, serratus_anterior

-- Back
latissimus_dorsi, trapezius_upper, trapezius_middle, trapezius_lower,
rhomboids, erector_spinae, teres_major

-- Shoulders
deltoid_anterior, deltoid_lateral, deltoid_posterior, rotator_cuff

-- Arms
biceps, triceps, forearms

-- Legs
quadriceps, hamstrings, gluteus_maximus, gluteus_medius,
calves, hip_flexors, adductors

-- Core
rectus_abdominis, obliques, transversus_abdominis, multifidus
```

### Beispiel: Diamond vs. Wide Push-Up
```
Diamond Push-Up:
  Ebene 1: chest, arms
  Ebene 2: horizontal_push
  Ebene 3: triceps, pectoralis_minor

Wide Push-Up:
  Ebene 1: chest, shoulders
  Ebene 2: horizontal_push
  Ebene 3: pectoralis_major, deltoid_anterior
```

---

## Supabase Datenbankschema

```sql
-- Übungsbibliothek
create table exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  gif_base64 text,

  -- Dreistufige Klassifizierung
  body_regions text[],              -- ['chest','arms']
  movement_patterns text[],         -- ['horizontal_push']
  muscle_groups_anatomical text[],  -- ['pectoralis_major','triceps']

  -- DUP-Modi: 'kraft','hyper','vol','flexibility'
  dup_modes text[],

  -- Gewichte für Kraft-Übungen (optional, max 5 Felder)
  -- Struktur: JSONB Array [{type, working_weight, personal_record}]
  -- type: 'barbell','dumbbell_1x','dumbbell_2x','kettlebell_1x','kettlebell_2x'
  strength_weights jsonb,

  week_assignment text[],           -- null, ['A'], ['B'], ['A','B']
  created_at timestamptz default now()
);

-- Sessions (Wochenplan)
create table sessions (
  id uuid primary key default gen_random_uuid(),
  week text not null,               -- 'A' oder 'B'
  weekday text not null,            -- 'mo','di','mi','do','fr','sa','so'
  dup_mode text not null,           -- 'kraft','hyper','vol','flexibility'
  exercise_ids uuid[],              -- geordnete Liste von Übungs-IDs
  work_seconds int,                 -- Arbeitszeit (null für kraft+flexibility)
  rest_seconds int,                 -- Pausenzeit (null für flexibility)
  title text,                       -- auto-generiert: "Kraft, Shoulders, Arms"
  created_at timestamptz default now()
);

-- Trainingshistorie
create table training_log (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  session_id uuid references sessions(id),
  week text,                        -- 'A' oder 'B'
  exercises_done uuid[],
  sets_completed int,
  duration_minutes int,
  created_at timestamptz default now()
);

-- App-State
create table app_state (
  id uuid primary key default gen_random_uuid(),
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
