/**
 * EXPO to WORLD Admin Panel - Type Definitions
 *
 * NOTE: Catalog-related types (Product, Category, Subcategory, Store, Region)
 * are defined in @/services/catalogApi.ts — the single source of truth for all
 * catalog types that match the backend API contract. Do NOT re-define them here.
 */

// ============================================
// ORDER TYPES
// ============================================

export type OrderStatus = 
  | 'pending'
  | 'confirmed'
  | 'processing'
  | 'ready_for_pickup'
  | 'shipped'
  | 'delivered'
  | 'completed'
  | 'cancelled'
  | 'refunded'
  | 'disputed';

export interface OrderItem {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface Order {
  id: string;
  userId: string;
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  items: OrderItem[];
  subtotal: number;
  deliveryFee: number;
  total: number;
  status: OrderStatus;
  shippingAddress?: string;
  paymentMethod: string;
  storeId: string;
  storeName: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

// ============================================
// USER TYPES
// ============================================

export type UserRole = 'admin' | 'customer' | 'manufacturer' | 'logistics' | 'partner';
export type UserStatus = 'active' | 'suspended' | 'pending';

export interface User {
  id: string;
  username: string;
  realName?: string;
  email: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  profileImageUrl?: string;
  totalOrders: number;
  totalSpent: number;
  walletBalance: number;
  organizationId?: string;
  createdAt: string;
  lastLoginAt?: string;
}

// ============================================
// ORGANIZATION TYPES
// ============================================

export type OrganizationType = 'manufacturer' | 'logistics' | 'partner' | 'supplier';

export interface Organization {
  id: string;
  name: string;
  type: OrganizationType;
  contactPerson: string;
  contactEmail: string;
  contactPhone?: string;
  address?: string;
  description?: string;
  logoUrl?: string;
  productCount: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// ============================================
// CART TYPES
// ============================================

export interface CartItem {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface Cart {
  id: string;
  userId: string;
  customerName: string;
  items: CartItem[];
  totalItems: number;
  totalPrice: number;
  storeId: string;
  storeName: string;
  createdAt: string;
  updatedAt: string;
}

// ============================================
// CONTENT TYPES
// ============================================

export interface Banner {
  id: string;
  title: string;
  subtitle?: string;
  imageUrl: string;
  linkUrl?: string;
  position: number;
  isActive: boolean;
  startDate?: string;
  endDate?: string;
  createdAt: string;
  updatedAt: string;
}

export interface FeaturedProduct {
  id: string;
  productId: string;
  productName: string;
  productImage: string;
  productPrice: number;
  displayOrder: number;
  scope: 'global' | 'store' | 'category';
  storeId?: string;
  storeName?: string;
  categoryId?: string;
  categoryName?: string;
  isActive: boolean;
  startDate?: string;
  endDate?: string;
  createdAt: string;
  updatedAt: string;
}

// ============================================
// DASHBOARD / ANALYTICS TYPES
// ============================================

export interface DashboardStats {
  totalRevenue: number;
  totalOrders: number;
  totalUsers: number;
  totalProducts: number;
  pendingOrders: number;
  lowStockProducts: number;
  revenueChange: number; // Percentage change from previous period
  ordersChange: number;
  usersChange: number;
}

export interface ChartDataPoint {
  date: string;
  value: number;
  label?: string;
}

export interface TopProduct {
  id: string;
  name: string;
  sales: number;
  revenue: number;
  imageUrl?: string;
}

export interface RecentOrder {
  id: string;
  customerName: string;
  total: number;
  status: OrderStatus;
  createdAt: string;
}

// ============================================
// API RESPONSE TYPES
// ============================================

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface ApiError {
  message: string;
  code?: string;
  details?: Record<string, string>;
}
