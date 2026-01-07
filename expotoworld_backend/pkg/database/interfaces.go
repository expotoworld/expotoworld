package database

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// Querier defines the interface for database query operations.
// Both Pool and Tx implement this interface.
type Querier interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// TxBeginner defines the interface for starting transactions.
type TxBeginner interface {
	Begin(ctx context.Context) (pgx.Tx, error)
}

// DB defines the full database interface.
type DB interface {
	Querier
	TxBeginner
	HealthCheck(ctx context.Context) error
	Close()
}

// Ensure Pool implements DB interface.
var _ DB = (*Pool)(nil)
