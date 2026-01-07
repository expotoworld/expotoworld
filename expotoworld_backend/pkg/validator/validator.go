// Package validator provides input validation utilities using go-playground/validator.
package validator

import (
	"reflect"
	"regexp"
	"strings"
	"sync"
	"unicode"

	"github.com/go-playground/validator/v10"
)

var (
	instance *Validator
	once     sync.Once
)

// Validator wraps go-playground/validator with custom rules.
type Validator struct {
	v *validator.Validate
}

// Get returns the singleton validator instance.
func Get() *Validator {
	once.Do(func() {
		instance = New()
	})
	return instance
}

// New creates a new validator instance with custom rules.
func New() *Validator {
	v := validator.New()

	// Register custom tag name func
	v.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
		if name == "-" {
			return ""
		}
		return name
	})

	// Register custom validations
	_ = v.RegisterValidation("slug", validateSlug)
	_ = v.RegisterValidation("username", validateUsername)
	_ = v.RegisterValidation("phone", validatePhone)
	_ = v.RegisterValidation("country_code", validateCountryCode)
	_ = v.RegisterValidation("currency", validateCurrency)
	_ = v.RegisterValidation("price", validatePrice)
	_ = v.RegisterValidation("uuid", validateUUID)
	_ = v.RegisterValidation("safe_text", validateSafeText)
	_ = v.RegisterValidation("no_html", validateNoHTML)

	return &Validator{v: v}
}

// Validate validates a struct and returns a map of field errors.
func (val *Validator) Validate(s interface{}) map[string]string {
	err := val.v.Struct(s)
	if err == nil {
		return nil
	}

	errors := make(map[string]string)
	for _, e := range err.(validator.ValidationErrors) {
		errors[e.Field()] = getErrorMessage(e)
	}
	return errors
}

// ValidateStruct validates a struct and returns an error string if validation fails.
func (val *Validator) ValidateStruct(s interface{}) error {
	errs := val.Validate(s)
	if errs == nil {
		return nil
	}

	// Build error message from validation errors
	var messages []string
	for field, msg := range errs {
		messages = append(messages, field+": "+msg)
	}
	return &ValidationError{Errors: errs, Message: strings.Join(messages, "; ")}
}

// ValidationError represents a validation error with field-level details.
type ValidationError struct {
	Errors  map[string]string
	Message string
}

func (e *ValidationError) Error() string {
	return e.Message
}

// ValidateField validates a single field.
func (val *Validator) ValidateField(field interface{}, tag string) error {
	return val.v.Var(field, tag)
}

// getErrorMessage returns a human-readable error message.
func getErrorMessage(e validator.FieldError) string {
	switch e.Tag() {
	case "required":
		return "This field is required"
	case "email":
		return "Must be a valid email address"
	case "min":
		if e.Type().Kind() == reflect.String {
			return "Must be at least " + e.Param() + " characters"
		}
		return "Must be at least " + e.Param()
	case "max":
		if e.Type().Kind() == reflect.String {
			return "Must be at most " + e.Param() + " characters"
		}
		return "Must be at most " + e.Param()
	case "len":
		return "Must be exactly " + e.Param() + " characters"
	case "gte":
		return "Must be greater than or equal to " + e.Param()
	case "lte":
		return "Must be less than or equal to " + e.Param()
	case "gt":
		return "Must be greater than " + e.Param()
	case "lt":
		return "Must be less than " + e.Param()
	case "oneof":
		return "Must be one of: " + e.Param()
	case "url":
		return "Must be a valid URL"
	case "uuid":
		return "Must be a valid UUID"
	case "slug":
		return "Must be a valid slug (lowercase letters, numbers, and hyphens)"
	case "username":
		return "Must be a valid username (3-30 characters, alphanumeric and underscores)"
	case "phone":
		return "Must be a valid phone number"
	case "country_code":
		return "Must be a valid 2-letter country code"
	case "currency":
		return "Must be a valid 3-letter currency code"
	case "price":
		return "Must be a valid price (non-negative)"
	case "safe_text":
		return "Contains invalid characters"
	case "no_html":
		return "HTML tags are not allowed"
	case "eqfield":
		return "Must match " + e.Param()
	case "nefield":
		return "Must be different from " + e.Param()
	case "alphanum":
		return "Must contain only alphanumeric characters"
	case "alpha":
		return "Must contain only letters"
	case "numeric":
		return "Must be a number"
	case "boolean":
		return "Must be true or false"
	case "datetime":
		return "Must be a valid date/time"
	default:
		return "Invalid value"
	}
}

