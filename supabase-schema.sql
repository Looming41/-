-- Kim Eunjeong Institute — Supabase schema
-- Run this once in Supabase SQL Editor (Project > SQL Editor > New query)

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

-- 3. EC achievements (EC 탭 성과)
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

-- Row Level Security: everyone can read, only a logged-in admin can write
alter table team_members enable row level security;
alter table admission_results enable row level security;
alter table ec_achievements enable row level security;
alter table news_posts enable row level security;

create policy "public read team_members" on team_members for select using (true);
create policy "public read admission_results" on admission_results for select using (true);
create policy "public read ec_achievements" on ec_achievements for select using (true);
create policy "public read news_posts" on news_posts for select using (true);

create policy "admin write team_members" on team_members for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "admin write admission_results" on admission_results for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "admin write ec_achievements" on ec_achievements for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "admin write news_posts" on news_posts for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Storage: bucket "Photos" must already exist (Storage > New bucket > Photos > Public).
-- Public read for everyone, upload/replace/delete only for a logged-in admin.
create policy "public read Photos" on storage.objects for select
  using (bucket_id = 'Photos');

create policy "admin upload Photos" on storage.objects for insert
  with check (bucket_id = 'Photos' and auth.role() = 'authenticated');

create policy "admin update Photos" on storage.objects for update
  using (bucket_id = 'Photos' and auth.role() = 'authenticated');

create policy "admin delete Photos" on storage.objects for delete
  using (bucket_id = 'Photos' and auth.role() = 'authenticated');
