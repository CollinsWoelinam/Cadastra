-- Sign-in attempts, kept for a day to throttle password guessing.
CREATE TABLE login_attempts (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL,  -- lower-cased as typed; need not belong to an account
    ip TEXT,
    succeeded BOOLEAN NOT NULL,
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_login_attempts_email ON login_attempts (email, attempted_at);
CREATE INDEX idx_login_attempts_ip ON login_attempts (ip, attempted_at);
CREATE INDEX idx_login_attempts_time ON login_attempts (attempted_at);
