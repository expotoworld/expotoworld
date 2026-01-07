package domain

import (
	"time"
)

// UserRole represents the role of a user in the system.
type UserRole string

const (
	RoleCustomer UserRole = "Customer"
	RoleAdmin    UserRole = "Admin"
)

// UserStatus represents the status of a user account.
type UserStatus string

const (
	StatusActive   UserStatus = "active"
	StatusInactive UserStatus = "inactive"
	StatusBanned   UserStatus = "banned"
)

// User represents a user entity in the system.
type User struct {
	ID         string
	Username   string
	Email      *string
	Phone      *string
	FirstName  *string
	MiddleName *string
	LastName   *string
	Role       UserRole
	Status     UserStatus
	LastLogin  *time.Time
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

// OrgMembership represents a user's membership in an organization.
type OrgMembership struct {
	OrgID   string
	OrgType string // brand, manufacturer, tpl
	OrgRole string // Owner, Staff
	Name    string // Organization name
}

// IsActive returns true if the user account is active.
func (u *User) IsActive() bool {
	return u.Status == StatusActive
}

// IsAdmin returns true if the user has admin role.
func (u *User) IsAdmin() bool {
	return u.Role == RoleAdmin
}

// FullName returns the user's full name.
func (u *User) FullName() string {
	var parts []string
	if u.FirstName != nil && *u.FirstName != "" {
		parts = append(parts, *u.FirstName)
	}
	if u.MiddleName != nil && *u.MiddleName != "" {
		parts = append(parts, *u.MiddleName)
	}
	if u.LastName != nil && *u.LastName != "" {
		parts = append(parts, *u.LastName)
	}
	if len(parts) == 0 {
		return u.Username
	}
	result := ""
	for i, p := range parts {
		if i > 0 {
			result += " "
		}
		result += p
	}
	return result
}
