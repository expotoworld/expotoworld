import axios from 'axios';
import type {
  User,
  UserListResponse,
  Product,
  Store,
  Category,
  Subcategory,
  Region,
  Organization,
  OrderSummary,
  CartSummary,
  CartDetails,
  ProductImage,
  ProductSourcingMapping,
  ProductLogisticsMapping,
  StorePartner,
  SortDirection,
  OrderDetails,
  UserAnalytics,
  OrderStatistics,
} from '../types/domain';

// Determine if we're in local development mode
// Vite exposes environment variables via `import.meta.env`
// NOTE: You must define VITE_API_BASE_URL in your environment for non-local setups
const envApiBase = import.meta.env.VITE_API_BASE_URL || 'https://device-api.expotoworld.com';
const isLocalDev = envApiBase === 'local';

// Local development: direct connection to backend services
// Production: via Cloudflare Worker gateway
let AUTH_BASE: string;
let ADMIN_BASE: string;
let CATALOG_BASE: string;
let MANUFACTURER_BASE: string;
let USER_BASE: string;

if (isLocalDev) {
  // Local development - connect directly to backend services
  AUTH_BASE = 'http://localhost:8081/api/auth';
  ADMIN_BASE = 'http://localhost:8082/api/admin';  // Order service handles admin routes
  CATALOG_BASE = 'http://localhost:8080/api/v1';   // Catalog service
  MANUFACTURER_BASE = 'http://localhost:8082/api/admin/manufacturer';  // Order service
  USER_BASE = 'http://localhost:8083/api/admin';   // User service handles user management
} else {
  // Production - via Cloudflare Worker
  const API_BASE = envApiBase;
  AUTH_BASE = `${API_BASE}/api/auth`;
  ADMIN_BASE = `${API_BASE}/api/admin`;
  CATALOG_BASE = `${API_BASE}/api/v1`;
  MANUFACTURER_BASE = `${API_BASE}/api/admin/manufacturer`;
  USER_BASE = `${API_BASE}/api/admin`;  // Cloudflare Worker routes to user service
}

export { AUTH_BASE, ADMIN_BASE, CATALOG_BASE, MANUFACTURER_BASE, USER_BASE };

// Token storage helpers
const TOKEN_KEY = 'admin_token';
const REFRESH_KEY = 'admin_refresh_token';

function getAccessToken(): string | null {
  const raw = localStorage.getItem(TOKEN_KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as { token?: string | null };
    return parsed.token ?? null;
  } catch {
    return null;
  }
}
function setAccessToken(token: string, expiresAt: string | number | null): void {
  localStorage.setItem(TOKEN_KEY, JSON.stringify({ token, expiresAt }));
}
function getRefreshToken(): string | null {
  const raw = localStorage.getItem(REFRESH_KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as { refresh_token?: string | null };
    return parsed.refresh_token ?? null;
  } catch {
    return null;
  }
}
function setRefreshToken(refresh_token: string, refresh_expires_at: string | number | null): void {
  localStorage.setItem(REFRESH_KEY, JSON.stringify({ refresh_token, refresh_expires_at }));
}

interface PendingRequest {
  resolve: (value: string) => void;
  reject: (reason?: unknown) => void;
}

let isRefreshing = false;
let pendingRequests: PendingRequest[] = [];

