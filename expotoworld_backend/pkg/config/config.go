// Package config provides centralized configuration management for all services.
// It supports loading configuration from environment variables, .env files,
// and AWS Secrets Manager for production deployments.
package config

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/go-playground/validator/v10"
	"github.com/spf13/viper"
)

// Config holds all configuration for the application.
// Configuration is loaded from environment variables and optionally from AWS Secrets Manager.
type Config struct {
	App       AppConfig       `mapstructure:",squash"`
	Server    ServerConfig    `mapstructure:",squash"`
	Database  DatabaseConfig  `mapstructure:",squash"`
	JWT       JWTConfig       `mapstructure:",squash"`
	AWS       AWSConfig       `mapstructure:",squash"`
	CORS      CORSConfig      `mapstructure:",squash"`
	RateLimit RateLimitConfig `mapstructure:",squash"`
	Telemetry TelemetryConfig `mapstructure:",squash"`
	Log       LogConfig       `mapstructure:",squash"`
}

// AppConfig contains application-level settings.
type AppConfig struct {
	Env     string `mapstructure:"APP_ENV" validate:"required,oneof=development staging production"`
	Version string `mapstructure:"APP_VERSION"`
	Debug   bool   `mapstructure:"APP_DEBUG"`
}

// ServerConfig contains HTTP server settings.
type ServerConfig struct {
	Port         int           `mapstructure:"SERVER_PORT" validate:"required,min=1,max=65535"`
	AuthPort     int           `mapstructure:"AUTH_SERVICE_PORT" validate:"required,min=1,max=65535"`
	CatalogPort  int           `mapstructure:"CATALOG_SERVICE_PORT" validate:"required,min=1,max=65535"`
	EbookPort    int           `mapstructure:"EBOOK_SERVICE_PORT" validate:"required,min=1,max=65535"`
	OrderPort    int           `mapstructure:"ORDER_SERVICE_PORT" validate:"required,min=1,max=65535"`
	UserPort     int           `mapstructure:"USER_SERVICE_PORT" validate:"required,min=1,max=65535"`
	ReadTimeout  time.Duration `mapstructure:"SERVER_READ_TIMEOUT"`
	WriteTimeout time.Duration `mapstructure:"SERVER_WRITE_TIMEOUT"`
	IdleTimeout  time.Duration `mapstructure:"SERVER_IDLE_TIMEOUT"`
}

// DatabaseConfig contains PostgreSQL connection settings.
type DatabaseConfig struct {
	URL             string        `mapstructure:"DATABASE_URL" validate:"required_without=AWSSecretPath"`
	AWSSecretPath   string        `mapstructure:"AWS_SECRET_DATABASE"`
	MaxConns        int32         `mapstructure:"DATABASE_MAX_CONNS" validate:"min=1,max=100"`
	MinConns        int32         `mapstructure:"DATABASE_MIN_CONNS" validate:"min=0"`
	MaxConnLifetime time.Duration `mapstructure:"DATABASE_MAX_CONN_LIFETIME"`
	MaxConnIdleTime time.Duration `mapstructure:"DATABASE_MAX_CONN_IDLE_TIME"`
}

// JWTConfig contains JWT authentication settings.
type JWTConfig struct {
	Issuer             string        `mapstructure:"JWT_ISSUER"`
	Audience           string        `mapstructure:"JWT_AUDIENCE"`
	JWKSURL            string        `mapstructure:"JWKS_URL" validate:"omitempty,url"`
	PrivateKeyPEM      string        `mapstructure:"JWT_PRIVATE_KEY_PEM"`
	PublicKeyPEM       string        `mapstructure:"JWT_PUBLIC_KEY_PEM"`
	AWSSecretPrivate   string        `mapstructure:"AWS_SECRET_JWT_PRIVATE"`
	AWSSecretPublic    string        `mapstructure:"AWS_SECRET_JWT_PUBLIC"`
	AccessTokenExpiry  time.Duration `mapstructure:"JWT_ACCESS_TOKEN_EXPIRY"`
	RefreshTokenExpiry time.Duration `mapstructure:"JWT_REFRESH_TOKEN_EXPIRY"`
}

// AWSConfig contains AWS service settings.
type AWSConfig struct {
	Region           string `mapstructure:"AWS_REGION" validate:"required"`
	AccountID        string `mapstructure:"AWS_ACCOUNT_ID"`
	S3BucketProducts string `mapstructure:"AWS_S3_BUCKET_PRODUCTS"`
	S3BucketEbooks   string `mapstructure:"AWS_S3_BUCKET_EBOOKS"`
	S3BucketProfiles string `mapstructure:"AWS_S3_BUCKET_PROFILES"`
	CloudFrontDistID string `mapstructure:"CLOUDFRONT_DISTRIBUTION_ID"`
	CloudFrontDomain string `mapstructure:"CLOUDFRONT_DOMAIN"`
	SESSenderEmail   string `mapstructure:"SES_SENDER_EMAIL" validate:"omitempty,email"`
	SESSenderName    string `mapstructure:"SES_SENDER_NAME"`
	SNSSenderID      string `mapstructure:"SNS_SENDER_ID"`
}

