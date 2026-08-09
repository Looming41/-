-- 유앤UP 국제컨설팅 — Supabase schema
-- Run this in Supabase SQL Editor (Project > SQL Editor > New query).
-- Safe to re-run in full any time: tables use IF NOT EXISTS and policies are dropped/recreated.

create extension if not exists "pgcrypto";

-- 1. Team members (원장 팀)
create table if not exists team_members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  position text,
  education text,
  career text,
  photo_url text,
  display_order int default 0,
  created_at timestamptz default now()
);

-- 2. Admission results (입시결과)
create table if not exists admission_results (
  id uuid primary key default gen_random_uuid(),
  school_name text not null,
  photo_url text,
  display_order int default 0,
  created_at timestamptz default now()
);

-- 3. EC achievements (EC 탭 성과 - 관리자가 등록하는 공개 성과)
create table if not exists ec_achievements (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in (
    'Engineering/STEM/Research',
    'Medicine/Biomedical',
    'Economics',
    'Statistics/Mathematics',
    'Essay'
  )),
  description text not null,
  photo_url text,
  display_order int default 0,
  created_at timestamptz default now()
);

-- 4. News posts (미국입시뉴스)
create table if not exists news_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  display_order int default 0,
  created_at timestamptz default now()
);

-- 5. Admins — only user IDs listed here are treated as site admins.
-- IMPORTANT: after running this script, register your existing admin login by running:
--   insert into admins (id) select id from auth.users where email = '관리자 이메일 주소';
create table if not exists admins (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- 6. Admission tier benchmarks (터미널 게이지 그래프 기준값 - 관리자 수정 가능)
create table if not exists benchmarks (
  tier text primary key,
  tier_label text not null,
  tier_order int not null,
  avg_gpa numeric(3,2) not null,
  sat_low int not null,
  sat_high int not null,
  ap4_low int not null,
  ap4_high int not null,
  updated_at timestamptz default now()
);

insert into benchmarks (tier, tier_label, tier_order, avg_gpa, sat_low, sat_high, ap4_low, ap4_high) values
  ('top1_5',   'Top 1-5',   1, 3.94, 1520, 1580, 8, 12),
  ('top5_10',  'Top 5-10',  2, 3.93, 1520, 1580, 8, 12),
  ('top10_15', 'Top 10-15', 3, 3.92, 1510, 1570, 7, 12),
  ('top15_20', 'Top 15-20', 4, 3.91, 1490, 1560, 7, 11),
  ('top20_30', 'Top 20-30', 5, 3.86, 1440, 1550, 6, 10),
  ('top30_50', 'Top 30-50', 6, 3.81, 1420, 1535, 5, 8)
on conflict (tier) do update set
  tier_label = excluded.tier_label,
  tier_order = excluded.tier_order,
  avg_gpa = excluded.avg_gpa,
  sat_low = excluded.sat_low,
  sat_high = excluded.sat_high,
  ap4_low = excluded.ap4_low,
  ap4_high = excluded.ap4_high;

-- 7. Students (터미널 회원가입)
create table if not exists students (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  school text not null,
  grade_at_signup int not null,
  signup_school_year int not null,
  sat_score int,
  target_tier text references benchmarks(tier),
  created_at timestamptz default now()
);
alter table students add column if not exists target_tier text references benchmarks(tier);

-- 8. GPA records (학년/학기별)
create table if not exists gpa_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  grade int not null,
  semester int not null check (semester in (1, 2)),
  gpa numeric(3,2) not null,
  created_at timestamptz default now(),
  unique (student_id, grade, semester)
);

-- 9. AP scores (과목별). grade = 시험 응시 학년 (성적 추이 그래프에 사용)
create table if not exists ap_scores (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  subject text not null,
  score int not null check (score between 1 and 5),
  grade int,
  created_at timestamptz default now(),
  unique (student_id, subject)
);
alter table ap_scores add column if not exists grade int;

-- 9b. SAT scores (응시 이력 - 재응시 추이 추적용)
create table if not exists sat_scores (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  score int not null check (score between 400 and 1600),
  test_date date not null default current_date,
  created_at timestamptz default now()
);

-- 10. EC records (학생이 직접 기입하는 활동)
create table if not exists ec_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  category text not null,
  title text not null,
  description text,
  created_at timestamptz default now()
);

-- ---------- Row Level Security ----------
alter table team_members enable row level security;
alter table admission_results enable row level security;
alter table ec_achievements enable row level security;
alter table news_posts enable row level security;
alter table admins enable row level security;
alter table benchmarks enable row level security;
alter table students enable row level security;
alter table gpa_records enable row level security;
alter table ap_scores enable row level security;
alter table sat_scores enable row level security;
alter table ec_records enable row level security;

-- Public read for site content
drop policy if exists "public read team_members" on team_members;
create policy "public read team_members" on team_members for select using (true);

drop policy if exists "public read admission_results" on admission_results;
create policy "public read admission_results" on admission_results for select using (true);

