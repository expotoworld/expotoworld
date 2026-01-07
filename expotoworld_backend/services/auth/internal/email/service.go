package email

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/ses/types"
)

// Config holds email service configuration.
type Config struct {
	FromEmail string
	FromName  string
	Region    string
}

// Service provides email sending functionality using AWS SES.
type Service struct {
	client    *ses.Client
	fromEmail string
	fromName  string
	logger    *slog.Logger
}

// NewService creates a new email service.
func NewService(client *ses.Client, cfg Config, logger *slog.Logger) *Service {
	return &Service{
		client:    client,
		fromEmail: cfg.FromEmail,
		fromName:  cfg.FromName,
		logger:    logger,
	}
}

// SendOTPEmail sends an OTP verification email.
func (s *Service) SendOTPEmail(ctx context.Context, toEmail, code string) error {
	subject := "Your EXPO to WORLD Verification Code is:"
	htmlBody := s.buildOTPEmailHTML(code)
	textBody := fmt.Sprintf("Your verification code is: %s\n\nThis code expires in 10 minutes.", code)

	return s.sendEmail(ctx, toEmail, subject, htmlBody, textBody)
}

// sendEmail sends an email using AWS SES.
func (s *Service) sendEmail(ctx context.Context, toEmail, subject, htmlBody, textBody string) error {
	fromAddress := fmt.Sprintf("%s <%s>", s.fromName, s.fromEmail)

	input := &ses.SendEmailInput{
		Destination: &types.Destination{
			ToAddresses: []string{toEmail},
		},
		Message: &types.Message{
			Body: &types.Body{
				Html: &types.Content{
					Charset: aws.String("UTF-8"),
					Data:    aws.String(htmlBody),
				},
				Text: &types.Content{
					Charset: aws.String("UTF-8"),
					Data:    aws.String(textBody),
				},
			},
			Subject: &types.Content{
				Charset: aws.String("UTF-8"),
				Data:    aws.String(subject),
			},
		},
		Source: aws.String(fromAddress),
	}

	_, err := s.client.SendEmail(ctx, input)
	if err != nil {
		s.logger.Error("failed to send email via SES", "error", err, "to", toEmail)
		return fmt.Errorf("failed to send email: %w", err)
	}

	s.logger.Info("email sent successfully", "to", toEmail, "subject", subject)
	return nil
}

// buildOTPEmailHTML builds the HTML content for OTP emails.
func (s *Service) buildOTPEmailHTML(code string) string {
	return fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verification Code</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
    <table role="presentation" style="width: 100%%; border-collapse: collapse;">
        <tr>
            <td align="center" style="padding: 40px 0;">
                <table role="presentation" style="width: 100%%; max-width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <tr>
                        <td style="padding: 40px 40px 20px 40px; text-align: center;">
                            <h1 style="margin: 0; font-size: 24px; color: #333333;">EXPO to WORLD</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 20px 40px;">
                            <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #333333; text-align: center;">Verification Code</h2>
                            <p style="margin: 0 0 30px 0; font-size: 16px; line-height: 24px; color: #666666; text-align: center;">
                                Use the following code to verify your identity:
                            </p>
                            <div style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; text-align: center; margin-bottom: 30px;">
                                <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #333333;">%s</span>
                            </div>
                            <p style="margin: 0 0 10px 0; font-size: 14px; color: #999999; text-align: center;">
                                This code expires in <strong>10 minutes</strong>.
                            </p>
                            <p style="margin: 0; font-size: 14px; color: #999999; text-align: center;">
                                If you didn't request this code, you can safely ignore this email.
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 20px 40px 40px 40px; text-align: center; border-top: 1px solid #eeeeee;">
                            <p style="margin: 0; font-size: 12px; color: #999999;">
                                © 2026 EXPO to WORLD. All rights reserved.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>`, code)
}