// Custom validation functions

var slugRegex = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)

func validateSlug(fl validator.FieldLevel) bool {
	return slugRegex.MatchString(fl.Field().String())
}

var usernameRegex = regexp.MustCompile(`^[a-zA-Z][a-zA-Z0-9_]{2,29}$`)

func validateUsername(fl validator.FieldLevel) bool {
	return usernameRegex.MatchString(fl.Field().String())
}

var phoneRegex = regexp.MustCompile(`^\+?[1-9]\d{1,14}$`)

func validatePhone(fl validator.FieldLevel) bool {
	phone := fl.Field().String()
	if phone == "" {
		return true // Optional by default, use required tag if mandatory
	}
	return phoneRegex.MatchString(phone)
}

var countryCodeRegex = regexp.MustCompile(`^[A-Z]{2}$`)

func validateCountryCode(fl validator.FieldLevel) bool {
	return countryCodeRegex.MatchString(fl.Field().String())
}

var currencyRegex = regexp.MustCompile(`^[A-Z]{3}$`)

func validateCurrency(fl validator.FieldLevel) bool {
	return currencyRegex.MatchString(fl.Field().String())
}

func validatePrice(fl validator.FieldLevel) bool {
	switch fl.Field().Kind() {
	case reflect.Int, reflect.Int64:
		return fl.Field().Int() >= 0
	case reflect.Float32, reflect.Float64:
		return fl.Field().Float() >= 0
	default:
		return false
	}
}

var uuidRegex = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

func validateUUID(fl validator.FieldLevel) bool {
	return uuidRegex.MatchString(strings.ToLower(fl.Field().String()))
}

func validateSafeText(fl validator.FieldLevel) bool {
	text := fl.Field().String()
	for _, r := range text {
		if !unicode.IsPrint(r) && !unicode.IsSpace(r) {
			return false
		}
	}
	return true
}

var htmlTagRegex = regexp.MustCompile(`<[^>]*>`)

func validateNoHTML(fl validator.FieldLevel) bool {
	return !htmlTagRegex.MatchString(fl.Field().String())
}

// Utility functions

// SanitizeSlug converts a string to a valid slug.
func SanitizeSlug(s string) string {
	s = strings.ToLower(s)
	s = strings.TrimSpace(s)

	// Replace spaces and underscores with hyphens
	s = strings.ReplaceAll(s, " ", "-")
	s = strings.ReplaceAll(s, "_", "-")

	// Remove any character that is not alphanumeric or hyphen
	result := strings.Builder{}
	for _, r := range s {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
			result.WriteRune(r)
		}
	}

	// Remove consecutive hyphens
	s = result.String()
	for strings.Contains(s, "--") {
		s = strings.ReplaceAll(s, "--", "-")
	}

	// Trim leading and trailing hyphens
	s = strings.Trim(s, "-")

	return s
}

// SanitizeString removes leading/trailing whitespace and normalizes internal whitespace.
func SanitizeString(s string) string {
	s = strings.TrimSpace(s)
	space := regexp.MustCompile(`\s+`)
	return space.ReplaceAllString(s, " ")
}

// TruncateString truncates a string to a maximum length.
func TruncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen]
}

// IsEmpty checks if a string is empty or contains only whitespace.
func IsEmpty(s string) bool {
	return strings.TrimSpace(s) == ""
}

// CoalesceString returns the first non-empty string.
func CoalesceString(strings ...string) string {
	for _, s := range strings {
		if !IsEmpty(s) {
			return s
		}
	}
	return ""
}
