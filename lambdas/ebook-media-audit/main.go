package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/jackc/pgx/v5/pgxpool"
)

type event struct{}

type auditFinding struct {
	Kind string `json:"kind"` // orphan_in_s3 | missing_in_s3
	Key  string `json:"key"`
}

type result struct {
	CheckedS3 int            `json:"checked_s3"`
	Orphans   []auditFinding `json:"orphans"`
	Missing   []auditFinding `json:"missing"`
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
	res := result{}
	// AWS
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = os.Getenv("AWS_DEFAULT_REGION")
	}
	if region == "" {
		region = "eu-central-1"
	}
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return res, err
	}
	s3c := s3.NewFromConfig(cfg)
	sm := secretsmanager.NewFromConfig(cfg)

	bucket := os.Getenv("MEDIA_BUCKET")
	if bucket == "" {
		bucket = "expotoworld-media"
	}
	prefix := os.Getenv("AUDIT_PREFIX")
	if prefix == "" {
		prefix = "ebooks/huashangdao/"
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

	// Iterate S3
	var token *string
	for {
		out, err := s3c.ListObjectsV2(ctx, &s3.ListObjectsV2Input{Bucket: &bucket, Prefix: aws.String(prefix), ContinuationToken: token})
		if err != nil {
			return res, err
		}
		for _, obj := range out.Contents {
			key := aws.ToString(obj.Key)
			res.CheckedS3++
			var exists bool
			err := pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM ebook_media_usage WHERE media_key=$1)`, key).Scan(&exists)
			if err == nil && !exists {
				res.Orphans = append(res.Orphans, auditFinding{Kind: "orphan_in_s3", Key: key})
			}
		}
		if aws.ToBool(out.IsTruncated) && out.NextContinuationToken != nil {
			token = out.NextContinuationToken
		} else {
			break
		}
	}

	// Spot-check DB rows that no longer exist in S3 (cheap heuristic)
	rows, _ := pool.Query(ctx, `SELECT media_key FROM ebook_media_usage WHERE last_seen_at < now() - interval '90 days' LIMIT 1000`)
	defer rows.Close()
	for rows.Next() {
		var key string
		_ = rows.Scan(&key)
		_, err := s3c.HeadObject(ctx, &s3.HeadObjectInput{Bucket: &bucket, Key: &key})
		if err != nil && strings.Contains(err.Error(), "NotFound") {
			res.Missing = append(res.Missing, auditFinding{Kind: "missing_in_s3", Key: key})
		}
	}

	log.Printf("audit: s3_checked=%d orphans=%d missing=%d", res.CheckedS3, len(res.Orphans), len(res.Missing))
	return res, nil
}

func main() { lambda.Start(handler) }
