// Package storage provides S3 storage interfaces and implementations.
package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// S3Client defines the interface for S3 operations.
type S3Client interface {
	// GetObject retrieves an object from the default bucket.
	GetObject(ctx context.Context, key string) ([]byte, error)

	// PutObject stores an object in the default bucket.
	PutObject(ctx context.Context, key string, data []byte, contentType string) error

	// DeleteObject removes an object from the default bucket.
	DeleteObject(ctx context.Context, key string) error

	// ListObjects lists objects with the given prefix from the default bucket.
	ListObjects(ctx context.Context, prefix string) ([]string, error)

	// GetObjectFromBucket retrieves an object from a specific bucket.
	GetObjectFromBucket(ctx context.Context, bucket, key string) ([]byte, error)

	// PutObjectToBucket stores an object in a specific bucket.
	PutObjectToBucket(ctx context.Context, bucket, key string, data []byte, contentType string) error

	// DeleteObjectFromBucket removes an object from a specific bucket.
	DeleteObjectFromBucket(ctx context.Context, bucket, key string) error

	// GeneratePresignedURL generates a presigned URL for uploading.
	GeneratePresignedURL(ctx context.Context, bucket, key, contentType string, expirySeconds int64) (string, error)
}

// s3Client implements S3Client using AWS SDK v2.
type s3Client struct {
	client        *s3.Client
	presignClient *s3.PresignClient
	defaultBucket string
}

// NewS3Client creates a new S3 client.
func NewS3Client(client *s3.Client, defaultBucket string) S3Client {
	return &s3Client{
		client:        client,
		presignClient: s3.NewPresignClient(client),
		defaultBucket: defaultBucket,
	}
}

// GetObject retrieves an object from the default bucket.
func (c *s3Client) GetObject(ctx context.Context, key string) ([]byte, error) {
	return c.GetObjectFromBucket(ctx, c.defaultBucket, key)
}

// PutObject stores an object in the default bucket.
func (c *s3Client) PutObject(ctx context.Context, key string, data []byte, contentType string) error {
	return c.PutObjectToBucket(ctx, c.defaultBucket, key, data, contentType)
}

// DeleteObject removes an object from the default bucket.
func (c *s3Client) DeleteObject(ctx context.Context, key string) error {
	return c.DeleteObjectFromBucket(ctx, c.defaultBucket, key)
}

// ListObjects lists objects with the given prefix from the default bucket.
func (c *s3Client) ListObjects(ctx context.Context, prefix string) ([]string, error) {
	var keys []string
	paginator := s3.NewListObjectsV2Paginator(c.client, &s3.ListObjectsV2Input{
		Bucket: aws.String(c.defaultBucket),
		Prefix: aws.String(prefix),
	})

	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			return nil, fmt.Errorf("list objects with prefix %s: %w", prefix, err)
		}
		for _, obj := range page.Contents {
			keys = append(keys, *obj.Key)
		}
	}

	return keys, nil
}

// GetObjectFromBucket retrieves an object from a specific bucket.
func (c *s3Client) GetObjectFromBucket(ctx context.Context, bucket, key string) ([]byte, error) {
	output, err := c.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, fmt.Errorf("get object %s/%s: %w", bucket, key, err)
	}
	defer output.Body.Close()

	data, err := io.ReadAll(output.Body)
	if err != nil {
		return nil, fmt.Errorf("read object body: %w", err)
	}

	return data, nil
}

// PutObjectToBucket stores an object in a specific bucket.
func (c *s3Client) PutObjectToBucket(ctx context.Context, bucket, key string, data []byte, contentType string) error {
	_, err := c.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(data),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return fmt.Errorf("put object %s/%s: %w", bucket, key, err)
	}
	return nil
}

// DeleteObjectFromBucket removes an object from a specific bucket.
func (c *s3Client) DeleteObjectFromBucket(ctx context.Context, bucket, key string) error {
	_, err := c.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("delete object %s/%s: %w", bucket, key, err)
	}
	return nil
}

// GeneratePresignedURL generates a presigned URL for uploading.
func (c *s3Client) GeneratePresignedURL(ctx context.Context, bucket, key, contentType string, expirySeconds int64) (string, error) {
	presignedReq, err := c.presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(key),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("presign put object: %w", err)
	}
	return presignedReq.URL, nil
}
