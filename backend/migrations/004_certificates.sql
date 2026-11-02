-- Issued certificates. Each stores a snapshot of what it certified, so a public
-- check can tell whether the parcel record has changed since.
CREATE SEQUENCE certificate_number_seq;

CREATE TABLE certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number TEXT NOT NULL UNIQUE,      -- C-2026-000123, printed on the certificate
    code TEXT NOT NULL UNIQUE,        -- 8 random characters behind the QR code
    parcel_id UUID NOT NULL REFERENCES parcels (id),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    issued_by UUID REFERENCES users (id),
    snapshot JSONB NOT NULL
);

CREATE INDEX idx_certificates_parcel ON certificates (parcel_id, issued_at DESC);

-- Unknown codes looked up from one address, to throttle guessing.
CREATE TABLE verification_misses (
    id BIGSERIAL PRIMARY KEY,
    ip TEXT,
    at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_verification_misses_ip ON verification_misses (ip, at);
