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
  -- 'horizontal_push','vertical_push','horizontal_pull','vertical_pull',
  -- 'hip_hinge','squat','lunge','carry','rotation','anti_rotation',
  -- 'core_flexion','isometrie','mobility'
  movement_patterns         text[],

  -- Ebene 3: Anatomische Muskeln
  -- 'pectoralis_major','pectoralis_minor','serratus_anterior',
  -- 'latissimus_dorsi','trapezius_upper','trapezius_middle','trapezius_lower',
  -- 'rhomboids','erector_spinae','teres_major',
  -- 'deltoid_anterior','deltoid_lateral','deltoid_posterior','rotator_cuff',
  -- 'biceps','triceps','forearms',
  -- 'quadriceps','hamstrings','gluteus_maximus','gluteus_medius',
  -- 'calves','hip_flexors','adductors',
  -- 'rectus_abdominis','obliques','transversus_abdominis','multifidus'
  muscle_groups_anatomical  text[],

  -- DUP Soft Lock
  -- empfohlen: ['kraft','hyper','vol','snack']
  -- erlaubt:   ['kraft','hyper','vol','snack']
  dup_modes_recommended     text[],
  dup_modes_allowed         text[],

  -- Wochenzuweisung: ['A'], ['B'], ['A','B'], ['snack'], null
  week_assignment           text[],

  created_at                timestamptz default now()
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
-- Berechtigungen für anon / authenticated Role
-- (nötig wenn Auto-expose tables deaktiviert ist)
-- ============================================================

grant usage on schema public to anon, authenticated;
grant all on table exercises    to anon, authenticated;
grant all on table training_log to anon, authenticated;
grant all on table app_state    to anon, authenticated;

-- ============================================================
-- Initialer App-State (genau eine Zeile eintragen)
-- ============================================================

insert into app_state (last_training_date, current_dup_index, current_week)
values (null, 0, 'A')
on conflict do nothing;