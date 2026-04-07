-- =============================================================
-- InkAcademy – Supabase Database Schema
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor)
-- =============================================================

-- 1. PROFILES (linked to auth.users)
create table if not exists public.profiles (
    id         text primary key,          -- matches auth.users.id
    name       text        not null,
    email      text        not null,
    role       text        not null default 'student',  -- 'student' | 'instructor'
    avatar_url text,
    created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
    on public.profiles for select
    using (auth.uid()::text = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid()::text = id);

create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid()::text = id);


-- 2. MODULES
create table if not exists public.modules (
    id          text primary key,
    title       text        not null,
    description text        not null default '',
    image_url   text,
    is_locked   boolean     not null default false,
    "order"     int         not null default 0,
    created_at  timestamptz not null default now()
);

alter table public.modules enable row level security;

create policy "Modules are readable by everyone"
    on public.modules for select
    using (true);


-- 3. LESSONS
create table if not exists public.lessons (
    id           text primary key,
    module_id    text        not null references public.modules(id) on delete cascade,
    title        text        not null,
    description  text        not null default '',
    video_url    text,
    duration     float8      not null default 0,
    "order"      int         not null default 0,
    is_completed boolean     not null default false,
    created_at   timestamptz not null default now()
);

alter table public.lessons enable row level security;

create policy "Lessons are readable by everyone"
    on public.lessons for select
    using (true);


-- 4. LESSON COMPLETIONS (per user)
create table if not exists public.lesson_completions (
    user_id    text not null,
    lesson_id  text not null references public.lessons(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, lesson_id)
);

alter table public.lesson_completions enable row level security;

create policy "Users can read own completions"
    on public.lesson_completions for select
    using (auth.uid()::text = user_id);

create policy "Users can insert own completions"
    on public.lesson_completions for insert
    with check (auth.uid()::text = user_id);


-- 5. QUIZZES
create table if not exists public.quizzes (
    id            text primary key,
    lesson_id     text        not null references public.lessons(id) on delete cascade,
    passing_score int         not null default 0,
    created_at    timestamptz not null default now()
);

alter table public.quizzes enable row level security;

create policy "Quizzes are readable by everyone"
    on public.quizzes for select
    using (true);


-- 6. QUESTIONS
create table if not exists public.questions (
    id                   text   primary key,
    quiz_id              text   not null references public.quizzes(id) on delete cascade,
    text                 text   not null,
    options              jsonb  not null default '[]'::jsonb,   -- ["A","B","C","D"]
    correct_option_index int    not null default 0,
    type                 text   not null default 'multipleChoice',  -- 'multipleChoice' | 'trueFalse'
    "order"              int    not null default 0
);

alter table public.questions enable row level security;

create policy "Questions are readable by everyone"
    on public.questions for select
    using (true);


-- 7. QUIZ SUBMISSIONS
create table if not exists public.quiz_submissions (
    id         uuid        primary key default gen_random_uuid(),
    quiz_id    text        not null references public.quizzes(id) on delete cascade,
    user_id    text        not null,
    score      int         not null,
    total      int         not null,
    created_at timestamptz not null default now()
);

alter table public.quiz_submissions enable row level security;

create policy "Users can read own submissions"
    on public.quiz_submissions for select
    using (auth.uid()::text = user_id);

create policy "Users can insert own submissions"
    on public.quiz_submissions for insert
    with check (auth.uid()::text = user_id);


-- 8. ASSIGNMENTS
create table if not exists public.assignments (
    id              text primary key,
    user_id         text        not null,
    title           text        not null,
    description     text        not null default '',
    due_date        timestamptz not null,
    submission_date timestamptz,
    file_url        text,
    status          text        not null default 'pending',  -- pending | submitted | reviewed | revisionRequested
    created_at      timestamptz not null default now()
);

alter table public.assignments enable row level security;

create policy "Users can read own assignments"
    on public.assignments for select
    using (auth.uid()::text = user_id);

create policy "Users can update own assignments"
    on public.assignments for update
    using (auth.uid()::text = user_id);


-- 9. FEEDBACKS
create table if not exists public.feedbacks (
    id              text primary key,
    assignment_id   text        not null references public.assignments(id) on delete cascade,
    instructor_id   text        not null,
    instructor_name text        not null,
    comment         text        not null default '',
    rating          int         not null default 0,
    date            timestamptz not null default now()
);

alter table public.feedbacks enable row level security;

create policy "Users can read feedback on own assignments"
    on public.feedbacks for select
    using (
        assignment_id in (
            select id from public.assignments where user_id = auth.uid()::text
        )
    );


-- 10. QR CODES
create table if not exists public.qr_codes (
    id        uuid primary key default gen_random_uuid(),
    payload   text not null unique,
    module_id text not null references public.modules(id) on delete cascade
);

alter table public.qr_codes enable row level security;

create policy "QR codes are readable by everyone"
    on public.qr_codes for select
    using (true);


-- 11. USER MODULE UNLOCKS (via QR)
create table if not exists public.user_module_unlocks (
    user_id    text not null,
    module_id  text not null references public.modules(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, module_id)
);

alter table public.user_module_unlocks enable row level security;

create policy "Users can read own unlocks"
    on public.user_module_unlocks for select
    using (auth.uid()::text = user_id);

create policy "Users can insert own unlocks"
    on public.user_module_unlocks for insert
    with check (auth.uid()::text = user_id);


-- 12. STORAGE BUCKET for assignment uploads
-- Run from Dashboard → Storage → New bucket, or:
insert into storage.buckets (id, name, public)
values ('assignments', 'assignments', true)
on conflict (id) do nothing;

create policy "Authenticated users can upload"
    on storage.objects for insert
    with check (bucket_id = 'assignments' and auth.role() = 'authenticated');

create policy "Public read for assignment files"
    on storage.objects for select
    using (bucket_id = 'assignments');
