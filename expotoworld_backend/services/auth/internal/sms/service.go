// Package sms provides SMS sending functionality using AWS SNS.
package sms

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sns/types"
)

// Config holds SMS service configuration.
type Config struct {
	SenderID string
	Region   string
}

// Service provides SMS sending functionality using AWS SNS.
type Service struct {
	client   *sns.Client
	senderID string
	logger   *slog.Logger
}

// NewService creates a new SMS service.
func NewService(client *sns.Client, cfg Config, logger *slog.Logger) *Service {
	return &Service{
		client:   client,
		senderID: cfg.SenderID,
		logger:   logger,
	}
}

// SendOTPSMS sends an OTP verification SMS.
func (s *Service) SendOTPSMS(ctx context.Context, phoneNumber, code string) error {
	message := fmt.Sprintf("Your EXPO to WORLD verification code is: %s\n\nThis code expires in 10 minutes.", code)

	input := &sns.PublishInput{
		Message:     aws.String(message),
		PhoneNumber: aws.String(phoneNumber),
		MessageAttributes: map[string]types.MessageAttributeValue{
			"AWS.SNS.SMS.SMSType": {
				DataType:    aws.String("String"),
				StringValue: aws.String("Transactional"),
			},
		},
	}

	// Add sender ID if configured
	if s.senderID != "" {
		input.MessageAttributes["AWS.SNS.SMS.SenderID"] = types.MessageAttributeValue{
			DataType:    aws.String("String"),
			StringValue: aws.String(s.senderID),
		}
	}

	_, err := s.client.Publish(ctx, input)
	if err != nil {
		s.logger.Error("failed to send SMS via SNS", "error", err, "phone", phoneNumber)
		return fmt.Errorf("failed to send SMS: %w", err)
	}

	s.logger.Info("SMS sent successfully", "phone", phoneNumber)
	return nil
}
