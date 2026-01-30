package domain

import "errors"

// Domain errors for the ebook service.
var (
	ErrEbookNotFound         = errors.New("ebook not found")
	ErrVersionNotFound       = errors.New("version not found")
	ErrInvalidMediaType      = errors.New("invalid media type")
	ErrS3NotConfigured       = errors.New("s3 not configured")
	ErrCannotDeletePublished = errors.New("cannot delete published version")
	ErrUnauthorized          = errors.New("unauthorized")
)
