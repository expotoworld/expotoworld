package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	cwtypes "github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/jackc/pgx/v5/pgxpool"
)

type secretPayload struct {
	DatabaseURL string `json:"DATABASE_URL"`
}

type result struct {
	AdminCodesExpired       int64
	AdminCodesUsed          int64
	AdminRateLimits         int64
	UserCodesExpired        int64
	UserCodesUsed           int64
	UserPhoneCodesExp       int64
	UserPhoneCodesUsed      int64
	UserRateLimits          int64
	RevokedRefreshTokens24h int64
	ExpiredRefreshTokens7d  int64
}

func getSecret(ctx context.Context, sm *secretsmanager.Client, secretArn string) (string, error) {
	out, err := sm.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{SecretId: &secretArn})
	if err != nil {
		return "", fmt.Errorf("get secret: %w", err)
	}
	var payload secretPayload
	if err := json.Unmarshal([]byte(*out.SecretString), &payload); err != nil {
		return "", fmt.Errorf("parse secret json: %w", err)
	}
	if payload.DatabaseURL == "" {
		return "", fmt.Errorf("DATABASE_URL missing in secret")
	}
	return payload.DatabaseURL, nil
}

func execDelete(ctx context.Context, pool *pgxpool.Pool, sql string) (int64, error) {
	ct, err := pool.Exec(ctx, sql)
	if err != nil {
		return 0, err
	}
	return ct.RowsAffected(), nil
}

func putMetrics(ctx context.Context, cw *cloudwatch.Client, ns string, r result) error {
	now := time.Now()
	metrics := []cwtypes.MetricDatum{
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.AdminCodesExpired), Dimensions: dims("Table", "app_verification_codes_admin_email_expired")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.AdminCodesUsed), Dimensions: dims("Table", "app_verification_codes_admin_email_used")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.AdminRateLimits), Dimensions: dims("Table", "app_rate_limits_admin")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.UserCodesExpired), Dimensions: dims("Table", "app_verification_codes_user_email_expired")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.UserCodesUsed), Dimensions: dims("Table", "app_verification_codes_user_email_used")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.UserPhoneCodesExp), Dimensions: dims("Table", "app_verification_codes_user_phone_expired")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.UserPhoneCodesUsed), Dimensions: dims("Table", "app_verification_codes_user_phone_used")},
		{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.UserRateLimits), Dimensions: dims("Table", "app_rate_limits_user")},
	}
	// Add refresh-token specific metrics
	metrics = append(metrics,
		cwtypes.MetricDatum{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.RevokedRefreshTokens24h), Dimensions: dims("Table", "app_refresh_tokens_revoked_24h")},
		cwtypes.MetricDatum{MetricName: awsStr("RowsDeleted"), Timestamp: &now, Unit: cwtypes.StandardUnitCount, Value: awsFloat(r.ExpiredRefreshTokens7d), Dimensions: dims("Table", "app_refresh_tokens_expired_7d")},
	)
	_, err := cw.PutMetricData(ctx, &cloudwatch.PutMetricDataInput{
		Namespace:  &ns,
		MetricData: metrics,
	})
	return err
}

