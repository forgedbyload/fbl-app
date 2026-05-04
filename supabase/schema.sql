-- ============================================================
-- fbl-app Supabase Schema
-- Region: Europe (Frankfurt)
-- RLS: aktiviert
-- Auto-expose tables: deaktiviert
-- ============================================================

-- Übungsbibliothek
create table if not exists exercises (
  id                        uuid primary key default gen_random_uuid(),
  name                      text not null,
  gif_base64                text,

  -- Ebene 1: Körperregion
  -- 'chest','back','shoulders','arms','legs','core','mobility'
  body_regions              text[],

  -- Ebene 2: Movement Pattern
  movement_patterns         text[],

  -- Ebene 3: Anatomische Muskeln
  muscle_groups_anatomical  text[],

  -- DUP-Modi: ['kraft','hyper','vol','flexibility']
  dup_modes                 text[],

  -- Krafttraining: Gewichte pro Equipment-Typ
  -- { "barbell": {"working_weight": 80, "pr": 100}, ... }
  strength_weights          jsonb,

  -- Wochenzuweisung: ['A'], ['B'], ['A','B'], null
  week_assignment           text[],

  created_at                timestamptz default now()
);

-- Trainingshistorie
create table if not exists training_log (
  id                 uuid primary key default gen_random_uuid(),
  date               date not null,
  session_type       text not null,  -- 'kraft','hyper','vol','flexibility'
  week               text,           -- 'A' oder 'B'
  exercises_done     uuid[],
  sets_completed     int,
  duration_minutes   int,
  created_at         timestamptz default now()
);

-- Wochenplan-Sessions
create table if not exists sessions (
  id            uuid primary key default gen_random_uuid(),
  week          text not null,         -- 'A' oder 'B'
  weekday       text not null,         -- 'Mo','Di','Mi','Do','Fr','Sa','So'
  dup_mode      text not null,         -- 'kraft','hyper','vol','flexibility'
  exercise_ids  uuid[],
  work_seconds  int,                   -- null bei flexibility
  rest_seconds  int,                   -- null bei flexibility
  title         text,
  created_at    timestamptz default now()
);

-- App-State (genau eine Zeile)
create table if not exists app_state (
  id            uuid primary key default gen_random_uuid(),
  current_week  text default 'A'       -- 'A' oder 'B'
);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table exercises    enable row level security;
alter table training_log enable row level security;
alter table sessions     enable row level security;
alter table app_state    enable row level security;

create policy "Alle Zugriffe erlaubt (kein Auth)" on exercises
  for all using (true) with check (true);

create policy "Alle Zugriffe erlaubt (kein Auth)" on training_log
  for all using (true) with check (true);

create policy "Alle Zugriffe erlaubt (kein Auth)" on sessions
  for all using (true) with check (true);

create policy "Alle Zugriffe erlaubt (kein Auth)" on app_state
  for all using (true) with check (true);

-- ============================================================
-- Berechtigungen
-- ============================================================

grant usage on schema public to anon, authenticated;
grant all on table exercises    to anon, authenticated;
grant all on table training_log to anon, authenticated;
grant all on table sessions     to anon, authenticated;
grant all on table app_state    to anon, authenticated;

-- ============================================================
-- Initialer App-State
-- ============================================================

insert into app_state (current_week)
values ('A')
on conflict do nothing;

-- ============================================================
-- Migration (in Supabase SQL Editor ausführen):
-- ============================================================
-- alter table exercises
--   drop column if exists dup_modes_recommended,
--   drop column if exists dup_modes_allowed;
-- alter table exercises
--   add column if not exists dup_modes text[],
--   add column if not exists strength_weights jsonb;
-- alter table app_state
--   drop column if exists last_training_date,
--   drop column if exists current_dup_index;
--
-- Migration: exercise_ids von uuid[] auf jsonb [{exercise_id, sets}]
-- alter table sessions drop column if exists exercise_ids;
-- alter table sessions add column exercise_ids jsonb;
