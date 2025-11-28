// Shared domain model interfaces for the admin panel

export type SortDirection = 'asc' | 'desc';

export interface User {
  id: number;
  username: string;
  email: string;
  first_name?: string | null;
  middle_name?: string | null;
  last_name?: string | null;
  full_name?: string | null;
  phone?: string | null;
  role: string;
  status: string;
  created_at?: string | null;
  last_login?: string | null;
  order_count?: number;
  is_active?: boolean;
}

export interface UserListResponse {
  users: User[];
  total: number;
}

export interface ProductImage {
  id: number;
  image_url: string;
  display_order?: number;
  is_primary?: boolean;
  // Used only on the frontend for previews
  url?: string;
}

export interface Product {
  id: number;
  title: string;
  sku: string;
  description_short?: string | null;
  description_long?: string;
  weight?: number;
  main_price: number;
  strikethrough_price?: number | null;
  cost_price?: number | null;
  stock_left?: number;
  minimum_order_quantity?: number;
  mini_app_type: string;
  store_id?: number | null;
  shelf_code?: string | null;
  category_ids?: number[];
  subcategory_ids?: number[];
  is_featured?: boolean;
  is_mini_app_recommendation?: boolean;
  is_active?: boolean;
  store_type?: string | null;
  // ETW fields (primary for new code)
  etw_store_type?: string | null;
  etw_mini_app_type?: string | null;
  image_url?: string | null;
  image_urls?: string[];
  images?: ProductImage[];
  created_at?: string | null;
  updated_at?: string | null;
}

export interface StorePartner {
  partner_org_id: string;
  name?: string;
}

export interface Store {
  id: number;
  name: string;
  city: string;
  address: string;
  latitude: number;
  longitude: number;
  type: string;
  etw_store_type?: string | null;
  etw_mini_app_type?: string | null;
  region_id: number | null;
  image_url?: string | null;
  is_active: boolean;
}

export interface Category {
  id: number;
  name: string;
  description?: string | null;
  image_url?: string | null;
  display_order?: number;
  is_active?: boolean;
  store_id?: number | null;
  etw_mini_app_type?: ETWMiniAppType | null;
  etw_store_type?: ETWStoreType | null;
  // Store info (when joined)
  store_name?: string | null;
  store_city?: string | null;
  store_etw_store_type?: ETWStoreType | null;
  store_etw_mini_app_type?: ETWMiniAppType | null;
}

export interface Subcategory {
  id: number;
  name: string;
  image_url?: string | null;
  display_order?: number;
  is_active?: boolean;
}

export interface Region {
  id: number;
  region_id: number;
  name: string;
  description?: string | null;
}

export interface Organization {
  org_id: number;
  name: string;
  org_type: string;
  parent_org_id?: number | null;
  contact_email?: string | null;
  contact_phone?: string | null;
  contact_address?: string | null;
}

export interface OrderSummary {
  id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  mini_app_type: string;
  store_id: number | null;
  store_name: string | null;
  total_amount: number;
  status: string;
  item_count: number;
  created_at: string;
  updated_at?: string | null;
}

export interface CartSummary {
  id: number;
  user_id: number;
  user_name: string;
  user_email: string;
  mini_app_type: string;
  store_id: number | null;
  store_name: string | null;
  item_count: number;
  total_value: number;
  updated_at: string;
}

export interface CartItemProduct {
  id: string;
  sku: string;
  title: string;
  main_price: number;
  stock_left?: number;
  minimum_order_quantity?: number;
  is_active?: boolean;
}

export interface CartItemDetail {
  id: string;
  product_id: string;
  quantity: number;
  product?: CartItemProduct | null;
  added_at?: string;
}

export interface CartDetails {
  cart: CartSummary;
  items: CartItemDetail[];
}


export interface OrderItem {
  product_title: string;
  product_sku: string;
  quantity: number;
  unit_price: number;
  total_price: number;
}

export interface OrderStatusChange {
  status: string;
  reason?: string | null;
  changed_at?: string | null;
  changed_by?: string | null;
}

export interface OrderDetails {
  order: OrderSummary;
  items: OrderItem[];
  status_history?: OrderStatusChange[];
}

export interface ProductSourcingMapping {
  manufacturer_org_id: string;
  region_id: number;
  name?: string;
}

export interface ProductLogisticsMapping {
  tpl_org_id: string;
  name?: string;
}


export interface UserAnalyticsByRole {
  Customer?: number;
  Manufacturer?: number;
  '3PL'?: number;
  Partner?: number;
}

export interface UserAnalytics {
  users_by_role?: UserAnalyticsByRole;
}

export interface DailyOrderStats {
  date: string;
  order_count: number;
  revenue: number;
}

export interface ProductOrderStats {
  product_id: string;
  product_title: string;
  order_count: number;
  total_revenue: number;
}

export interface OrderStatistics {
  total_orders: number;
  total_revenue: number;
  orders_by_status?: Record<string, number>;
  orders_by_mini_app?: Record<string, number>;
  revenue_by_mini_app?: Record<string, number>;
  daily_stats?: DailyOrderStats[];
  top_products?: ProductOrderStats[];
}
