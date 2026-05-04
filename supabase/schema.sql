-- ============================================================
-- fbl-app Supabase Schema
-- Region: Europe (Frankfurt)
-- RLS: aktiviert
-- Auto-expose tables: deaktiviert
-- ============================================================

-- Übungsbibliothek
create table if not exists exercises (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  gif_base64       text,
  muscle_groups    text[],   -- z.B. ['push','core','hinge']
  dup_modes        text[],   -- z.B. ['kraft','hyper','vol']
  week_assignment  text,     -- 'A', 'B' oder 'snack'
  created_at       timestamptz default now()
);

-- Trainingshistorie
create table if not exists training_log (
  id                 uuid primary key default gen_random_uuid(),
  date               date not null,
  session_type       text not null,  -- 'kraft','hyper','vol','snack'
  week               text,           -- 'A', 'B' oder null für snack
  exercises_done     uuid[],
  sets_completed     int,
  duration_minutes   int,
  created_at         timestamptz default now()
);

-- App-State (Rolling Schedule – genau eine Zeile)
create table if not exists app_state (
  id                  uuid primary key default gen_random_uuid(),
  last_training_date  date,
  current_dup_index   int  default 0,  -- 0=kraft, 1=hyper, 2=vol
  current_week        text default 'A' -- 'A' oder 'B'
);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table exercises    enable row level security;
alter table training_log enable row level security;
alter table app_state    enable row level security;

-- Temporäre open policies (solange kein Auth aktiv ist).
-- Sobald Auth eingeführt wird, durch user-spezifische Policies ersetzen.

create policy "Alle Zugriffe erlaubt (kein Auth)" on exercises
  for all using (true) with check (true);

create policy "Alle Zugriffe erlaubt (kein Auth)" on training_log
  for all using (true) with check (true);

create policy "Alle Zugriffe erlaubt (kein Auth)" on app_state
  for all using (true) with check (true);

-- ============================================================
-- Initialer App-State (genau eine Zeile eintragen)
-- ============================================================

insert into app_state (last_training_date, current_dup_index, current_week)
values (null, 0, 'A')
on conflict do nothing;
