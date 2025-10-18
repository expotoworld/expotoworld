package services

import (
	"context"
	"log"
	"time"

	"github.com/expotoworld/expotoworld/backend/auth-service/internal/db"
)

// CleanupService handles periodic cleanup of expired data
type CleanupService struct {
	db       *db.Database
	interval time.Duration
	stopChan chan bool
}

// NewCleanupService creates a new cleanup service
func NewCleanupService(database *db.Database, intervalMinutes int) *CleanupService {
	return &CleanupService{
		db:       database,
		interval: time.Duration(intervalMinutes) * time.Minute,
		stopChan: make(chan bool),
	}
}

// Start begins the periodic cleanup process
func (c *CleanupService) Start() {
	log.Printf("Starting cleanup service with %v interval", c.interval)

	// Run cleanup immediately on start
	c.runCleanup()

	// Set up periodic cleanup
	ticker := time.NewTicker(c.interval)

	go func() {
		for {
			select {
			case <-ticker.C:
				c.runCleanup()
			case <-c.stopChan:
				ticker.Stop()
				log.Println("Cleanup service stopped")
				return
			}
		}
	}()
}

// Stop stops the cleanup service
func (c *CleanupService) Stop() {
	c.stopChan <- true
}

// runCleanup performs the actual cleanup operations
func (c *CleanupService) runCleanup() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	log.Println("Running periodic cleanup...")

	// Cleanup admin verification codes
	if err := c.db.CleanupExpiredCodes(ctx); err != nil {
		log.Printf("Error during admin cleanup: %v", err)
	} else {
		log.Println("Admin cleanup completed successfully")
	}

	// Cleanup user verification codes
	if err := c.db.CleanupExpiredUserCodes(ctx); err != nil {
		log.Printf("Error during user cleanup: %v", err)
	} else {
		log.Println("User cleanup completed successfully")
	}
}