drop policy if exists "public read ec_achievements" on ec_achievements;
create policy "public read ec_achievements" on ec_achievements for select using (true);

drop policy if exists "public read news_posts" on news_posts;
create policy "public read news_posts" on news_posts for select using (true);

-- Admin-only write for site content (checks membership in `admins`, NOT just "is logged in" —
-- students also get accounts now, so `auth.role() = 'authenticated'` would have let any student
-- edit/delete site content and is no longer used).
drop policy if exists "admin write team_members" on team_members;
create policy "admin write team_members" on team_members for all
  using (exists (select 1 from admins where id = auth.uid()))
  with check (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "admin write admission_results" on admission_results;
create policy "admin write admission_results" on admission_results for all
  using (exists (select 1 from admins where id = auth.uid()))
  with check (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "admin write ec_achievements" on ec_achievements;
create policy "admin write ec_achievements" on ec_achievements for all
  using (exists (select 1 from admins where id = auth.uid()))
  with check (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "admin write news_posts" on news_posts;
create policy "admin write news_posts" on news_posts for all
  using (exists (select 1 from admins where id = auth.uid()))
  with check (exists (select 1 from admins where id = auth.uid()));

-- Admins table: a user may only check their own membership row
drop policy if exists "self read admins" on admins;
create policy "self read admins" on admins for select using (auth.uid() = id);

-- Benchmarks: everyone can read (used in student gauge charts), only admins can edit
drop policy if exists "public read benchmarks" on benchmarks;
create policy "public read benchmarks" on benchmarks for select using (true);

drop policy if exists "admin write benchmarks" on benchmarks;
create policy "admin write benchmarks" on benchmarks for all
  using (exists (select 1 from admins where id = auth.uid()))
  with check (exists (select 1 from admins where id = auth.uid()));

-- Students: a student manages only their own profile; admins can read everyone's
drop policy if exists "student read own profile" on students;
create policy "student read own profile" on students for select using (auth.uid() = id);

drop policy if exists "student insert own profile" on students;
create policy "student insert own profile" on students for insert with check (auth.uid() = id);

drop policy if exists "student update own profile" on students;
create policy "student update own profile" on students for update using (auth.uid() = id);

drop policy if exists "admin read all students" on students;
create policy "admin read all students" on students for select
  using (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "admin delete students" on students;
create policy "admin delete students" on students for delete
  using (exists (select 1 from admins where id = auth.uid()));

-- GPA / AP / EC records: a student manages only their own rows; admins can read everyone's
drop policy if exists "student manage own gpa" on gpa_records;
create policy "student manage own gpa" on gpa_records for all
  using (auth.uid() = student_id) with check (auth.uid() = student_id);

drop policy if exists "admin read all gpa" on gpa_records;
create policy "admin read all gpa" on gpa_records for select
  using (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "student manage own ap" on ap_scores;
create policy "student manage own ap" on ap_scores for all
  using (auth.uid() = student_id) with check (auth.uid() = student_id);

drop policy if exists "admin read all ap" on ap_scores;
create policy "admin read all ap" on ap_scores for select
  using (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "student manage own sat" on sat_scores;
create policy "student manage own sat" on sat_scores for all
  using (auth.uid() = student_id) with check (auth.uid() = student_id);

drop policy if exists "admin read all sat" on sat_scores;
create policy "admin read all sat" on sat_scores for select
  using (exists (select 1 from admins where id = auth.uid()));

drop policy if exists "student manage own ec" on ec_records;
create policy "student manage own ec" on ec_records for all
  using (auth.uid() = student_id) with check (auth.uid() = student_id);

drop policy if exists "admin read all ec" on ec_records;
create policy "admin read all ec" on ec_records for select
  using (exists (select 1 from admins where id = auth.uid()));

-- ---------- Storage ----------
-- Bucket "Photos" must already exist (Storage > New bucket > Photos > Public).
-- Public read for everyone, upload/replace/delete only for a registered admin.
drop policy if exists "public read Photos" on storage.objects;
create policy "public read Photos" on storage.objects for select
  using (bucket_id = 'Photos');

drop policy if exists "admin upload Photos" on storage.objects;
create policy "admin upload Photos" on storage.objects for insert
  with check (bucket_id = 'Photos' and exists (select 1 from admins where id = auth.uid()));

drop policy if exists "admin update Photos" on storage.objects;
create policy "admin update Photos" on storage.objects for update
  using (bucket_id = 'Photos' and exists (select 1 from admins where id = auth.uid()));

drop policy if exists "admin delete Photos" on storage.objects;
create policy "admin delete Photos" on storage.objects for delete
  using (bucket_id = 'Photos' and exists (select 1 from admins where id = auth.uid()));

-- ---------- One-time setup ----------
-- Register your existing admin account (replace with the real admin login email):
-- insert into admins (id) select id from auth.users where email = 'your-admin-email@example.com';
