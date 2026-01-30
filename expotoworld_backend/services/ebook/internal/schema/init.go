// Package schema provides database schema initialization for the ebook service.
package schema

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Init initializes the ebook service database schema.
// This function is designed to work with the existing legacy database schema.
// It only creates indexes that are safe and compatible with existing tables.
func Init(ctx context.Context, pool *pgxpool.Pool) error {
	// Create indexes only for columns that exist in the legacy schema
	// Note: ebook_media_usage does NOT have ebook_id in the legacy schema (single-ebook design)
	_, err := pool.Exec(ctx, `
		CREATE INDEX IF NOT EXISTS idx_ebook_versions_ebook_id ON ebook_versions(ebook_id);
		CREATE INDEX IF NOT EXISTS idx_ebook_version_media_version_id ON ebook_version_media(version_id);
		CREATE INDEX IF NOT EXISTS idx_ebook_media_pending_not_before ON ebook_media_pending_deletion(not_before);
	`)
	if err != nil {
		return fmt.Errorf("create indexes: %w", err)
	}

	return nil
}

// Verify checks that all required tables exist in the legacy schema.
func Verify(ctx context.Context, pool *pgxpool.Pool) error {
	tables := []string{
		"ebooks",
		"ebook_versions",
		"ebook_media_assets",
		"ebook_media_usage",
		"ebook_media_pending_deletion",
		"ebook_version_media",
	}

	for _, table := range tables {
		var exists bool
		err := pool.QueryRow(ctx, `
			SELECT EXISTS (
				SELECT FROM information_schema.tables 
				WHERE table_name = $1
			)
		`, table).Scan(&exists)
		if err != nil {
			return fmt.Errorf("check table %s: %w", table, err)
		}
		if !exists {
			return fmt.Errorf("table %s does not exist", table)
		}
	}

	return nil
}
