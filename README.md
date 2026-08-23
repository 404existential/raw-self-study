# RAW — Real Academic Work

A free, high-end self-study platform foundation.

## Non-negotiables

- Email + password only. No OTP, magic links, phone login or passwordless login.
- No fabricated academic data, scores, ranks, participants, schedules or question counts.
- Student data belongs in Supabase/Postgres, not localStorage.
- Browser code contains only the public Supabase anon/publishable key.
- Never expose a service-role key or AI provider secret to the browser.
- Academic material must have a source or be clearly marked as original/unverified.
- Copyrighted third-party material is not copied into RAW without permission.
- Correct answers and authoritative scoring must not be exposed as trusted client data.
- RLS is required for private student records.

## Run

```bash
npm install
cp .env.example .env
npm run dev
```

Configure `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.

Apply `supabase/schema.sql` to a fresh Supabase project. Enable email/password authentication. Do not enable OTP or passwordless authentication for the product flow.

## Academic sources

`data/official-sources.json` contains a source catalog for official JEE Main 2026, NEET UG 2026, CBSE 2026–27 and NCERT resources. RAW stores source metadata and links; it does not pretend third-party material is RAW-owned content.

## Production gate

RAW is not considered production-ready until server-side test submission/scoring, AI Edge Functions, document processing, content review, moderation, rate limiting, storage policies and security tests are implemented and verified. Empty states are intentional when real data is unavailable.
