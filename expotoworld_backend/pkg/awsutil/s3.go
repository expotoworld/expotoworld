// Package awsutil provides utilities for working with AWS services.
package awsutil

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	s3Types "github.com/aws/aws-sdk-go-v2/service/s3/types"
)

// S3Client wraps the AWS S3 client with utility functions.
type S3Client struct {
	client        *s3.Client
	presignClient *s3.PresignClient
	bucket        string
}

// NewS3Client creates a new S3 client wrapper.
func NewS3Client(cfg aws.Config, bucket string) *S3Client {
	client := s3.NewFromConfig(cfg)
	return &S3Client{
		client:        client,
		presignClient: s3.NewPresignClient(client),
		bucket:        bucket,
	}
}

// GeneratePresignedUploadURL generates a presigned URL for uploading a file to S3.
// The URL is valid for the specified duration and includes required metadata.
func (s *S3Client) GeneratePresignedUploadURL(ctx context.Context, key string, contentType string, expiresIn time.Duration) (string, error) {
	if key == "" {
		return "", fmt.Errorf("s3 key is required")
	}

	input := &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		ContentType: aws.String(contentType),
	}

	presignedReq, err := s.presignClient.PresignPutObject(ctx, input, func(opts *s3.PresignOptions) {
		opts.Expires = expiresIn
	})
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned upload URL: %w", err)
	}

	return presignedReq.URL, nil
}

// GeneratePresignedDownloadURL generates a presigned URL for downloading a file from S3.
func (s *S3Client) GeneratePresignedDownloadURL(ctx context.Context, key string, expiresIn time.Duration) (string, error) {
	if key == "" {
		return "", fmt.Errorf("s3 key is required")
	}

	input := &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}

	presignedReq, err := s.presignClient.PresignGetObject(ctx, input, func(opts *s3.PresignOptions) {
		opts.Expires = expiresIn
	})
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned download URL: %w", err)
	}

	return presignedReq.URL, nil
}

// DeleteObject deletes an object from S3.
func (s *S3Client) DeleteObject(ctx context.Context, key string) error {
	if key == "" {
		return fmt.Errorf("s3 key is required")
	}

	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("failed to delete object %s: %w", key, err)
	}

	return nil
}

// DeleteObjects deletes multiple objects from S3.
func (s *S3Client) DeleteObjects(ctx context.Context, keys []string) error {
	if len(keys) == 0 {
		return nil
	}

	objects := make([]s3Types.ObjectIdentifier, len(keys))
	for i, key := range keys {
		objects[i] = s3Types.ObjectIdentifier{
			Key: aws.String(key),
		}
	}

	_, err := s.client.DeleteObjects(ctx, &s3.DeleteObjectsInput{
		Bucket: aws.String(s.bucket),
		Delete: &s3Types.Delete{
			Objects: objects,
			Quiet:   aws.Bool(true),
		},
	})
	if err != nil {
		return fmt.Errorf("failed to delete objects: %w", err)
	}

	return nil
}

// GetPublicURL returns the public URL for an object (if bucket has public access).
func (s *S3Client) GetPublicURL(key string) string {
	return fmt.Sprintf("https://%s.s3.amazonaws.com/%s", s.bucket, key)
}

// GetBucket returns the bucket name.
func (s *S3Client) GetBucket() string {
	return s.bucket
}

// ObjectExists checks if an object exists in S3.
func (s *S3Client) ObjectExists(ctx context.Context, key string) (bool, error) {
	_, err := s.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		// Check if it's a "not found" error
		var nfe *s3Types.NotFound
		if errors.As(err, &nfe) {
			return false, nil
		}
		return false, fmt.Errorf("failed to check object existence: %w", err)
	}
	return true, nil
}
