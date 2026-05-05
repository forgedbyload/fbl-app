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

-- Trainingshistorie (nur nicht-ableitbare Felder – rest kommt aus set_log)
create table if not exists training_log (
  id                 uuid primary key default gen_random_uuid(),
  date               date not null,
  session_id         uuid references sessions(id),
  exercises_skipped  uuid[],
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
  id              uuid primary key default gen_random_uuid(),
  current_week    text    default 'A',      -- 'A' oder 'B'
  week_b_enabled  boolean default false
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

-- set_log: Satzprotokoll pro Training
create table if not exists set_log (
  id                    uuid primary key default gen_random_uuid(),
  exercise_id           uuid references exercises(id),
  session_id            uuid references sessions(id),
  session_date          date not null,
  set_number            int not null,
  total_sets_in_session int not null,
  weight_kg             numeric,
  reps                  int,
  rir                   int,
  equipment             text,
  dup_mode              text,           -- 'kraft','hyper','vol','flexibility' – denormalisiert für Stats
  week                  text,           -- 'A' oder 'B' – denormalisiert für Stats
  created_at            timestamptz default now()
);

alter table set_log enable row level security;
create policy "Alle Zugriffe erlaubt (kein Auth)" on set_log
  for all using (true) with check (true);
grant all on table set_log to anon, authenticated;

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
--
-- Migration: dup_mode + week auf set_log (für Stats ohne Join)
-- alter table set_log add column if not exists dup_mode text;
-- alter table set_log add column if not exists week text;
--
-- Migration: training_log auf nicht-ableitbare Felder reduzieren
-- alter table training_log drop column if exists session_type;
-- alter table training_log drop column if exists week;
-- alter table training_log drop column if exists exercises_done;
-- alter table training_log drop column if exists sets_completed;
-- alter table training_log add column if not exists session_id uuid references sessions(id);
-- alter table training_log add column if not exists exercises_skipped uuid[];
--
-- Migration: week_b_enabled auf app_state
-- alter table app_state add column if not exists week_b_enabled boolean default false;

-- ============================================================
-- Funktion & Trigger: PR auto-update nach set_log insert
-- ============================================================

create or replace function update_pr()
returns trigger as $$
begin
  update exercises
  set strength_weights = (
    select jsonb_agg(
      case
        when sw->>'type' = NEW.equipment
        and (NEW.weight_kg is not null)
        and (NEW.weight_kg > coalesce((sw->>'personal_record')::numeric, 0))
        then jsonb_set(sw, '{personal_record}', to_jsonb(NEW.weight_kg))
        else sw
      end
    )
    from jsonb_array_elements(strength_weights) as sw
  )
  where id = NEW.exercise_id
  and strength_weights is not null;
  return NEW;
end;
$$ language plpgsql;

create trigger trigger_update_pr
after insert on set_log
for each row execute function update_pr();
