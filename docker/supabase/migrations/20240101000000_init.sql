-- =============================================================================
-- Hatch — initial Supabase/PostgreSQL schema
-- Mirrors the Drift schema in packages/core, with RLS policies.
-- =============================================================================

-- Enable pgvector (available via pgvector/pgvector image)
CREATE EXTENSION IF NOT EXISTS vector;

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

-- Repeat the same collaborator-or-owner pattern for the remaining tables.
-- (abbreviated — same logic applies to activities, flights, hotels, notes,
--  expenses, attachments, sync_log)
