// Package postgres provides PostgreSQL implementations of repositories.
package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
)

// UserRepository is a PostgreSQL implementation of repository.UserRepository.
type UserRepository struct {
	pool *pgxpool.Pool
}

// NewUserRepository creates a new PostgreSQL user repository.
func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

// FindByID retrieves a user by their ID.
func (r *UserRepository) FindByID(ctx context.Context, id string) (*domain.User, error) {
	query := `
		SELECT id, username, email, phone, first_name, middle_name, last_name, 
		       role, status, last_login, created_at, updated_at
		FROM app_users
		WHERE id = $1`

	var user domain.User
	var role, status string
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Username, &user.Email, &user.Phone,
		&user.FirstName, &user.MiddleName, &user.LastName,
		&role, &status, &user.LastLogin, &user.CreatedAt, &user.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find user by ID: %w", err)
	}

	user.Role = domain.UserRole(role)
	user.Status = domain.UserStatus(status)
	return &user, nil
}

// FindByEmail retrieves a user by their email address.
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	query := `
		SELECT id, username, email, phone, first_name, middle_name, last_name, 
		       role, status, last_login, created_at, updated_at
		FROM app_users
		WHERE email = $1`

	var user domain.User
	var role, status string
	err := r.pool.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Username, &user.Email, &user.Phone,
		&user.FirstName, &user.MiddleName, &user.LastName,
		&role, &status, &user.LastLogin, &user.CreatedAt, &user.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find user by email: %w", err)
	}

	user.Role = domain.UserRole(role)
	user.Status = domain.UserStatus(status)
	return &user, nil
}

// FindByPhone retrieves a user by their phone number.
func (r *UserRepository) FindByPhone(ctx context.Context, phone string) (*domain.User, error) {
	query := `
		SELECT id, username, email, phone, first_name, middle_name, last_name, 
		       role, status, last_login, created_at, updated_at
		FROM app_users
		WHERE phone = $1`

	var user domain.User
	var role, status string
	err := r.pool.QueryRow(ctx, query, phone).Scan(
		&user.ID, &user.Username, &user.Email, &user.Phone,
		&user.FirstName, &user.MiddleName, &user.LastName,
		&role, &status, &user.LastLogin, &user.CreatedAt, &user.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find user by phone: %w", err)
	}

	user.Role = domain.UserRole(role)
	user.Status = domain.UserStatus(status)
	return &user, nil
}

// Create creates a new user and returns the created user with ID.
func (r *UserRepository) Create(ctx context.Context, user *domain.User) (*domain.User, error) {
	query := `
		INSERT INTO app_users (username, email, phone, first_name, middle_name, last_name, role, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		user.Username, user.Email, user.Phone,
		user.FirstName, user.MiddleName, user.LastName,
		string(user.Role), string(user.Status),
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

// Update updates an existing user.
func (r *UserRepository) Update(ctx context.Context, user *domain.User) error {
	query := `
		UPDATE app_users 
		SET username = $1, email = $2, phone = $3, first_name = $4, 
		    middle_name = $5, last_name = $6, role = $7, status = $8, 
		    updated_at = NOW()
		WHERE id = $9`

	_, err := r.pool.Exec(ctx, query,
		user.Username, user.Email, user.Phone,
		user.FirstName, user.MiddleName, user.LastName,
		string(user.Role), string(user.Status), user.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

// UpdateLastLogin updates the user's last login timestamp.
func (r *UserRepository) UpdateLastLogin(ctx context.Context, userID string) error {
	query := `UPDATE app_users SET last_login = NOW(), updated_at = NOW() WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, userID)
	if err != nil {
		return fmt.Errorf("failed to update last login: %w", err)
	}
	return nil
}

// GetOrgMemberships retrieves the organization memberships for a user.
func (r *UserRepository) GetOrgMemberships(ctx context.Context, userID string) ([]domain.OrgMembership, error) {
	query := `
		SELECT ou.org_id, o.org_type, ou.role, o.org_name
		FROM admin_organization_users ou
		JOIN admin_organizations o ON o.org_id = ou.org_id
		WHERE ou.user_id = $1`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get org memberships: %w", err)
	}
	defer rows.Close()

	var memberships []domain.OrgMembership
	for rows.Next() {
		var m domain.OrgMembership
		if err := rows.Scan(&m.OrgID, &m.OrgType, &m.OrgRole, &m.Name); err != nil {
			return nil, fmt.Errorf("failed to scan org membership: %w", err)
		}
		memberships = append(memberships, m)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating org memberships: %w", err)
	}

	return memberships, nil
}
