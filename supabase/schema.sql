create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null check (char_length(trim(full_name)) between 2 and 120),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.student_profiles (
 id uuid primary key references public.profiles(id) on delete cascade,
 education_level text, class_name text, primary_exam text, exam_date date,
 preferred_language text not null default 'en', study_hours numeric(4,2) check(study_hours between 0 and 24 or study_hours is null),
 onboarding_completed boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,full_name) values(new.id,coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Student')) on conflict(id) do nothing; return new; end; $$;
revoke all on function public.handle_new_user() from public,anon,authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create table if not exists public.exams(id uuid primary key default gen_random_uuid(),name text not null,slug text unique not null,authority text,official_url text,status text not null default 'draft' check(status in('draft','published','archived')),created_at timestamptz not null default now());
create table if not exists public.subjects(id uuid primary key default gen_random_uuid(),exam_id uuid references public.exams(id) on delete cascade,name text not null,slug text not null,status text not null default 'draft' check(status in('draft','under_review','verified','published','archived')),unique(exam_id,slug));
create table if not exists public.chapters(id uuid primary key default gen_random_uuid(),subject_id uuid not null references public.subjects(id) on delete cascade,name text not null,slug text not null,order_index int not null default 0,status text not null default 'draft',unique(subject_id,slug));
create table if not exists public.topics(id uuid primary key default gen_random_uuid(),chapter_id uuid not null references public.chapters(id) on delete cascade,name text not null,slug text not null,order_index int not null default 0,status text not null default 'draft',unique(chapter_id,slug));
create table if not exists public.material_sources(id uuid primary key default gen_random_uuid(),provider text not null,title text not null,source_url text not null,license_note text,last_verified_at timestamptz,status text not null default 'unverified',created_at timestamptz not null default now());
create table if not exists public.study_materials(id uuid primary key default gen_random_uuid(),topic_id uuid references public.topics(id) on delete set null,source_id uuid references public.material_sources(id) on delete set null,title text not null,material_type text not null,storage_path text,external_url text,status text not null default 'draft',created_at timestamptz not null default now(),updated_at timestamptz not null default now());

create table if not exists public.questions(id uuid primary key default gen_random_uuid(),topic_id uuid references public.topics(id) on delete set null,source_id uuid references public.material_sources(id) on delete set null,prompt text not null,question_type text not null,difficulty text,solution text,status text not null default 'draft',created_at timestamptz not null default now());
create table if not exists public.question_options(id uuid primary key default gen_random_uuid(),question_id uuid not null references public.questions(id) on delete cascade,label text not null,order_index int not null,unique(question_id,order_index));
create table if not exists public.question_keys(question_id uuid primary key references public.questions(id) on delete cascade,correct_option_ids uuid[] not null default '{}',numerical_answer numeric,explanation text not null);

create table if not exists public.tests(id uuid primary key default gen_random_uuid(),title text not null,test_type text not null,duration_minutes int not null,status text not null default 'draft',scoring_rules jsonb not null default '{}',created_at timestamptz not null default now());
create table if not exists public.test_questions(test_id uuid not null references public.tests(id) on delete cascade,question_id uuid not null references public.questions(id),order_index int not null,primary key(test_id,question_id),unique(test_id,order_index));
create table if not exists public.test_attempts(id uuid primary key default gen_random_uuid(),test_id uuid not null references public.tests(id),student_id uuid not null references public.profiles(id) on delete cascade,status text not null default 'in_progress',started_at timestamptz not null default now(),submitted_at timestamptz);
create table if not exists public.test_answers(id uuid primary key default gen_random_uuid(),attempt_id uuid not null references public.test_attempts(id) on delete cascade,question_id uuid not null references public.questions(id),selected_option_ids uuid[] not null default '{}',numerical_answer numeric,updated_at timestamptz not null default now(),unique(attempt_id,question_id));
create table if not exists public.test_results(attempt_id uuid primary key references public.test_attempts(id) on delete cascade,score numeric not null,accuracy numeric not null,correct_count int not null,incorrect_count int not null,unanswered_count int not null,subject_breakdown jsonb not null default '{}',topic_breakdown jsonb not null default '{}',computed_at timestamptz not null default now());
create table if not exists public.national_tests(id uuid primary key default gen_random_uuid(),title text not null,test_id uuid references public.tests(id) on delete set null,scheduled_for timestamptz not null,status text not null default 'scheduled',created_at timestamptz not null default now());
create table if not exists public.national_test_participants(national_test_id uuid not null references public.national_tests(id) on delete cascade,attempt_id uuid not null references public.test_attempts(id) on delete cascade,student_id uuid not null references public.profiles(id) on delete cascade,rank int,percentile numeric,primary key(national_test_id,attempt_id));

create table if not exists public.practice_sessions(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,started_at timestamptz not null default now(),completed_at timestamptz);
create table if not exists public.question_attempts(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,session_id uuid references public.practice_sessions(id) on delete cascade,question_id uuid not null references public.questions(id),selected_option_ids uuid[] not null default '{}',numerical_answer numeric,is_correct boolean not null,time_taken_seconds int,created_at timestamptz not null default now());
create table if not exists public.mistakes(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,question_id uuid not null references public.questions(id),attempt_id uuid references public.question_attempts(id) on delete cascade,category text,created_at timestamptz not null default now());
create table if not exists public.study_plans(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,name text not null,start_date date,end_date date,schedule jsonb not null default '{}',created_at timestamptz not null default now());
create table if not exists public.study_tasks(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,title text not null,source_type text,source_id uuid,due_at timestamptz,completed boolean not null default false,created_at timestamptz not null default now());
create table if not exists public.mastery(student_id uuid not null references public.profiles(id) on delete cascade,topic_id uuid not null references public.topics(id) on delete cascade,mastery numeric not null default 0 check(mastery between 0 and 1),updated_at timestamptz not null default now(),primary key(student_id,topic_id));
create table if not exists public.bookmarks(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,entity_type text not null,entity_id uuid not null,created_at timestamptz not null default now(),unique(student_id,entity_type,entity_id));
create table if not exists public.student_notes(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,title text not null,body text not null,entity_type text,entity_id uuid,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.revision_items(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete cascade,topic_id uuid references public.topics(id) on delete set null,due_at timestamptz not null,interval_days int not null default 1,completed_at timestamptz);

alter table public.profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.question_attempts enable row level security;
alter table public.mistakes enable row level security;
alter table public.study_plans enable row level security;
alter table public.study_tasks enable row level security;
alter table public.mastery enable row level security;
alter table public.bookmarks enable row level security;
alter table public.student_notes enable row level security;
alter table public.revision_items enable row level security;
alter table public.test_attempts enable row level security;
alter table public.test_answers enable row level security;
alter table public.test_results enable row level security;

create policy "profiles own row" on public.profiles for select using(auth.uid()=id);
create policy "profiles own update" on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id);
create policy "student profile own row" on public.student_profiles for all using(auth.uid()=id) with check(auth.uid()=id);
create policy "practice own rows" on public.practice_sessions for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "attempts own rows" on public.question_attempts for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "mistakes own rows" on public.mistakes for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "plans own rows" on public.study_plans for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "tasks own rows" on public.study_tasks for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "mastery own rows" on public.mastery for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "bookmarks own rows" on public.bookmarks for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "notes own rows" on public.student_notes for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "revision own rows" on public.revision_items for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "test attempts own rows" on public.test_attempts for all using(auth.uid()=student_id) with check(auth.uid()=student_id);
create policy "test answers via own attempt" on public.test_answers for all using(exists(select 1 from public.test_attempts a where a.id=attempt_id and a.student_id=auth.uid())) with check(exists(select 1 from public.test_attempts a where a.id=attempt_id and a.student_id=auth.uid()));
create policy "test results own rows" on public.test_results for select using(exists(select 1 from public.test_attempts a where a.id=attempt_id and a.student_id=auth.uid()));

create index if not exists idx_questions_topic on public.questions(topic_id);
create index if not exists idx_attempts_student on public.test_attempts(student_id);
create index if not exists idx_practice_student on public.question_attempts(student_id);
