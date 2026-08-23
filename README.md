# RAW — Real Academic Work

RAW is a free, high-end self-study platform for serious preparation.

## Product rules

- Email + password only. No OTP, magic links, phone login or passwordless login.
- Name, email and password are the only required account fields.
- No subscriptions, trials, payment walls or premium locks.
- No fabricated academic data, scores, ranks, participants, schedules or question counts.
- Empty states are intentional when verified data does not exist.
- Student data lives in Supabase/Postgres, not localStorage.
- Browser code may contain only a public Supabase publishable/anon key.
- Never expose a service-role key or AI-provider secret to the browser.
- Correct answers and authoritative scoring must never be trusted from browser state.
- User-generated notes/community content is untrusted input and must not be rendered as raw HTML.
- Academic material must have provenance: official, licensed, RAW-original or clearly unverified.
- Copyrighted third-party material is not copied into RAW without permission.

## Current platform surface

Public:

- cinematic hero banner
- live ambient academic motion
- Learn / Practice / Tests / RAW National discovery
- responsive premium editorial design
- separate pre-login and post-login experiences

Authenticated:

- study room dashboard
- Learn
- Infinite Practice
- Tests
- Revision
- Progress
- Mistake Book
- Verified Library
- Study Planner
- RAW National
- RAW Tutor
- My Notes
- Friends
- Study Groups
- Community
- global logout and password recovery

Backend model:

- profiles and student profiles
- exam → subject → chapter → topic hierarchy
- source/provenance tracking
- question bank
- practice attempts
- mastery
- tests and attempts
- revision
- planner/tasks
- notes/bookmarks
- document ownership
- AI session/message ownership
- friends/groups/community/reporting foundations
- RLS and security migrations

## Security

The connected Supabase project has received a production security migration that:

- removes direct browser SELECT access to the legacy `questions` table
- provides a safe question view without the legacy `correct_answer` column
- locks `question_keys` behind RLS
- isolates student-owned records with RLS
- adds indexes for common student access paths
- keeps server-authoritative scoring and AI work explicitly outside the browser

The Supabase security advisor currently reports one remaining warning: leaked-password protection is disabled in Auth. Enable it in the Supabase Auth dashboard before opening RAW to real students.

## Run

```bash
npm install
cp .env.example .env
npm run dev
```

Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.

For a fresh database, use `supabase/schema.sql`. For the existing connected project, the applied production migration is documented under `supabase/migrations/`.

## Academic content policy

RAW does not fill a database with copied textbooks or invented questions just to make the interface look populated. Content must be official, licensed or original and reviewed before it is presented as verified.

## Production gate

RAW should not be marketed as a production exam platform until server-side test submission/scoring, AI Edge Functions, document processing, content review, moderation, rate limiting, private storage policies and security tests are implemented and verified. A polished interface is not a substitute for those controls.
