-- =====================================================================
--  Smart Anti-Theft Recovery System — Sprint 1 schema
--  Tables: users, devices
--  (Future sprints: locations, images, commands, alerts, logs)
-- =====================================================================

-- Extensions ---------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid()

-- Enum types ---------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('OWNER', 'ADMIN');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_status') THEN
        CREATE TYPE device_status AS ENUM ('ACTIVE', 'LOST', 'RECOVERED', 'DISABLED');
    END IF;
END$$;

-- users --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(190) UNIQUE NOT NULL,
    phone           VARCHAR(32)  UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(120) NOT NULL,
    role            user_role    NOT NULL DEFAULT 'OWNER',
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- devices ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS devices (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_uid       VARCHAR(190) UNIQUE NOT NULL, -- Android ID / hardware fingerprint
    label            VARCHAR(120) NOT NULL,        -- "My Pixel 8"
    manufacturer     VARCHAR(80),
    model            VARCHAR(80),
    os_version       VARCHAR(40),
    app_version      VARCHAR(20),
    sim_serial       VARCHAR(40),                  -- ICCID (last known)
    sim_operator     VARCHAR(60),
    push_token       VARCHAR(255),                 -- FCM token
    status           device_status NOT NULL DEFAULT 'ACTIVE',
    last_seen_at     TIMESTAMPTZ,
    enrolled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_devices_user_id     ON devices (user_id);
CREATE INDEX IF NOT EXISTS idx_devices_status      ON devices (status);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen   ON devices (last_seen_at);

-- updated_at trigger -------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at   ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_devices_updated_at ON devices;
CREATE TRIGGER trg_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
