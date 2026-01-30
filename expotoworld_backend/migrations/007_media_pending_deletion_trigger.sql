-- Migration: Add trigger for automatic pending deletion scheduling
-- This trigger fires on UPDATE of ebook_media_usage table
-- When all usage indicators are false/zero, it schedules the media for pending deletion
-- When media is re-added (any usage indicator becomes active), it removes from pending

-- Create the trigger function
CREATE OR REPLACE FUNCTION fn_check_media_pending_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if all usage flags indicate the media is no longer in use
  IF NEW.in_autosave = false AND NEW.manual_refs = 0 AND NEW.published_refs = 0 THEN
    -- Schedule for pending deletion with 15-minute buffer
    -- Use ON CONFLICT to avoid duplicate entries
    INSERT INTO ebook_media_pending_deletion (media_key, requested_at, not_before, attempts)
    VALUES (NEW.media_key, now(), now() + interval '15 minutes', 0)
    ON CONFLICT (media_key) DO UPDATE SET
      requested_at = now(),
      not_before = now() + interval '15 minutes',
      attempts = 0;
  ELSE
    -- Media is still in use somewhere, remove from pending if present
    DELETE FROM ebook_media_pending_deletion WHERE media_key = NEW.media_key;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists (for idempotency)
DROP TRIGGER IF EXISTS trg_check_media_pending_deletion ON ebook_media_usage;

-- Create the trigger
CREATE TRIGGER trg_check_media_pending_deletion
AFTER UPDATE ON ebook_media_usage
FOR EACH ROW
EXECUTE FUNCTION fn_check_media_pending_deletion();

-- ROLLBACK SCRIPT (if needed):
-- DROP TRIGGER IF EXISTS trg_check_media_pending_deletion ON ebook_media_usage;
-- DROP FUNCTION IF EXISTS fn_check_media_pending_deletion();
