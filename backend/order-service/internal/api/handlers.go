package api

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/expotoworld/expotoworld/backend/order-service/internal/db"
	"github.com/expotoworld/expotoworld/backend/order-service/internal/models"
	"github.com/gin-gonic/gin"
)

// Handler holds the database connection and provides HTTP handlers
type Handler struct {
	db *db.Database
}

// NewHandler creates a new handler instance
func NewHandler(database *db.Database) *Handler {
	return &Handler{
		db: database,
	}
}

// Health checks the health of the service
func (h *Handler) Health(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check database health
	if err := h.db.Health(ctx); err != nil {
		c.JSON(http.StatusServiceUnavailable, models.ErrorResponse{
			Error:   "Database connection failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"service":   "order-service",
		"timestamp": time.Now().UTC(),
	})
}

// GetCart retrieves the user's cart for a specific mini-app
func (h *Handler) GetCart(c *gin.Context) {
	// Validate mini-app type
	miniAppType, ok := ValidateMiniAppType(c)
	if !ok {
		return
	}

	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get cart items for user and mini-app
	items, err := h.getCartItems(ctx, userID, miniAppType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to get cart items",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Cart retrieved successfully",
		Data: models.CartResponse{
			Items: items,
		},
	})
}

// AddToCart adds a product to the user's cart
func (h *Handler) AddToCart(c *gin.Context) {
	// Validate mini-app type
	miniAppType, ok := ValidateMiniAppType(c)
	if !ok {
		return
	}

	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	// Parse request body
	var req models.AddToCartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
		})
		return
	}

	// Validate store requirement for location-based mini-apps
	if miniAppType.RequiresStore() && req.StoreID == nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Store ID required",
			Message: "This mini-app requires a store selection",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Verify product exists and has stock
	product, err := h.getProduct(ctx, req.ProductID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Product not found",
			Message: err.Error(),
		})
		return
	}

	// Check if product is active
	if !product.IsActive {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Product unavailable",
			Message: "This product is currently not available",
		})
		return
	}

	// Check stock availability only for UnmannedStore mini-app
	// All other mini-apps have infinite stock
	if miniAppType == models.MiniAppTypeUnmannedStore && !product.HasStock() {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Insufficient stock",
			Message: "This product is currently out of stock",
		})
		return
	}

	// Get existing quantity in cart to validate final total against MOQ
	var existingQuantity int
	checkQuery := `
		SELECT COALESCE(quantity, 0) FROM app_carts
		WHERE user_id = $1 AND mini_app_type = $2 AND product_id = $3
	`
	err = h.db.Pool.QueryRow(ctx, checkQuery, userID, string(miniAppType), req.ProductID).Scan(&existingQuantity)
	if err != nil {
		// If no existing item, current quantity is 0
		existingQuantity = 0
	}

	// Calculate final quantity after addition
	finalQuantity := existingQuantity + req.Quantity

	// Check minimum order quantity against final total quantity
	if finalQuantity < product.MinimumOrderQuantity {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Minimum order quantity not met",
			Message: "Minimum order quantity for this product is " + strconv.Itoa(product.MinimumOrderQuantity),
		})
		return
	}

	// Check if requested quantity exceeds available stock (only for UnmannedStore)
	if miniAppType == models.MiniAppTypeUnmannedStore && req.Quantity > product.DisplayStock() {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Insufficient stock",
			Message: "Only " + strconv.Itoa(product.DisplayStock()) + " items available",
		})
		return
	}

	// Validate stock considering existing cart contents (only for UnmannedStore)
	if miniAppType == models.MiniAppTypeUnmannedStore {
		err = h.validateStockForCartAddition(ctx, userID, miniAppType, req.ProductID, req.Quantity)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Stock validation failed",
				Message: err.Error(),
			})
			return
		}
	}

	// Add item to cart
	err = h.addItemToCart(ctx, userID, miniAppType, req.ProductID, req.Quantity, req.StoreID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to add item to cart",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Item added to cart successfully",
	})
}