func handler(ctx context.Context) (string, error) {
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "eu-central-1"
	}
	secretArn := os.Getenv("SECRET_ARN")
	if secretArn == "" {
		return "", fmt.Errorf("SECRET_ARN env var is required")
	}
	ns := os.Getenv("METRIC_NAMESPACE")
	if ns == "" {
		ns = "MadeInWorld/AuthCleanup"
	}
	stmtTimeoutMs := int64(10000)
	if v := os.Getenv("STATEMENT_TIMEOUT_MS"); v != "" {
		if n, err := strconv.ParseInt(v, 10, 64); err == nil {
			stmtTimeoutMs = n
		}
	}

	// AWS SDK clients
	awsCfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return "", fmt.Errorf("aws config: %w", err)
	}
	sm := secretsmanager.NewFromConfig(awsCfg)
	cw := cloudwatch.NewFromConfig(awsCfg)

	// Retrieve DB URL
	dbURL, err := getSecret(ctx, sm, secretArn)
	if err != nil {
		return "", err
	}

	// Append session-level statement_timeout (optional, defense-in-depth)
	// Alternatively: run "SET LOCAL statement_timeout" per statement.
	cfg, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		return "", fmt.Errorf("parse db url: %w", err)
	}
	// keep pool tiny
	cfg.MaxConns = 1
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return "", fmt.Errorf("connect db: %w", err)
	}
	defer pool.Close()

	// Helper to run each statement with context timeout
	run := func(sql string, timeoutMs int64) (int64, error) {
		c, cancel := context.WithTimeout(ctx, time.Duration(timeoutMs)*time.Millisecond)
		defer cancel()
		return execDelete(c, pool, sql)
	}

	var res result
	// Used > 24h first (privacy/storage), then expired-older-than-1h
	// Admin
	res.AdminCodesUsed, err = run(`DELETE FROM app_verification_codes WHERE actor_type = 'admin' AND channel_type = 'email' AND used = true AND created_at < now() - interval '24 hours'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("admin used: %w", err)
	}
	res.AdminCodesExpired, err = run(`DELETE FROM app_verification_codes WHERE actor_type = 'admin' AND channel_type = 'email' AND expires_at < now() - interval '1 hour'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("admin expired: %w", err)
	}
	res.AdminRateLimits, err = run(`DELETE FROM app_rate_limits WHERE actor_type = 'admin' AND channel_type = 'email' AND window_start < now() - interval '24 hours'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("admin rate_limits: %w", err)
	}

	// User (email)
	res.UserCodesUsed, err = run(`DELETE FROM app_verification_codes WHERE actor_type = 'user' AND channel_type = 'email' AND used = true AND created_at < now() - interval '24 hours'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("user used: %w", err)
	}
	res.UserCodesExpired, err = run(`DELETE FROM app_verification_codes WHERE actor_type = 'user' AND channel_type = 'email' AND expires_at < now() - interval '1 hour'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("user expired: %w", err)
	}

	// User (phone)
	res.UserPhoneCodesUsed, err = run(`DELETE FROM app_verification_codes WHERE actor_type = 'user' AND channel_type = 'phone' AND used = true AND created_at < now() - interval '24 hours'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("user phone used: %w", err)
	}
	res.UserPhoneCodesExp, err = run(`DELETE FROM app_verification_codes WHERE actor_type = 'user' AND channel_type = 'phone' AND expires_at < now() - interval '1 hour'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("user phone expired: %w", err)
	}

	// User rate limits
	res.UserRateLimits, err = run(`DELETE FROM app_rate_limits WHERE actor_type = 'user' AND window_start < now() - interval '24 hours'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("user rate_limits: %w", err)
	}

	// Refresh tokens cleanup
	// 1) Revoke-based deletion with 24h audit window
	res.RevokedRefreshTokens24h, err = run(`DELETE FROM app_refresh_tokens WHERE revoked = true AND issued_at < now() - interval '24 hours'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("refresh tokens revoked>24h: %w", err)
	}
	// 2) Fully expired older-than-3-days (optional pruning for non-revoked old tokens)
	res.ExpiredRefreshTokens7d, err = run(`DELETE FROM app_refresh_tokens WHERE expires_at < now() - interval '3 days'`, stmtTimeoutMs)
	if err != nil {
		return "", fmt.Errorf("refresh tokens expired>3d: %w", err)
	}

	log.Printf("[CLEANUP] Deleted rows: admin_codes_used=%d admin_codes_expired=%d admin_rate_limits=%d user_codes_used=%d user_codes_expired=%d user_phone_used=%d user_phone_expired=%d user_rate_limits=%d refresh_tokens_revoked_24h=%d refresh_tokens_expired_7d=%d",
		res.AdminCodesUsed, res.AdminCodesExpired, res.AdminRateLimits,
		res.UserCodesUsed, res.UserCodesExpired, res.UserPhoneCodesUsed, res.UserPhoneCodesExp, res.UserRateLimits, res.RevokedRefreshTokens24h, res.ExpiredRefreshTokens7d)

	if err := putMetrics(ctx, cw, ns, res); err != nil {
		log.Printf("PutMetricData failed: %v", err)
	}

	return "ok", nil
}

func awsStr(s string) *string { return &s }
func awsFloat(i int64) *float64 {
	f := float64(i)
	return &f
}

func dims(k, v string) []cwtypes.Dimension {
	return []cwtypes.Dimension{{Name: &k, Value: &v}}
}

func main() { lambda.Start(handler) }