// CORSConfig contains CORS middleware settings.
type CORSConfig struct {
	AllowedOrigins   []string `mapstructure:"CORS_ALLOWED_ORIGINS"`
	AllowedMethods   []string `mapstructure:"CORS_ALLOWED_METHODS"`
	AllowedHeaders   []string `mapstructure:"CORS_ALLOWED_HEADERS"`
	AllowCredentials bool     `mapstructure:"CORS_ALLOW_CREDENTIALS"`
	MaxAge           int      `mapstructure:"CORS_MAX_AGE"`
}

// RateLimitConfig contains rate limiting settings.
type RateLimitConfig struct {
	Requests int           `mapstructure:"RATE_LIMIT_REQUESTS" validate:"min=1"`
	Window   time.Duration `mapstructure:"RATE_LIMIT_WINDOW"`
}

// TelemetryConfig contains OpenTelemetry settings.
type TelemetryConfig struct {
	Enabled          bool   `mapstructure:"OTEL_ENABLED"`
	ExporterEndpoint string `mapstructure:"OTEL_EXPORTER_ENDPOINT"`
	ServiceName      string `mapstructure:"OTEL_SERVICE_NAME"`
}

// LogConfig contains logging settings.
type LogConfig struct {
	Level  string `mapstructure:"LOG_LEVEL" validate:"required,oneof=debug info warn error"`
	Format string `mapstructure:"LOG_FORMAT" validate:"required,oneof=text json"`
}

// singleton instance
var (
	cfg     *Config
	cfgOnce sync.Once
	cfgErr  error
)

// Load loads configuration from environment variables and .env files.
// It returns a singleton Config instance.
func Load() (*Config, error) {
	cfgOnce.Do(func() {
		cfg, cfgErr = load()
	})
	return cfg, cfgErr
}

// MustLoad loads configuration and panics on error.
func MustLoad() *Config {
	c, err := Load()
	if err != nil {
		panic(fmt.Sprintf("failed to load config: %v", err))
	}
	return c
}

// load performs the actual configuration loading.
func load() (*Config, error) {
	v := viper.New()

	// Set defaults
	setDefaults(v)

	// Automatically bind all environment variables
	v.AutomaticEnv()
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))

	// Try to load .env file (optional in production)
	v.SetConfigName(".env")
	v.SetConfigType("env")
	v.AddConfigPath(".")
	v.AddConfigPath("./expotoworld_backend")
	v.AddConfigPath("/app")

	if err := v.ReadInConfig(); err != nil {
		// .env file is optional; ignore "not found" errors
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	// Unmarshal into struct
	var config Config
	if err := v.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Parse CORS allowed origins from comma-separated string
	if corsOrigins := v.GetString("CORS_ALLOWED_ORIGINS"); corsOrigins != "" {
		config.CORS.AllowedOrigins = strings.Split(corsOrigins, ",")
		for i := range config.CORS.AllowedOrigins {
			config.CORS.AllowedOrigins[i] = strings.TrimSpace(config.CORS.AllowedOrigins[i])
		}
	}

	// Parse CORS allowed methods
	if corsMethods := v.GetString("CORS_ALLOWED_METHODS"); corsMethods != "" {
		config.CORS.AllowedMethods = strings.Split(corsMethods, ",")
	} else {
		config.CORS.AllowedMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	}

	// Parse CORS allowed headers
	if corsHeaders := v.GetString("CORS_ALLOWED_HEADERS"); corsHeaders != "" {
		config.CORS.AllowedHeaders = strings.Split(corsHeaders, ",")
	} else {
		config.CORS.AllowedHeaders = []string{"Accept", "Authorization", "Content-Type", "X-Correlation-ID"}
	}

	// Load secrets from AWS Secrets Manager in production
	if config.App.Env == "production" || config.App.Env == "staging" {
		if err := loadAWSSecrets(&config); err != nil {
			return nil, fmt.Errorf("failed to load AWS secrets: %w", err)
		}
	}

	// Validate configuration
	validate := validator.New()
	if err := validate.Struct(config); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	return &config, nil
}