async function performRefresh() {
  if (isRefreshing) {
    return new Promise((resolve, reject) => pendingRequests.push({ resolve, reject }));
  }
  isRefreshing = true;
  try {
    const rt = getRefreshToken();
    if (!rt) throw new Error('No refresh token');
    const resp = await axios.post(`${AUTH_BASE}/token/refresh`, { refresh_token: rt, rotate: false });
    const newToken = resp.data?.token;
    const newTokenExp = resp.data?.expires_at;
    const newRefresh = resp.data?.refresh_token;
    const newRefreshExp = resp.data?.refresh_expires_at;
    if (!newToken) throw new Error('Invalid refresh response');
    setAccessToken(newToken, newTokenExp);
    if (newRefresh && newRefreshExp) setRefreshToken(newRefresh, newRefreshExp);
    axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`;
    pendingRequests.forEach(p => p.resolve(newToken));
    pendingRequests = [];
    return newToken;
  } catch (e) {
    pendingRequests.forEach(p => p.reject(e));
    pendingRequests = [];
    // Clear storage on refresh failure
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_KEY);
    localStorage.removeItem('admin_user');
    throw e;
  } finally {
    isRefreshing = false;
  }
}

// Create axios instance with base configuration (Catalog API v1)
const api = axios.create({
  baseURL: CATALOG_BASE,
  timeout: 10000, // 10 seconds timeout
  headers: { 'Content-Type': 'application/json' },
});

// Attach token on requests (both api instance and global axios)
function attachRequestInterceptor(instance: typeof axios | typeof api): void {
  instance.interceptors.request.use(
    (config) => {
      const url = typeof config.url === 'string' ? config.url : '';
      const isRefresh = url.includes('/token/refresh');
      if (!isRefresh) {
        const tok = getAccessToken();
        if (tok) config.headers.Authorization = `Bearer ${tok}`;
      }
      return config;
    },
    (error) => Promise.reject(error)
  );
}
attachRequestInterceptor(api);
attachRequestInterceptor(axios);

// 401 handler with silent refresh (once) then retry
function attachResponseInterceptor(instance: typeof axios | typeof api): void {
  instance.interceptors.response.use(
    (response) => response,
    async (error) => {
      const originalRequest = error.config || {};
      const url = typeof originalRequest.url === 'string' ? originalRequest.url : '';
      const isRefresh = url.includes('/token/refresh');
      if (!isRefresh && error.response?.status === 401 && !originalRequest?._retry) {
        originalRequest._retry = true;
        try {
          const newTok = await performRefresh();
          originalRequest.headers = originalRequest.headers || {};
          originalRequest.headers['Authorization'] = `Bearer ${newTok}`;
          return instance(originalRequest);
        } catch (e) {
          // If refresh fails, redirect to the login route (BrowserRouter)
          if (window.location.pathname !== '/login') {
            window.location.href = '/login';
          }
          return Promise.reject(error);
        }
      }
      return Promise.reject(error);
    }
  );
}
attachResponseInterceptor(api);
attachResponseInterceptor(axios);

// Helper function to get auth headers
const getAuthHeaders = (): Record<string, string> => {
  const savedToken = localStorage.getItem('admin_token');
  if (savedToken) {
    try {
      const tokenData = JSON.parse(savedToken) as { token?: string };
      if (tokenData.token) {
        return {
          Authorization: `Bearer ${tokenData.token}`,
        };
      }
    } catch (error) {
      console.error('Error parsing stored token:', error);
    }
  }
  return {};
};

// Response interceptor for handling auth errors (final fallback)
// Do NOT clear tokens on the first 401; let the refresh interceptor above handle retry.
// Only clear if a retry already happened or no refresh token is present.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const original = error.config || {}
    const hasTried = !!original._retry
    const hasRefresh = !!localStorage.getItem('admin_refresh_token')
    if (error.response?.status === 401 && (hasTried || !hasRefresh)) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      // Final fallback: redirect to the login route when unauthorized (BrowserRouter)
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    console.error('Response error:', error);

    // Handle common error scenarios
    if (error.response) {
      // Server responded with error status
      const { status, data } = error.response;
      console.error(`API Error ${status}:`, data);

      switch (status) {
        case 400:
          throw new Error(data.error || 'Bad request');
        case 404:
          throw new Error('Resource not found');
        case 409:
          throw new Error(data.error || 'Conflict - resource already exists');
        case 500:
          throw new Error('Internal server error');
        default:
          throw new Error(data.error || `Server error: ${status}`);
      }
    } else if (error.request) {
      // Network error
      console.error('Network error:', error.request);
      throw new Error('Network error - please check your connection');
    } else {
      // Other error
      console.error('Error:', error.message);
      throw new Error(error.message);
    }
  }
);

// User service methods
export const userService = {
  // Get all users with pagination and filtering
  getUsers: async (params: Record<string, unknown> = {}): Promise<UserListResponse> => {
    const response = await axios.get<UserListResponse>(`${USER_BASE}/users`, {
      params,
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Get single user by ID
  getUser: async (userId: number): Promise<User> => {
    const response = await axios.get<User>(`${USER_BASE}/users/${userId}`, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Create new user
  createUser: async (userData: Partial<User>): Promise<User> => {
    const response = await axios.post<User>(`${USER_BASE}/users`, userData, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Update user
  updateUser: async (userId: number, userData: Partial<User>): Promise<User> => {
    const response = await axios.put<User>(`${USER_BASE}/users/${userId}`, userData, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Delete user
  deleteUser: async (userId: number): Promise<void> => {
    await axios.delete(`${USER_BASE}/users/${userId}`, {
      headers: getAuthHeaders(),
    });
  },

  // Update user status
  updateUserStatus: async (
    userId: number,
    statusData: { status: string } | { is_active: boolean },
  ): Promise<User> => {
    const response = await axios.post<User>(`${USER_BASE}/users/${userId}/status`, statusData, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Get user analytics
  getUserAnalytics: async (): Promise<UserAnalytics> => {
    const response = await axios.get<UserAnalytics>(`${USER_BASE}/users/analytics`, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Bulk update users
  bulkUpdateUsers: async (
    bulkData: { user_ids: number[]; updates: Partial<User> },
  ): Promise<Record<string, unknown>> => {
    const response = await axios.post<Record<string, unknown>>(
      `${USER_BASE}/users/bulk-update`,
      bulkData,
      {
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },
};

// API service methods
export const productService = {
  // Get all products
  getProducts: async (params: Record<string, unknown> = {}): Promise<Product[]> => {
    const response = await api.get<Product[]>('/products', {
      params,
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Get manufacturer-scoped products (authenticated non-admins)
  getManufacturerProducts: async (
    params: Record<string, unknown> = {},
  ): Promise<Product[]> => {
    const response = await api.get<Product[]>(
      '/manufacturer/products',
      { params, headers: getAuthHeaders() },
    );
    return response.data;
  },

  // Get single product by ID
  getProduct: async (id: number): Promise<Product> => {
    const response = await api.get<Product>(`/products/${id}`, { headers: getAuthHeaders() });
    return response.data;
  },

  // Create new product
  createProduct: async (productData: Partial<Product>): Promise<Product> => {
    const response = await api.post<Product>('/products', productData, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Update existing product
  updateProduct: async (productId: number, productData: Partial<Product>): Promise<Product> => {
    const response = await api.put<Product>(`/products/${productId}`, productData, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Validate shelf code uniqueness per store (real-time)
  validateShelfCode: async ({
    store_id,
    shelf_code,
    product_id = null,
  }: {
    store_id: number;
    shelf_code: string;
    product_id?: number | null;
  }): Promise<{ valid: boolean }> => {
    const params: Record<string, unknown> = { store_id, shelf_code };
    if (product_id) params.product_id = product_id;
    const response = await api.get<{ valid: boolean }>('/products/validate-shelf-code', { params });
    return response.data; // expected shape: { valid: boolean }
  },

  // Delete product (soft delete by default)
  deleteProduct: async (productId: number, hardDelete = false): Promise<void> => {
    const params = hardDelete ? { hard: 'true' } : {};
    await api.delete(`/products/${productId}`, { params, headers: getAuthHeaders() });
  },

  // Upload product image
  uploadProductImage: async (productId: number, imageFile: File): Promise<ProductImage> => {
    const formData = new FormData();
    formData.append('productImage', imageFile);

    const response = await api.post<ProductImage>(`/products/${productId}/image`, formData, {
      headers: {
        ...getAuthHeaders(),
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },
};

export const categoryService = {
  // Get all categories
  getCategories: async (params: Record<string, unknown> = {}): Promise<{ categories: Category[] }> => {
    const response = await api.get<{ categories: Category[] }>('/categories', { params });
    return response.data;
  },

  // Get categories by mini-app type and store (for dynamic filtering)
  getCategoriesByMiniApp: async (
    miniAppType: string,
    storeId: number | null = null,
  ): Promise<{ categories: Category[] }> => {
    const params: Record<string, unknown> = {
      mini_app_type: miniAppType,
      include_subcategories: true,
    };
    if (storeId) {
      params.store_id = storeId;
    }
    const response = await api.get<{ categories: Category[] }>('/categories', { params });
    return response.data;
  },

  // Get subcategories for a specific category
  getSubcategories: async (categoryId: number): Promise<{ subcategories: Subcategory[] }> => {
    const response = await api.get<{ subcategories: Subcategory[] }>(`/categories/${categoryId}/subcategories`);
    return response.data;
  },

  // Get single category by ID
  getCategory: async (id: number): Promise<Category> => {
    const response = await api.get<Category>(`/categories/${id}`);
    return response.data;
  },

  // Create new category
  createCategory: async (categoryData: Partial<Category>): Promise<Category> => {
    const response = await api.post<Category>('/categories', categoryData);
    return response.data;
  },
};

export const storeService = {
  // Get all stores (public read)
  getStores: async (params: Record<string, unknown> = {}): Promise<Store[]> => {
    const response = await api.get<Store[]>('/stores', { params });
    return response.data;
  },

  // Get stores by mini-app type (public read)
  getStoresByMiniApp: async (miniAppType: string): Promise<Store[]> => {
    const params = { mini_app_type: miniAppType };
    const response = await api.get<Store[]>('/stores', { params });
    return response.data;
  },

  // Get stores by specific store type (public read)
  getStoresByType: async (storeType: string): Promise<Store[]> => {
    const params = { type: storeType };
    const response = await api.get<Store[]>('/stores', { params });
    return response.data;
  },

  // Admin writes
  createStore: async (payload: Partial<Store>): Promise<Store> => {
    const response = await api.post<Store>('/stores', payload, { headers: getAuthHeaders() });
    return response.data;
  },
  updateStore: async (id: number, payload: Partial<Store>): Promise<Store> => {
    const response = await api.put<Store>(`/stores/${id}`, payload, { headers: getAuthHeaders() });
    return response.data;
  },
  deleteStore: async (id: number): Promise<void> => {
    await api.delete(`/stores/${id}`, { headers: getAuthHeaders() });
  },
  uploadStoreImage: async (id: number, file: File): Promise<ProductImage> => {
    const formData = new FormData();
    formData.append('image', file);
    const response = await api.post<ProductImage>(`/stores/${id}/image`, formData, {
      headers: { ...getAuthHeaders(), 'Content-Type': 'multipart/form-data' },
    });
    return response.data;
  },
};

export const healthService = {
  // Check service health
  checkHealth: async (): Promise<Record<string, unknown>> => {
    const response = await api.get<Record<string, unknown>>('/health');
    return response.data;
  },
};

// Order service methods
export const orderService = {
  // Get all orders with pagination and filtering
  getOrders: async (
    params: Record<string, unknown> = {},
  ): Promise<{ orders: OrderSummary[]; total: number }> => {
    const response = await axios.get<{ orders: OrderSummary[]; total: number }>(
      `${ADMIN_BASE}/orders`,
      {
        params,
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },

  // Get single order by ID
  getOrder: async (orderId: string): Promise<OrderDetails> => {
    const response = await axios.get<OrderDetails>(`${ADMIN_BASE}/orders/${orderId}`, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Update order status
  updateOrderStatus: async (
    orderId: string,
    status: string,
    reason = '',
  ): Promise<OrderSummary> => {
    const response = await axios.put<OrderSummary>(
      `${ADMIN_BASE}/orders/${orderId}/status`,
      {
        status,
        reason,
      },
      {
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },

  // Delete/cancel order
  deleteOrder: async (orderId: string): Promise<void> => {
    await axios.delete(`${ADMIN_BASE}/orders/${orderId}`, {
      headers: getAuthHeaders(),
    });
  },

  // Bulk update orders
  bulkUpdateOrders: async (
    orderIds: string[],
    status: string,
    reason = '',
  ): Promise<Record<string, unknown>> => {
    const response = await axios.post<Record<string, unknown>>(
      `${ADMIN_BASE}/orders/bulk-update`,
      {
        order_ids: orderIds,
        status,
        reason,
      },
      {
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },

  // Get order statistics
  getStatistics: async (
    dateFrom = '',
    dateTo = '',
  ): Promise<OrderStatistics> => {
    const params: Record<string, string> = {};
    if (dateFrom) params.date_from = dateFrom;
    if (dateTo) params.date_to = dateTo;

    const response = await axios.get<OrderStatistics>(
      `${ADMIN_BASE}/orders/statistics`,
      {
        params,
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },
};

// Cart service methods
export const cartService = {
  // Get all carts with pagination and filtering
  getCarts: async (
    params: Record<string, unknown> = {},
  ): Promise<{ carts: CartSummary[]; total: number }> => {
    const response = await axios.get<{ carts: CartSummary[]; total: number }>(
      `${ADMIN_BASE}/carts`,
      {
        params,
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },

  // Get single cart by ID (detailed view)
  getCart: async (cartId: string): Promise<CartDetails> => {
    const response = await axios.get<CartDetails>(`${ADMIN_BASE}/carts/${cartId}`, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Update cart item quantity
  updateCartItem: async (
    cartId: string,
    productId: string,
    quantity: number,
  ): Promise<void> => {
    await axios.put(
      `${ADMIN_BASE}/carts/${cartId}/items`,
      {
        product_id: productId,
        quantity,
      },
      {
        headers: getAuthHeaders(),
      },
    );
  },

  // Delete cart
  deleteCart: async (cartId: string): Promise<void> => {
    await axios.delete(`${ADMIN_BASE}/carts/${cartId}`, {
      headers: getAuthHeaders(),
    });
  },

  // Get cart statistics
  getStatistics: async (
    dateFrom = '',
    dateTo = '',
  ): Promise<Record<string, unknown>> => {
    const params: Record<string, string> = {};
    if (dateFrom) params.date_from = dateFrom;
    if (dateTo) params.date_to = dateTo;

    const response = await axios.get<Record<string, unknown>>(
      `${ADMIN_BASE}/carts/statistics`,
      {
        params,
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },
};

// Manufacturer order service methods
export const manufacturerOrderService = {
  // Get manufacturer-scoped orders
  getOrders: async (
    params: Record<string, unknown> = {},
  ): Promise<{ orders: OrderSummary[]; total: number }> => {
    const response = await axios.get<{ orders: OrderSummary[]; total: number }>(
      `${MANUFACTURER_BASE}/orders`,
      {
        params,
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },

  // Get single order details (read-only)
  getOrder: async (orderId: string): Promise<OrderDetails> => {
    const response = await axios.get<OrderDetails>(`${MANUFACTURER_BASE}/orders/${orderId}`, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },

  // Update order status (only allowed for orders including their products)
  updateOrderStatus: async (
    orderId: string,
    status: string,
    reason = '',
  ): Promise<OrderSummary> => {
    const response = await axios.put<OrderSummary>(
      `${MANUFACTURER_BASE}/orders/${orderId}/status`,
      {
        status,
        reason,
      },
      {
        headers: getAuthHeaders(),
      },
    );
    return response.data;
  },
};


// Organization service methods
export const orgService = {
  getOrganizations: async (orgType: string | null = null): Promise<{ organizations: Organization[] }> => {
    const params: Record<string, string> = {};
    if (orgType) params.org_type = orgType;
    const response = await api.get<{ organizations: Organization[] }>(
      '/organizations',
      { params, headers: getAuthHeaders() },
    );
    return response.data;
  },
  createOrganization: async (payload: Partial<Organization>): Promise<Organization> => {
    const response = await api.post<Organization>('/organizations', payload, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },
  updateOrganization: async (id: number, payload: Partial<Organization>): Promise<Organization> => {
    const response = await api.put<Organization>(`/organizations/${id}`, payload, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },
  deleteOrganization: async (id: number): Promise<void> => {
    await api.delete(`/organizations/${id}`, { headers: getAuthHeaders() });
  },
  getOrganizationUsers: async (orgId: number): Promise<User[]> => {
    const response = await api.get<User[]>(`/organizations/${orgId}/users`, {
      headers: getAuthHeaders(),
    });
    return response.data;
  },
  setOrganizationUsers: async (
    orgId: number,
    assignments: { user_id: number; primary_role: string }[],
  ): Promise<Record<string, unknown>> => {
    const response = await api.post<Record<string, unknown>>(
      `/organizations/${orgId}/users`,
      { assignments },
      { headers: getAuthHeaders() },
    );
    return response.data;
  },
};

// Regions service methods
export const regionService = {
  getRegions: async (): Promise<{ regions: Region[] }> => {
    const response = await api.get<{ regions: Region[] }>('/regions', { headers: getAuthHeaders() });
    return response.data;
  },
  createRegion: async (payload: Partial<Region>): Promise<Region> => {
    const response = await api.post<Region>('/regions', payload, { headers: getAuthHeaders() });
    return response.data;
  },
  updateRegion: async (id: number, payload: Partial<Region>): Promise<Region> => {
    const response = await api.put<Region>(`/regions/${id}`, payload, { headers: getAuthHeaders() });
    return response.data;
  },
  deleteRegion: async (id: number): Promise<void> => {
    await api.delete(`/regions/${id}`, { headers: getAuthHeaders() });
  },
};

// Relationship management
export const relationshipService = {
  manageProductSourcing: async (
    productId: number,
    mappings: ProductSourcingMapping[],
  ): Promise<Record<string, unknown>> => {
    const response = await api.post<Record<string, unknown>>(
      `/products/${productId}/sourcing`,
      { mappings },
      { headers: getAuthHeaders() },
    );
    return response.data;
  },
  manageProductLogistics: async (
    productId: number,
    mappings: ProductLogisticsMapping[],
  ): Promise<Record<string, unknown>> => {
    const response = await api.post<Record<string, unknown>>(
      `/products/${productId}/logistics`,
      { mappings },
      { headers: getAuthHeaders() },
    );
    return response.data;
  },
  getProductSourcing: async (
    productId: number,
  ): Promise<{ mappings: ProductSourcingMapping[] }> => {
    const response = await api.get<{ mappings: ProductSourcingMapping[] }>(
      `/products/${productId}/sourcing`,
      { headers: getAuthHeaders() },
    );
    return response.data; // { mappings: [ { manufacturer_org_id, region_id, name } ] }
  },
  getProductLogistics: async (
    productId: number,
  ): Promise<{ mappings: ProductLogisticsMapping[] }> => {
    const response = await api.get<{ mappings: ProductLogisticsMapping[] }>(
      `/products/${productId}/logistics`,
      { headers: getAuthHeaders() },
    );
    return response.data; // { mappings: [ { tpl_org_id, name } ] }
  },
  getStorePartners: async (storeId: number): Promise<{ partners: StorePartner[] }> => {
    const response = await api.get<{ partners: StorePartner[] }>(
      `/stores/${storeId}/partners`,
      { headers: getAuthHeaders() },
    );
    return response.data;
  },
  // Batch fetch partners for multiple stores
  getStorePartnersBatch: async (
    storeIds: number[] = [],
  ): Promise<{ results: Record<string, { partners: StorePartner[] }> }> => {
    const ids = (storeIds || []).filter(Boolean).join(',');
    const response = await api.get<{ results: Record<string, { partners: StorePartner[] }> }>(
      `/store-partners`,
      {
        params: { store_ids: ids },
        headers: getAuthHeaders(),
      },
    );
    return response.data; // { results: { "7": { partners: [...] }, ... } }
  },
  manageStorePartners: async (
    storeId: number,
    mappings: StorePartner[],
  ): Promise<Record<string, unknown>> => {
    const response = await api.post<Record<string, unknown>>(
      `/stores/${storeId}/partners`,
      { mappings },
      { headers: getAuthHeaders() },
    );
    return response.data;
  },
};


// Export the axios instance as default for custom requests
export default api;
