package ebookschema

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Init creates/verifies media tracking tables for the ebook service.
// Safe to call at startup; idempotent.
func Init(ctx context.Context, pool *pgxpool.Pool) error {
	if pool == nil {
		return fmt.Errorf("nil pool")
	}

	stmts := []string{
		`CREATE TABLE IF NOT EXISTS ebook_media_usage (
			media_key TEXT PRIMARY KEY,
			in_autosave BOOLEAN NOT NULL DEFAULT false,
			manual_refs INTEGER NOT NULL DEFAULT 0,
			published_refs INTEGER NOT NULL DEFAULT 0,
			last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
		);`,
		`CREATE TABLE IF NOT EXISTS ebook_media_pending_deletion (
			media_key TEXT PRIMARY KEY,
			requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			not_before TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '15 minutes'),
			attempts INTEGER NOT NULL DEFAULT 0,
			last_checked_at TIMESTAMPTZ
		);`,
		`CREATE INDEX IF NOT EXISTS idx_media_pending_due ON ebook_media_pending_deletion(not_before);`,
		`CREATE TABLE IF NOT EXISTS ebook_version_media (
			version_id UUID NOT NULL,
			media_key TEXT NOT NULL,
			PRIMARY KEY(version_id, media_key)
		);`,
		`CREATE TABLE IF NOT EXISTS ebook_media_assets (
			media_key TEXT PRIMARY KEY,
			file_type TEXT NOT NULL,
			mime_type TEXT NOT NULL,
			file_size BIGINT,
			created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
		);`,
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin schema tx: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, s := range stmts {
		if _, err := tx.Exec(ctx, s); err != nil {
			return fmt.Errorf("exec schema: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit schema: %w", err)
	}

	log.Println("[EBOOK] Media schema verified")
	return nil
}
