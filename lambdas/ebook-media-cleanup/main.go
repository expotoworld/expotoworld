package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/jackc/pgx/v5/pgxpool"
)

type event struct{}

type result struct {
	Checked  int `json:"checked"`
	Deleted  int `json:"deleted"`
	Retained int `json:"retained"`
	Errors   int `json:"errors"`
}

type logSummary struct {
	DeletedCount        int            `json:"deleted_count"`
	RetainedCount       int            `json:"retained_count"`
	ErrorCount          int            `json:"error_count"`
	ErrorReasons        map[string]int `json:"error_reasons"`
	Checked             int            `json:"checked"`
	ExecutionDurationMs int64          `json:"execution_duration_ms"`
	Timestamp           string         `json:"ts"`
}

func getSecret(ctx context.Context, sm *secretsmanager.Client, secretArn string) (string, error) {
	out, err := sm.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{SecretId: &secretArn})
	if err != nil {
		return "", fmt.Errorf("get secret: %w", err)
	}
	var payload struct {
		DatabaseURL string `json:"DATABASE_URL"`
	}
	if err := json.Unmarshal([]byte(*out.SecretString), &payload); err != nil {
		return "", fmt.Errorf("parse secret: %w", err)
	}
	if payload.DatabaseURL == "" {
		return "", fmt.Errorf("DATABASE_URL missing in secret")
	}
	return payload.DatabaseURL, nil
}

func handler(ctx context.Context, _ event) (result, error) {
	start := time.Now()
	res := result{}
	// AWS cfg & clients
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = os.Getenv("AWS_DEFAULT_REGION")
	}
	if region == "" {
		region = "eu-central-1"
	}
	awsCfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return res, err
	}
	s3c := s3.NewFromConfig(awsCfg)
	sm := secretsmanager.NewFromConfig(awsCfg)

	bucket := os.Getenv("MEDIA_BUCKET")
	if bucket == "" {
		bucket = "expotoworld-media"
	}
	secretArn := os.Getenv("SECRETS_ARN")
	if secretArn == "" {
		return res, fmt.Errorf("SECRETS_ARN env var is required")
	}

	// DB via Secrets Manager
	dsn, err := getSecret(ctx, sm, secretArn)
	if err != nil {
		return res, err
	}
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return res, err
	}
	defer pool.Close()

	// Ensure required tables exist (idempotent)
	{
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
		}
		for _, s := range stmts {
			if _, err := pool.Exec(ctx, s); err != nil {
				return res, fmt.Errorf("schema init: %w", err)
			}
		}
	}

	// Fetch batch of pending
	rows, err := pool.Query(ctx, `SELECT media_key FROM ebook_media_pending_deletion WHERE not_before <= now() ORDER BY not_before ASC LIMIT 100`)
	if err != nil {
		return res, err
	}
	defer rows.Close()
	keys := []string{}
	for rows.Next() {
		var k string
		_ = rows.Scan(&k)
		keys = append(keys, k)
	}
	res.Checked = len(keys)

	errorReasons := map[string]int{}
	for _, key := range keys {
		var inAutosave bool
		var manualRefs, publishedRefs int
		err := pool.QueryRow(ctx, `SELECT in_autosave, manual_refs, published_refs FROM ebook_media_usage WHERE media_key=$1`, key).Scan(&inAutosave, &manualRefs, &publishedRefs)
		if err == nil && (inAutosave || manualRefs > 0 || publishedRefs > 0) {
			_, _ = pool.Exec(ctx, `DELETE FROM ebook_media_pending_deletion WHERE media_key=$1`, key)
			res.Retained++
			continue
		}
		_, err = s3c.DeleteObject(ctx, &s3.DeleteObjectInput{Bucket: &bucket, Key: &key})
		if err != nil {
			res.Errors++
			reason := "s3_delete_error"
			msg := strings.ToLower(err.Error())
			if strings.Contains(msg, "accessdenied") {
				reason = "s3_access_denied"
			} else if strings.Contains(msg, "timeout") {
				reason = "s3_timeout"
			} else if strings.Contains(msg, "notfound") {
				reason = "s3_not_found"
			}
			errorReasons[reason]++
			_, _ = pool.Exec(ctx, `UPDATE ebook_media_pending_deletion SET not_before = now() + interval '15 minutes', attempts = attempts + 1, last_checked_at = now() WHERE media_key=$1`, key)
			continue
		}
		_, _ = pool.Exec(ctx, `DELETE FROM ebook_media_pending_deletion WHERE media_key=$1`, key)
		_, _ = pool.Exec(ctx, `DELETE FROM ebook_media_usage WHERE media_key=$1`, key)
		res.Deleted++
	}

	// Structured JSON summary
	summary := logSummary{
		DeletedCount:        res.Deleted,
		RetainedCount:       res.Retained,
		ErrorCount:          res.Errors,
		ErrorReasons:        errorReasons,
		Checked:             res.Checked,
		ExecutionDurationMs: time.Since(start).Milliseconds(),
		Timestamp:           time.Now().UTC().Format(time.RFC3339),
	}
	b, _ := json.Marshal(summary)
	log.Printf("%s", b)
	return res, nil
}

func main() { lambda.Start(handler) }