// UpdateCartItem updates the quantity of an item in the cart
func (h *Handler) UpdateCartItem(c *gin.Context) {
	// Validate mini-app type
	miniAppType, ok := ValidateMiniAppType(c)
	if !ok {
		return
	}

	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	// Parse request body
	var req models.UpdateCartItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// If quantity is 0, remove the item
	if req.Quantity == 0 {
		err := h.removeItemFromCart(ctx, userID, miniAppType, req.ProductID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error:   "Failed to remove item from cart",
				Message: err.Error(),
			})
			return
		}
		c.JSON(http.StatusOK, models.SuccessResponse{
			Message: "Item removed from cart successfully",
		})
		return
	}

	// Verify product exists and has stock
	product, err := h.getProduct(ctx, req.ProductID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Product not found",
			Message: err.Error(),
		})
		return
	}

	// Check stock availability (only for UnmannedStore)
	if miniAppType == models.MiniAppTypeUnmannedStore && req.Quantity > product.DisplayStock() {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Insufficient stock",
			Message: "Only " + strconv.Itoa(product.DisplayStock()) + " items available",
		})
		return
	}

	// Update cart item quantity
	err = h.updateCartItemQuantity(ctx, userID, miniAppType, req.ProductID, req.Quantity)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to update cart item",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Cart item updated successfully",
	})
}

// RemoveFromCart removes an item from the cart
func (h *Handler) RemoveFromCart(c *gin.Context) {
	// Validate mini-app type
	miniAppType, ok := ValidateMiniAppType(c)
	if !ok {
		return
	}

	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	// Get product ID from URL parameter
	productID := c.Param("product_id")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Remove item from cart
	err := h.removeItemFromCart(ctx, userID, miniAppType, productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to remove item from cart",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Item removed from cart successfully",
	})
}

// CreateOrder creates an order from the user's cart
func (h *Handler) CreateOrder(c *gin.Context) {
	// Validate mini-app type
	miniAppType, ok := ValidateMiniAppType(c)
	if !ok {
		return
	}

	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	// Parse request body
	var req models.CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
		})
		return
	}

	// Validate store requirement for location-based mini-apps
	if miniAppType.RequiresStore() && req.StoreID == nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Store ID required",
			Message: "This mini-app requires a store selection",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Get cart items (filtered by store for location-based mini-apps)
	cartItems, err := h.getCartItemsWithStore(ctx, userID, miniAppType, req.StoreID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to get cart items",
			Message: err.Error(),
		})
		return
	}

	// Check if cart is empty
	if len(cartItems) == 0 {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Empty cart",
			Message: "Cannot create order from empty cart",
		})
		return
	}

	// Validate stock for all cart items before order creation (only for UnmannedStore)
	if miniAppType == models.MiniAppTypeUnmannedStore {
		err = h.validateCartStockBeforeOrder(ctx, cartItems)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Stock validation failed",
				Message: err.Error(),
			})
			return
		}
	}

	// Calculate total amount
	var totalAmount float64
	for _, item := range cartItems {
		totalAmount += float64(item.Quantity) * item.Product.MainPrice
	}

	// Create order (we'll implement this method)
	order, err := h.createOrder(ctx, userID, miniAppType, req.StoreID, totalAmount, cartItems)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create order",
			Message: err.Error(),
		})
		return
	}

	// Clear cart after successful order creation (only items from submitted store for location-based mini-apps)
	err = h.clearCartWithStore(ctx, userID, miniAppType, req.StoreID)
	if err != nil {
		// Log error but don't fail the order creation
		// The order was created successfully, cart clearing is secondary
		fmt.Printf("Warning: Failed to clear cart after order creation: %v\n", err)
	}

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Message: "Order created successfully",
		Data:    order,
	})
}

// GetOrders retrieves the user's orders for a specific mini-app
func (h *Handler) GetOrders(c *gin.Context) {
	// Validate mini-app type
	miniAppType, ok := ValidateMiniAppType(c)
	if !ok {
		return
	}

	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get user's orders for the mini-app
	orders, err := h.getUserOrders(ctx, userID, miniAppType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to get orders",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Orders retrieved successfully",
		Data:    orders,
	})
}

// GetOrder retrieves a specific order by ID
func (h *Handler) GetOrder(c *gin.Context) {
	// Get user ID from JWT
	userID, ok := GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "Invalid user",
			Message: "Could not extract user ID from token",
		})
		return
	}

	// Get order ID from URL parameter
	orderID := c.Param("order_id")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get order details
	order, err := h.getOrderByID(ctx, orderID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Order not found",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Order retrieved successfully",
		Data:    order,
	})
}
