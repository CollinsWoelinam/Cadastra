CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE parcels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Client-generated id so offline uploads can be retried without duplicates.
    client_ref UUID UNIQUE,
    title_deed_no VARCHAR(50) UNIQUE NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    boundary GEOMETRY(Polygon, 4326) NOT NULL
        CHECK (ST_IsValid(boundary) AND NOT ST_IsEmpty(boundary)),
    area_sqm DOUBLE PRECISION GENERATED ALWAYS AS (ST_Area(boundary::geography)) STORED,
    perimeter_m DOUBLE PRECISION GENERATED ALWAYS AS (ST_Perimeter(boundary::geography)) STORED,
    -- Worst horizontal accuracy (m) reported across the captured nodes, if known.
    survey_accuracy_m DOUBLE PRECISION CHECK (survey_accuracy_m >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    review_note TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parcels_boundary ON parcels USING GIST (boundary);
CREATE INDEX idx_parcels_status ON parcels (status);

-- Raw field nodes as captured, kept for evidentiary purposes.
CREATE TABLE survey_points (
    id BIGSERIAL PRIMARY KEY,
    parcel_id UUID NOT NULL REFERENCES parcels (id) ON DELETE CASCADE,
    seq INTEGER NOT NULL,
    geom GEOMETRY(Point, 4326) NOT NULL,
    accuracy_m DOUBLE PRECISION CHECK (accuracy_m >= 0),
    captured_at TIMESTAMPTZ,
    UNIQUE (parcel_id, seq)
);

-- Append-only audit trail; registry history must never be rewritten.
CREATE TABLE parcel_events (
    id BIGSERIAL PRIMARY KEY,
    parcel_id UUID NOT NULL REFERENCES parcels (id),
    event_type VARCHAR(30) NOT NULL,
    detail JSONB NOT NULL DEFAULT '{}'::jsonb,
    at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parcel_events_parcel ON parcel_events (parcel_id, at);

CREATE FUNCTION forbid_event_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'parcel_events is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER parcel_events_append_only
    BEFORE UPDATE OR DELETE ON parcel_events
    FOR EACH ROW EXECUTE FUNCTION forbid_event_mutation();
