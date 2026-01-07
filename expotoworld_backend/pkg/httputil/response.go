// Package httputil provides HTTP utilities for standardized API responses,
// error handling, and common HTTP operations.
package httputil

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Response represents a standardized API response.
type Response struct {
	Success   bool        `json:"success"`
	Data      interface{} `json:"data,omitempty"`
	Error     *ErrorInfo  `json:"error,omitempty"`
	Meta      *Meta       `json:"meta,omitempty"`
	Timestamp string      `json:"timestamp"`
}

// ErrorInfo represents error details in a response.
type ErrorInfo struct {
	Code    string            `json:"code"`
	Message string            `json:"message"`
	Details map[string]string `json:"details,omitempty"`
}

// Meta represents pagination and other metadata.
type Meta struct {
	Page       int   `json:"page,omitempty"`
	PageSize   int   `json:"page_size,omitempty"`
	TotalCount int64 `json:"total_count,omitempty"`
	TotalPages int   `json:"total_pages,omitempty"`
}

// NewResponse creates a new response with timestamp.
func NewResponse() *Response {
	return &Response{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
}

// Success sends a successful response with data.
func Success(c *gin.Context, statusCode int, data interface{}) {
	resp := NewResponse()
	resp.Success = true
	resp.Data = data
	c.JSON(statusCode, resp)
}

// OK sends a 200 OK response with data.
func OK(c *gin.Context, data interface{}) {
	Success(c, http.StatusOK, data)
}

// Created sends a 201 Created response with data.
func Created(c *gin.Context, data interface{}) {
	Success(c, http.StatusCreated, data)
}

// NoContent sends a 204 No Content response.
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// Paginated sends a paginated response.
func Paginated(c *gin.Context, data interface{}, page, pageSize int, totalCount int64) {
	totalPages := int(totalCount) / pageSize
	if int(totalCount)%pageSize > 0 {
		totalPages++
	}

	resp := NewResponse()
	resp.Success = true
	resp.Data = data
	resp.Meta = &Meta{
		Page:       page,
		PageSize:   pageSize,
		TotalCount: totalCount,
		TotalPages: totalPages,
	}
	c.JSON(http.StatusOK, resp)
}

// Error sends an error response.
func Error(c *gin.Context, statusCode int, code string, message string) {
	resp := NewResponse()
	resp.Success = false
	resp.Error = &ErrorInfo{
		Code:    code,
		Message: message,
	}
	c.JSON(statusCode, resp)
}

// ErrorWithDetails sends an error response with additional details.
func ErrorWithDetails(c *gin.Context, statusCode int, code string, message string, details map[string]string) {
	resp := NewResponse()
	resp.Success = false
	resp.Error = &ErrorInfo{
		Code:    code,
		Message: message,
		Details: details,
	}
	c.JSON(statusCode, resp)
}

// BadRequest sends a 400 Bad Request response.
func BadRequest(c *gin.Context, message string) {
	Error(c, http.StatusBadRequest, "BAD_REQUEST", message)
}

// BadRequestWithDetails sends a 400 Bad Request response with details.
func BadRequestWithDetails(c *gin.Context, message string, details map[string]string) {
	ErrorWithDetails(c, http.StatusBadRequest, "BAD_REQUEST", message, details)
}

// Unauthorized sends a 401 Unauthorized response.
func Unauthorized(c *gin.Context, message string) {
	if message == "" {
		message = "Authentication required"
	}
	Error(c, http.StatusUnauthorized, "UNAUTHORIZED", message)
}

// Forbidden sends a 403 Forbidden response.
func Forbidden(c *gin.Context, message string) {
	if message == "" {
		message = "Access denied"
	}
	Error(c, http.StatusForbidden, "FORBIDDEN", message)
}

// NotFound sends a 404 Not Found response.
func NotFound(c *gin.Context, message string) {
	if message == "" {
		message = "Resource not found"
	}
	Error(c, http.StatusNotFound, "NOT_FOUND", message)
}

// Conflict sends a 409 Conflict response.
func Conflict(c *gin.Context, message string) {
	Error(c, http.StatusConflict, "CONFLICT", message)
}

// UnprocessableEntity sends a 422 Unprocessable Entity response.
func UnprocessableEntity(c *gin.Context, message string) {
	Error(c, http.StatusUnprocessableEntity, "UNPROCESSABLE_ENTITY", message)
}

// TooManyRequests sends a 429 Too Many Requests response.
func TooManyRequests(c *gin.Context, message string) {
	if message == "" {
		message = "Too many requests"
	}
	Error(c, http.StatusTooManyRequests, "TOO_MANY_REQUESTS", message)
}

// InternalServerError sends a 500 Internal Server Error response.
func InternalServerError(c *gin.Context, message string) {
	if message == "" {
		message = "An internal error occurred"
	}
	Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", message)
}

// ServiceUnavailable sends a 503 Service Unavailable response.
func ServiceUnavailable(c *gin.Context, message string) {
	if message == "" {
		message = "Service temporarily unavailable"
	}
	Error(c, http.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", message)
}

// ValidationError sends a 400 response with validation error details.
func ValidationError(c *gin.Context, errors map[string]string) {
	ErrorWithDetails(c, http.StatusBadRequest, "VALIDATION_ERROR", "Validation failed", errors)
}

// Common error codes
const (
	ErrCodeBadRequest         = "BAD_REQUEST"
	ErrCodeUnauthorized       = "UNAUTHORIZED"
	ErrCodeForbidden          = "FORBIDDEN"
	ErrCodeNotFound           = "NOT_FOUND"
	ErrCodeConflict           = "CONFLICT"
	ErrCodeValidation         = "VALIDATION_ERROR"
	ErrCodeTooManyRequests    = "TOO_MANY_REQUESTS"
	ErrCodeInternalError      = "INTERNAL_ERROR"
	ErrCodeServiceUnavailable = "SERVICE_UNAVAILABLE"
)

// AppError represents an application error with HTTP status code.
type AppError struct {
	StatusCode int
	Code       string
	Message    string
	Details    map[string]string
	Err        error
}

// Error implements the error interface.
func (e *AppError) Error() string {
	if e.Err != nil {
		return e.Err.Error()
	}
	return e.Message
}

// Unwrap returns the wrapped error.
func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError creates a new application error.
func NewAppError(statusCode int, code, message string) *AppError {
	return &AppError{
		StatusCode: statusCode,
		Code:       code,
		Message:    message,
	}
}

// WithDetails adds details to an AppError.
func (e *AppError) WithDetails(details map[string]string) *AppError {
	e.Details = details
	return e
}

// WithError wraps another error.
func (e *AppError) WithError(err error) *AppError {
	e.Err = err
	return e
}

// HandleAppError sends an appropriate response for an AppError.
func HandleAppError(c *gin.Context, err error) {
	if appErr, ok := err.(*AppError); ok {
		if appErr.Details != nil {
			ErrorWithDetails(c, appErr.StatusCode, appErr.Code, appErr.Message, appErr.Details)
		} else {
			Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
		}
		return
	}

	// Default to internal server error for unknown errors
	InternalServerError(c, "An unexpected error occurred")
}

// Common application errors
var (
	ErrNotFound     = NewAppError(http.StatusNotFound, ErrCodeNotFound, "Resource not found")
	ErrUnauthorized = NewAppError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication required")
	ErrForbidden    = NewAppError(http.StatusForbidden, ErrCodeForbidden, "Access denied")
	ErrInternal     = NewAppError(http.StatusInternalServerError, ErrCodeInternalError, "An internal error occurred")
)

// BindJSON binds JSON request body and handles errors.
func BindJSON(c *gin.Context, obj interface{}) bool {
	if err := c.ShouldBindJSON(obj); err != nil {
		BadRequest(c, "Invalid request body: "+err.Error())
		return false
	}
	return true
}

// BindQuery binds query parameters and handles errors.
func BindQuery(c *gin.Context, obj interface{}) bool {
	if err := c.ShouldBindQuery(obj); err != nil {
		BadRequest(c, "Invalid query parameters: "+err.Error())
		return false
	}
	return true
}

// BindURI binds URI parameters and handles errors.
func BindURI(c *gin.Context, obj interface{}) bool {
	if err := c.ShouldBindUri(obj); err != nil {
		BadRequest(c, "Invalid URI parameters: "+err.Error())
		return false
	}
	return true
}

// GetIDParam extracts an ID parameter from the URL.
func GetIDParam(c *gin.Context, name string) string {
	return c.Param(name)
}

// GetIntQuery gets an integer query parameter with a default value.
func GetIntQuery(c *gin.Context, key string, defaultValue int) int {
	if val, exists := c.GetQuery(key); exists {
		var result int
		if _, err := json.Number(val).Int64(); err == nil {
			if n, err := json.Number(val).Int64(); err == nil {
				result = int(n)
				if result > 0 {
					return result
				}
			}
		}
	}
	return defaultValue
}

// GetStringQuery gets a string query parameter with a default value.
func GetStringQuery(c *gin.Context, key string, defaultValue string) string {
	if val, exists := c.GetQuery(key); exists && val != "" {
		return val
	}
	return defaultValue
}

// GetBoolQuery gets a boolean query parameter with a default value.
func GetBoolQuery(c *gin.Context, key string, defaultValue bool) bool {
	if val, exists := c.GetQuery(key); exists {
		switch val {
		case "true", "1", "yes":
			return true
		case "false", "0", "no":
			return false
		}
	}
	return defaultValue
}

// NotFoundError creates a not found error for a specific resource.
func NotFoundError(resource, id string) *AppError {
	return NewAppError(http.StatusNotFound, ErrCodeNotFound, resource+" not found: "+id)
}

// ConflictError creates a conflict error for a resource.
func ConflictError(resource, field, value string) *AppError {
	return NewAppError(http.StatusConflict, ErrCodeConflict, resource+" with "+field+" '"+value+"' already exists")
}

// HandleError handles any error type and sends appropriate response.
func HandleError(c *gin.Context, err error) {
	if err == nil {
		return
	}

	// Check for AppError
	if appErr, ok := err.(*AppError); ok {
		HandleAppError(c, appErr)
		return
	}

	// Default to internal server error for unknown errors
	InternalServerError(c, "An unexpected error occurred")
}
