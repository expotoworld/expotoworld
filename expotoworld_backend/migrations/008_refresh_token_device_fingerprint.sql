-- Migration 008: Add device_fingerprint for per-device refresh token tracking
-- This enables one refresh token per user per device, with sliding expiry

-- Add device_fingerprint column to app_refresh_tokens
ALTER TABLE app_refresh_tokens ADD COLUMN IF NOT EXISTS device_fingerprint VARCHAR(64);

-- Create partial unique index for one non-revoked token per user per device
-- Only applies when device_fingerprint is NOT NULL (backward compatible with old tokens)
CREATE UNIQUE INDEX IF NOT EXISTS ux_refresh_tokens_user_device 
ON app_refresh_tokens (user_id, device_fingerprint) 
WHERE device_fingerprint IS NOT NULL AND revoked = false;

-- Index for faster lookup by user_id + device_fingerprint
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_device 
ON app_refresh_tokens (user_id, device_fingerprint) 
WHERE revoked = false;

-- Comment explaining the design
COMMENT ON COLUMN app_refresh_tokens.device_fingerprint IS 
'SHA-256 hash of device identifiers (IP + User-Agent). Enables one token per device with sliding expiry, preventing token accumulation while maintaining security.';
