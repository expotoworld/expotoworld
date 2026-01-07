// Package awsutil provides utilities for working with AWS services.
package awsutil

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

// GetSecret retrieves a secret value from AWS Secrets Manager.
func GetSecret(ctx context.Context, cfg aws.Config, secretARN string) (string, error) {
	if secretARN == "" {
		return "", fmt.Errorf("secret ARN is empty")
	}

	client := secretsmanager.NewFromConfig(cfg)

	result, err := client.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: &secretARN,
	})
	if err != nil {
		return "", fmt.Errorf("failed to get secret %s: %w", secretARN, err)
	}

	if result.SecretString == nil {
		return "", fmt.Errorf("secret %s has no string value", secretARN)
	}

	return *result.SecretString, nil
}
