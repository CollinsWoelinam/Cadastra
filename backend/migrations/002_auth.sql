CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('SURVEYOR', 'REVIEWER', 'ADMIN')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX users_email_key ON users (lower(email));

-- Opaque refresh tokens, stored hashed. Each use rotates the token; presenting an
-- already-rotated token is treated as theft and revokes all of the user's sessions.
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id) WHERE revoked_at IS NULL;

-- Parcels created before accounts existed keep NULL here.
ALTER TABLE parcels
    ADD COLUMN submitted_by UUID REFERENCES users (id),
    ADD COLUMN reviewed_by UUID REFERENCES users (id);

ALTER TABLE parcel_events ADD COLUMN actor_id UUID REFERENCES users (id);