// setDefaults configures default values for configuration.
func setDefaults(v *viper.Viper) {
	// App
	v.SetDefault("APP_ENV", "development")
	v.SetDefault("APP_VERSION", "1.0.0")
	v.SetDefault("APP_DEBUG", true)

	// Server
	v.SetDefault("SERVER_PORT", 8080)
	v.SetDefault("AUTH_SERVICE_PORT", 8081)
	v.SetDefault("CATALOG_SERVICE_PORT", 8080)
	v.SetDefault("EBOOK_SERVICE_PORT", 8084)
	v.SetDefault("ORDER_SERVICE_PORT", 8082)
	v.SetDefault("USER_SERVICE_PORT", 8083)
	v.SetDefault("SERVER_READ_TIMEOUT", "15s")
	v.SetDefault("SERVER_WRITE_TIMEOUT", "15s")
	v.SetDefault("SERVER_IDLE_TIMEOUT", "60s")

	// Database
	v.SetDefault("DATABASE_MAX_CONNS", 10)
	v.SetDefault("DATABASE_MIN_CONNS", 2)
	v.SetDefault("DATABASE_MAX_CONN_LIFETIME", "30m")
	v.SetDefault("DATABASE_MAX_CONN_IDLE_TIME", "5m")

	// JWT
	v.SetDefault("JWT_ACCESS_TOKEN_EXPIRY", "15m")
	v.SetDefault("JWT_REFRESH_TOKEN_EXPIRY", "168h")
	v.SetDefault("JWKS_URL", "http://localhost:8081/.well-known/jwks.json")

	// AWS
	v.SetDefault("AWS_REGION", "eu-central-1")
	v.SetDefault("AWS_SECRET_DATABASE", "expotoworld/neon/db")
	v.SetDefault("AWS_SECRET_JWT_PRIVATE", "expotoworld/jwt/rs256/private_pem")
	v.SetDefault("AWS_SECRET_JWT_PUBLIC", "expotoworld/jwt/rs256/public_pem")

	// CORS
	v.SetDefault("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173")
	v.SetDefault("CORS_ALLOW_CREDENTIALS", true)
	v.SetDefault("CORS_MAX_AGE", 86400)

	// Rate limiting
	v.SetDefault("RATE_LIMIT_REQUESTS", 100)
	v.SetDefault("RATE_LIMIT_WINDOW", "1m")

	// Telemetry
	v.SetDefault("OTEL_ENABLED", false)
	v.SetDefault("OTEL_SERVICE_NAME", "expotoworld-backend")

	// Logging
	v.SetDefault("LOG_LEVEL", "debug")
	v.SetDefault("LOG_FORMAT", "text")
}

// loadAWSSecrets loads sensitive configuration from AWS Secrets Manager.
func loadAWSSecrets(config *Config) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Load AWS configuration
	awsCfg, err := awsconfig.LoadDefaultConfig(ctx,
		awsconfig.WithRegion(config.AWS.Region),
	)
	if err != nil {
		return fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := secretsmanager.NewFromConfig(awsCfg)

	// Load database URL
	if config.Database.AWSSecretPath != "" && config.Database.URL == "" {
		secret, err := getSecret(ctx, client, config.Database.AWSSecretPath)
		if err != nil {
			return fmt.Errorf("failed to load database secret: %w", err)
		}

		// Secret can be either a plain string or JSON with "url" field
		var dbSecret struct {
			URL string `json:"url"`
		}
		if err := json.Unmarshal([]byte(secret), &dbSecret); err == nil && dbSecret.URL != "" {
			config.Database.URL = dbSecret.URL
		} else {
			config.Database.URL = secret
		}
	}

	// Load JWT private key
	if config.JWT.AWSSecretPrivate != "" && config.JWT.PrivateKeyPEM == "" {
		secret, err := getSecret(ctx, client, config.JWT.AWSSecretPrivate)
		if err != nil {
			return fmt.Errorf("failed to load JWT private key: %w", err)
		}
		config.JWT.PrivateKeyPEM = secret
	}

	// Load JWT public key
	if config.JWT.AWSSecretPublic != "" && config.JWT.PublicKeyPEM == "" {
		secret, err := getSecret(ctx, client, config.JWT.AWSSecretPublic)
		if err != nil {
			return fmt.Errorf("failed to load JWT public key: %w", err)
		}
		config.JWT.PublicKeyPEM = secret
	}

	return nil
}

// getSecret retrieves a secret value from AWS Secrets Manager.
func getSecret(ctx context.Context, client *secretsmanager.Client, secretName string) (string, error) {
	output, err := client.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	})
	if err != nil {
		return "", err
	}

	if output.SecretString != nil {
		return *output.SecretString, nil
	}

	return "", fmt.Errorf("secret %s has no string value", secretName)
}

// IsDevelopment returns true if running in development mode.
func (c *Config) IsDevelopment() bool {
	return c.App.Env == "development"
}

// IsProduction returns true if running in production mode.
func (c *Config) IsProduction() bool {
	return c.App.Env == "production"
}

// GetServicePort returns the port for a specific service.
func (c *Config) GetServicePort(service string) int {
	switch service {
	case "auth":
		return c.Server.AuthPort
	case "catalog":
		return c.Server.CatalogPort
	case "ebook":
		return c.Server.EbookPort
	case "order":
		return c.Server.OrderPort
	case "user":
		return c.Server.UserPort
	default:
		return c.Server.Port
	}
}

// GetDatabaseURL returns the database connection URL.
func (c *Config) GetDatabaseURL() string {
	return c.Database.URL
}

// GetEnvOrDefault returns an environment variable or a default value.
func GetEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
