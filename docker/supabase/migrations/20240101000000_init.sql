-- =============================================================================
-- Hatch — initial Supabase/PostgreSQL schema
-- Mirrors the Drift schema in packages/core, with RLS policies.
-- =============================================================================

-- Enable pgvector (available via pgvector/pgvector image)
CREATE EXTENSION IF NOT EXISTS vector;

-- ---------------------------------------------------------------------------
-- Schemas required by Supabase services (must exist before services start)
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS _realtime;

-- ---------------------------------------------------------------------------
-- Roles for Supabase services and PostgREST
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    CREATE ROLE supabase_storage_admin NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator NOLOGIN NOINHERIT;
  END IF;
END
$$;

-- Allow postgres superuser to act as service roles
GRANT service_role TO postgres;
GRANT supabase_admin TO postgres;
GRANT supabase_auth_admin TO postgres;
GRANT supabase_storage_admin TO postgres;

-- Public schema access
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- Auth schema access for GoTrue
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA auth TO postgres;

-- Realtime schema access
GRANT ALL ON SCHEMA _realtime TO supabase_admin;
GRANT ALL ON SCHEMA _realtime TO postgres;

-- ---------------------------------------------------------------------------
-- Stub auth helper functions
-- GoTrue will CREATE OR REPLACE these with real JWT-reading implementations
-- when it runs its own migrations. The stubs allow RLS policies that reference
-- auth.uid() / auth.role() / auth.email() to be created before GoTrue starts.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.uid()
  RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT NULL::uuid $$;

CREATE OR REPLACE FUNCTION auth.role()
  RETURNS text LANGUAGE sql STABLE AS $$ SELECT NULL::text $$;

CREATE OR REPLACE FUNCTION auth.email()
  RETURNS text LANGUAGE sql STABLE AS $$ SELECT NULL::text $$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT UNIQUE NOT NULL,
    name        TEXT NOT NULL,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc         TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.trips (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    destination TEXT NOT NULL,
    start_date  TIMESTAMPTZ,
    end_date    TIMESTAMPTZ,
    status      TEXT NOT NULL DEFAULT 'draft',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc         TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.trip_days (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id     UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    day_number  INTEGER NOT NULL,
    date        TIMESTAMPTZ,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc         TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.places (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    address     TEXT,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    category    TEXT,
    external_id TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc         TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.activities (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_day_id UUID NOT NULL REFERENCES public.trip_days(id) ON DELETE CASCADE,
    place_id    UUID REFERENCES public.places(id),
    title       TEXT NOT NULL,
    type        TEXT NOT NULL,
    starts_at   TIMESTAMPTZ,
    ends_at     TIMESTAMPTZ,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc         TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.flights (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    flight_number   TEXT,
    airline         TEXT,
    origin          TEXT NOT NULL,
    destination     TEXT NOT NULL,
    departs_at      TIMESTAMPTZ NOT NULL,
    arrives_at      TIMESTAMPTZ NOT NULL,
    booking_ref     TEXT,
    seat_class      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc             TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.hotels (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id             UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name                TEXT NOT NULL,
    address             TEXT,
    check_in            TIMESTAMPTZ,
    check_out           TIMESTAMPTZ,
    confirmation_number TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc                 TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.notes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id    UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    category   TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc        TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id     UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    activity_id UUID REFERENCES public.activities(id),
    currency    TEXT NOT NULL DEFAULT 'USD',
    amount      DOUBLE PRECISION NOT NULL,
    category    TEXT,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc         TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.attachments (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id      UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    mime_type    TEXT NOT NULL,
    file_name    TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    size_bytes   INTEGER,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc          TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.collaborators (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id    UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role       TEXT NOT NULL DEFAULT 'viewer',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc        TEXT NOT NULL DEFAULT '',
    UNIQUE (trip_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.sync_log (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_table TEXT NOT NULL,
    entity_id    UUID NOT NULL,
    operation    TEXT NOT NULL,
    payload      JSONB,
    synced       BOOLEAN NOT NULL DEFAULT false,
    synced_at    TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    hlc          TEXT NOT NULL DEFAULT ''
);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE public.users        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_days    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.places       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flights      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_log     ENABLE ROW LEVEL SECURITY;

-- Users: own row only
CREATE POLICY users_self ON public.users
    USING (id = auth.uid());

-- Trips: owner or collaborator
CREATE POLICY trips_owner ON public.trips
    USING (user_id = auth.uid());

CREATE POLICY trips_collaborator ON public.trips
    USING (
        EXISTS (
            SELECT 1 FROM public.collaborators c
            WHERE c.trip_id = trips.id AND c.user_id = auth.uid()
        )
    );

-- Trip-scoped tables: user must own or collaborate on the parent trip
CREATE POLICY trip_days_access ON public.trip_days
    USING (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = trip_days.trip_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY activities_access ON public.activities
    USING (
        EXISTS (
            SELECT 1 FROM public.trip_days td
            JOIN public.trips t ON t.id = td.trip_id
            WHERE td.id = activities.trip_day_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY flights_access ON public.flights
    USING (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = flights.trip_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY hotels_access ON public.hotels
    USING (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = hotels.trip_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY notes_access ON public.notes
    USING (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = notes.trip_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY expenses_access ON public.expenses
    USING (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = expenses.trip_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY attachments_access ON public.attachments
    USING (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = attachments.trip_id
              AND (t.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.collaborators c
                WHERE c.trip_id = t.id AND c.user_id = auth.uid()
              ))
        )
    );

CREATE POLICY collaborators_access ON public.collaborators
    USING (
        collaborators.user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = collaborators.trip_id AND t.user_id = auth.uid()
        )
    );

CREATE POLICY places_select ON public.places
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY places_write ON public.places
    FOR ALL USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY sync_log_access ON public.sync_log
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);
