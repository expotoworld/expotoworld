/**
 * Catalog API Service
 * Handles communication with the catalog-service backend for products, categories, stores, and regions.
 */
import axios, { type AxiosInstance } from 'axios';

// ============================================
// API CONFIGURATION
// ============================================

// Get catalog API base URL from environment or default to localhost
function getCatalogApiUrl(): string {
  return import.meta.env.VITE_CATALOG_API_URL || 'http://localhost:8080/api/v1';
}

// Create axios instance for catalog API
const catalogApi: AxiosInstance = axios.create({
  baseURL: getCatalogApiUrl(),
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth interceptor (will use stored token when auth is implemented)
catalogApi.interceptors.request.use(
  (config) => {
    const tokenData = localStorage.getItem('admin_token');
    if (tokenData) {
      try {
        const { access_token } = JSON.parse(tokenData);
        if (access_token) {
          config.headers.Authorization = `Bearer ${access_token}`;
        }
      } catch {
        // Invalid token data, ignore
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// ============================================
// API RESPONSE TYPES (from catalog service)
// ============================================

export interface PaginationInfo {
  page: number;
  page_size: number;
  total: number;
  total_pages: number;
}

export interface PaginatedResponse<T> {
  items: T[];
  pagination: PaginationInfo;
}

// Backend response format (different from PaginatedResponse)
export interface BackendPaginatedResponse<T> {
  items: T[];
  total_count: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// Helper to convert backend pagination to frontend format
function mapBackendPagination<T, U>(
  response: BackendPaginatedResponse<T>,
  mapFn: (item: T) => U
): { items: U[]; pagination: PaginationInfo } {
  return {
    items: response.items?.map(mapFn) || [],
    pagination: {
      page: response.page,
      page_size: response.page_size,
      total: response.total_count,
      total_pages: response.total_pages,
    },
  };
}

// Raw API response types (snake_case from Go backend)
export interface ApiProduct {
  product_id: number;
  product_uuid: string;
  sku: string | null;
  title: string | null;
  description: string | null;
  store_id: number | null;
  owner_org_id: string | null;
  main_price: number;
  strikethrough_price: number | null;
  cost_price: number | null;
  tax_rate: number | null;
  stock_left: number | null;
  minimum_order_quantity: number;
  net_content: number | null;
  content_unit: string | null;
  reference_price: number | null;
  reference_unit: string | null;
  logistics_length: number | null;
  logistics_width: number | null;
  logistics_height: number | null;
  logistics_weight: number | null;
  logistics_volume: number | null;
  shelf_code: string | null;
  is_active: boolean;
  is_featured: boolean;
  is_mini_app_recommendation: boolean;
  is_archived: boolean;
  product_type: string;
  parent_id: number | null;
  visibility: string;
  is_default_variant: boolean;
  price_min: number | null;
  price_max: number | null;
  stock_total: number;
  variant_options_index: Record<string, unknown>;
  etw_store_type: string | null;
  etw_mini_app_type: string | null;
  primary_image_url: string | null;
  created_at: string;
  updated_at: string;
  attributes?: ApiProductAttribute[];
  specifications?: ApiProductSpecification[];
  images?: ApiProductImage[];
  category_ids?: number[];
  subcategory_ids?: number[];
}

export interface ApiProductAttribute {
  attribute_id: number;
  product_id: number | null;
  attribute_name: string | null;
  attribute_value: string | null;
  display_order: number;
  is_variant_defining: boolean;
  created_at: string;
}

export interface ApiProductSpecification {
  specification_id: number;
  product_id: number;
  spec_name: string;
  spec_value: string;
  display_order: number;
  created_at: string;
}

export interface ApiProductImage {
  image_id: number;
  product_id: number | null;
  image_url: string | null;
  display_order: number;
  is_primary: boolean;
  created_at: string;
}

export interface ApiCategory {
  category_id: number;
  name: string;
  description: string | null;
  image_url: string | null;
  display_order: number;
  is_active: boolean;
  store_id: number | null;
  etw_store_type: string | null;
  etw_mini_app_type: string | null;
  created_at: string;
  updated_at: string;
}

export interface ApiSubcategory {
  subcategory_id: number;
  name: string;
  description: string | null;
  image_url: string | null;
  category_id: number;
  display_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ApiStore {
  store_id: number;
  name: string;
  city: string;
  address: string;
  latitude: number;
  longitude: number;
  image_url: string | null;
  region_id: number | null;
  etw_store_type: string | null;
  etw_mini_app_type: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ApiRegion {
  region_id: number;
  name: string;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ============================================
// ADMIN PANEL TYPES (mapped from API)
// ============================================

export interface Product {
  id: string;
  name: string;
  description: string;
  originalPrice: number;
  currentPrice: number;
  stockLeft: number;
  minimumOrderQuantity: number;
  shelfCode: string;
  imageUrls: string[];
  primaryImageUrl?: string | null;
  categoryId: string;
  subcategoryId: string;
  storeId: string;
  organizationId?: string;
  isFeatured: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  // Additional fields from API
  sku?: string;
  netContent?: number;
  contentUnit?: string;
  taxRate?: number;
  costPrice?: number;
  referencePrice?: number;
  referenceUnit?: string;
  logisticsLength?: number;
  logisticsWidth?: number;
  logisticsHeight?: number;
  logisticsWeight?: number;
  logisticsVolume?: number;
  isArchived?: boolean;
  productType?: string;
  parentId?: string | null;
  etwStoreType?: string;
  etwMiniAppType?: string;
  // Variant-specific fields
  visibility?: string;
  isDefaultVariant?: boolean;
  priceMin?: number | null;
  priceMax?: number | null;
  stockTotal?: number;
  variantOptionsIndex?: Record<string, unknown>;
  isMiniAppRecommendation?: boolean;
  // Relations
  attributes?: ProductAttribute[];
  specifications?: ProductSpecification[];
  images?: ProductImage[];
  categoryIds?: number[];
  subcategoryIds?: number[];
}

export interface ProductAttribute {
  id: string;
  productId: string;
  attributeName: string;
  attributeValue: string;
  displayOrder: number;
  isVariantDefining?: boolean;
  createdAt: string;
}

export interface ProductSpecification {
  id: string;
  productId: string;
  specName: string;
  specValue: string;
  displayOrder: number;
  createdAt: string;
}

export interface ProductImage {
  id: string;
  productId: string;
  imageUrl: string;
  displayOrder: number;
  isPrimary: boolean;
  createdAt: string;
}

export interface ProductWithChildren extends Product {
  children?: Product[];
}

// API response type for product with children
export interface ApiProductWithChildren extends ApiProduct {
  children?: ApiProduct[];
}

// Input type for creating/updating products
export interface CreateProductData {
  sku?: string;
  title: string;
  description?: string;
  storeId?: number;
  ownerOrgId?: string;
  mainPrice?: number;
  strikethroughPrice?: number;
  costPrice?: number;
  taxRate?: number;
  stockLeft?: number;
  minimumOrderQuantity?: number;
  netContent?: number;
  contentUnit?: string;
  referencePrice?: number;
  referenceUnit?: string;
  logisticsLength?: number;
  logisticsWidth?: number;
  logisticsHeight?: number;
  logisticsWeight?: number;
  logisticsVolume?: number;
  shelfCode?: string;
  isActive?: boolean;
  isFeatured?: boolean;
  isMiniAppRecommendation?: boolean;
  productType: 'standard' | 'parent' | 'child';
  parentId?: number;
  visibility?: 'visible' | 'not_visible';
  isDefaultVariant?: boolean;
  etwStoreType?: string;
  etwMiniAppType?: string;
  attributes?: CreateAttributeData[];
  images?: CreateImageData[];
  categoryIds?: number[];
  subcategoryIds?: number[];
}

export interface CreateAttributeData {
  attributeName: string;
  attributeValue: string;
  displayOrder?: number;
  isVariantDefining?: boolean;
}

export interface CreateImageData {
  imageUrl: string;
  displayOrder?: number;
  isPrimary?: boolean;
}

export interface Category {
  id: string;
  name: string;
  iconUrl?: string;
  imageUrl?: string;
  description?: string;
  isActive: boolean;
  productCount: number;
  storeId?: string;
  displayOrder: number;
  etwStoreType?: string;
  etwMiniAppType?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Subcategory {
  id: string;
  name: string;
  categoryId: string;
  iconUrl?: string;
  imageUrl?: string;
  description?: string;
  productCount: number;
  isActive: boolean;
  displayOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface Store {
  id: string;
  name: string;
  storeType: string;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  imageUrl?: string;
  regionId?: string;
  isActive: boolean;
  etwStoreType?: string;
  etwMiniAppType?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Region {
  id: string;
  name: string;
  description?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// ============================================
// MAPPING FUNCTIONS (API -> Admin Panel)
// ============================================

function mapApiProduct(api: ApiProduct): Product {
  return {
    id: String(api.product_id),
    name: api.title || '',
    description: api.description || '',
    originalPrice: api.strikethrough_price ?? api.main_price,
    currentPrice: api.main_price,
    stockLeft: api.stock_left ?? 0,
    minimumOrderQuantity: api.minimum_order_quantity,
    shelfCode: api.shelf_code || '',
    imageUrls: api.images?.map((img) => img.image_url || '').filter(Boolean) || [],
    primaryImageUrl: api.primary_image_url,
    categoryId: api.category_ids?.[0] ? String(api.category_ids[0]) : '',
    subcategoryId: api.subcategory_ids?.[0] ? String(api.subcategory_ids[0]) : '',
    storeId: api.store_id ? String(api.store_id) : '',
    organizationId: api.owner_org_id || undefined,
    isFeatured: api.is_featured,
    isActive: api.is_active,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
    sku: api.sku || undefined,
    netContent: api.net_content ?? undefined,
    contentUnit: api.content_unit || undefined,
    taxRate: api.tax_rate ?? undefined,
    referencePrice: api.reference_price ?? undefined,
    referenceUnit: api.reference_unit || undefined,
    logisticsLength: api.logistics_length ?? undefined,
    logisticsWidth: api.logistics_width ?? undefined,
    logisticsHeight: api.logistics_height ?? undefined,
    logisticsWeight: api.logistics_weight ?? undefined,
    logisticsVolume: api.logistics_volume ?? undefined,
    isArchived: api.is_archived,
    productType: api.product_type,
    parentId: api.parent_id ? String(api.parent_id) : null,
    etwStoreType: api.etw_store_type || undefined,
    etwMiniAppType: api.etw_mini_app_type || undefined,
    // Variant-specific fields
    visibility: api.visibility,
    isDefaultVariant: api.is_default_variant,
    priceMin: api.price_min,
    priceMax: api.price_max,
    stockTotal: api.stock_total,
    variantOptionsIndex: api.variant_options_index,
    isMiniAppRecommendation: api.is_mini_app_recommendation,
    costPrice: api.cost_price ?? undefined,
    // Relations
    attributes: api.attributes?.map(mapApiAttribute),
    specifications: api.specifications?.map(mapApiSpecification),
    images: api.images?.map(mapApiImage),
    categoryIds: api.category_ids,
    subcategoryIds: api.subcategory_ids,
  };
}

function mapApiAttribute(api: ApiProductAttribute): ProductAttribute {
  return {
    id: String(api.attribute_id),
    productId: api.product_id ? String(api.product_id) : '',
    attributeName: api.attribute_name || '',
    attributeValue: api.attribute_value || '',
    displayOrder: api.display_order,
    isVariantDefining: api.is_variant_defining,
    createdAt: api.created_at,
  };
}

function mapApiSpecification(api: ApiProductSpecification): ProductSpecification {
  return {
    id: String(api.specification_id),
    productId: String(api.product_id),
    specName: api.spec_name,
    specValue: api.spec_value,
    displayOrder: api.display_order,
    createdAt: api.created_at,
  };
}

function mapApiImage(api: ApiProductImage): ProductImage {
  return {
    id: String(api.image_id),
    productId: api.product_id ? String(api.product_id) : '',
    imageUrl: api.image_url || '',
    displayOrder: api.display_order,
    isPrimary: api.is_primary,
    createdAt: api.created_at,
  };
}

function mapApiProductWithChildren(api: ApiProductWithChildren): ProductWithChildren {
  return {
    ...mapApiProduct(api),
    children: api.children?.map(mapApiProduct),
  };
}

function mapProductToApi(data: CreateProductData): Record<string, unknown> {
  return {
    sku: data.sku,
    title: data.title,
    description: data.description,
    store_id: data.storeId,
    owner_org_id: data.ownerOrgId,
    main_price: data.mainPrice,
    strikethrough_price: data.strikethroughPrice,
    cost_price: data.costPrice,
    tax_rate: data.taxRate,
    stock_left: data.stockLeft,
    minimum_order_quantity: data.minimumOrderQuantity,
    net_content: data.netContent,
    content_unit: data.contentUnit,
    reference_price: data.referencePrice,
    reference_unit: data.referenceUnit,
    logistics_length: data.logisticsLength,
    logistics_width: data.logisticsWidth,
    logistics_height: data.logisticsHeight,
    logistics_weight: data.logisticsWeight,
    logistics_volume: data.logisticsVolume,
    shelf_code: data.shelfCode,
    is_active: data.isActive,
    is_featured: data.isFeatured,
    is_mini_app_recommendation: data.isMiniAppRecommendation,
    product_type: data.productType,
    parent_id: data.parentId,
    visibility: data.visibility,
    is_default_variant: data.isDefaultVariant,
    etw_store_type: data.etwStoreType,
    etw_mini_app_type: data.etwMiniAppType,
    attributes: data.attributes?.map((attr) => ({
      attribute_name: attr.attributeName,
      attribute_value: attr.attributeValue,
      display_order: attr.displayOrder ?? 0,
      is_variant_defining: attr.isVariantDefining ?? false,
    })),
    images: data.images?.map((img) => ({
      image_url: img.imageUrl,
      display_order: img.displayOrder ?? 0,
      is_primary: img.isPrimary ?? false,
    })),
    category_ids: data.categoryIds,
    subcategory_ids: data.subcategoryIds,
  };
}

function mapApiCategory(api: ApiCategory): Category {
  return {
    id: String(api.category_id),
    name: api.name,
    description: api.description || undefined,
    imageUrl: api.image_url || undefined,
    isActive: api.is_active,
    productCount: 0, // Not provided by API yet
    storeId: api.store_id ? String(api.store_id) : undefined,
    displayOrder: api.display_order,
    etwStoreType: api.etw_store_type || undefined,
    etwMiniAppType: api.etw_mini_app_type || undefined,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

function mapApiSubcategory(api: ApiSubcategory): Subcategory {
  return {
    id: String(api.subcategory_id),
    name: api.name,
    categoryId: String(api.category_id),
    description: api.description || undefined,
    imageUrl: api.image_url || undefined,
    productCount: 0, // Not provided by API yet
    isActive: api.is_active,
    displayOrder: api.display_order,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

function mapApiStore(api: ApiStore): Store {
  return {
    id: String(api.store_id),
    name: api.name,
    storeType: api.etw_store_type || 'unknown',
    address: api.address,
    city: api.city,
    latitude: api.latitude,
    longitude: api.longitude,
    imageUrl: api.image_url || undefined,
    regionId: api.region_id ? String(api.region_id) : undefined,
    isActive: api.is_active,
    etwStoreType: api.etw_store_type || undefined,
    etwMiniAppType: api.etw_mini_app_type || undefined,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

function mapApiRegion(api: ApiRegion): Region {
  return {
    id: String(api.region_id),
    name: api.name,
    description: api.description || undefined,
    isActive: api.is_active,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

// ============================================
// QUERY PARAMETERS
// ============================================

export interface ProductQueryParams {
  page?: number;
  page_size?: number;
  store_id?: number;
  category_id?: number;
  subcategory_id?: number;
  is_active?: boolean;
  is_featured?: boolean;
  search?: string;
  sort_by?: string;
  sort_direction?: 'asc' | 'desc';
}

export interface CategoryQueryParams {
  page?: number;
  page_size?: number;
  store_id?: number;
  is_active?: boolean;
}

export interface StoreQueryParams {
  page?: number;
  page_size?: number;
  region_id?: number;
  is_active?: boolean;
}

// ============================================
// PRODUCT SERVICE
// ============================================

export const productApi = {
  /**
   * Get all products with optional filtering and pagination
   */
  getProducts: async (params: ProductQueryParams = {}): Promise<{ items: Product[]; pagination: PaginationInfo }> => {
    const response = await catalogApi.get<PaginatedResponse<ApiProduct>>('/products', { params });
    return {
      items: response.data.items.map(mapApiProduct),
      pagination: response.data.pagination,
    };
  },

  /**
   * Get a single product by ID
   */
  getProduct: async (id: string): Promise<Product> => {
    const response = await catalogApi.get<ApiProduct>(`/products/${id}`);
    return mapApiProduct(response.data);
  },

  /**
   * Create a new product
   */
  createProduct: async (data: Partial<Product>): Promise<Product> => {
    // Map admin panel data back to API format
    const apiData = {
      title: data.name,
      description: data.description,
      main_price: data.currentPrice,
      strikethrough_price: data.originalPrice,
      stock_left: data.stockLeft,
      minimum_order_quantity: data.minimumOrderQuantity,
      shelf_code: data.shelfCode,
      store_id: data.storeId ? Number(data.storeId) : null,
      is_featured: data.isFeatured,
      is_active: data.isActive,
      category_ids: data.categoryId ? [Number(data.categoryId)] : [],
      subcategory_ids: data.subcategoryId ? [Number(data.subcategoryId)] : [],
    };
    const response = await catalogApi.post<ApiProduct>('/products', apiData);
    return mapApiProduct(response.data);
  },

  /**
   * Update an existing product
   */
  updateProduct: async (id: string, data: Partial<Product>): Promise<Product> => {
    const apiData = {
      title: data.name,
      description: data.description,
      main_price: data.currentPrice,
      strikethrough_price: data.originalPrice,
      stock_left: data.stockLeft,
      minimum_order_quantity: data.minimumOrderQuantity,
      shelf_code: data.shelfCode,
      store_id: data.storeId ? Number(data.storeId) : null,
      is_featured: data.isFeatured,
      is_active: data.isActive,
      category_ids: data.categoryId ? [Number(data.categoryId)] : [],
      subcategory_ids: data.subcategoryId ? [Number(data.subcategoryId)] : [],
    };
    const response = await catalogApi.put<ApiProduct>(`/products/${id}`, apiData);
    return mapApiProduct(response.data);
  },

  /**
   * Archive (soft delete) a product
   */
  archiveProduct: async (id: string): Promise<void> => {
    await catalogApi.delete(`/products/${id}`);
  },

  /**
   * Unarchive a product
   */
  unarchiveProduct: async (id: string): Promise<Product> => {
    const response = await catalogApi.post<ApiProduct>(`/products/${id}/unarchive`);
    return mapApiProduct(response.data);
  },

  /**
   * Get product children (variants) for a parent product
   */
  getProductChildren: async (parentId: string): Promise<ProductWithChildren> => {
    const response = await catalogApi.get<ApiProductWithChildren>(`/products/${parentId}/children`);
    return mapApiProductWithChildren(response.data);
  },

  /**
   * Create a child product (variant) for a parent product
   */
  createChildProduct: async (parentId: string, data: CreateProductData): Promise<Product> => {
    const apiData = mapProductToApi(data);
    const response = await catalogApi.post<ApiProduct>(`/products/${parentId}/children`, apiData);
    return mapApiProduct(response.data);
  },

  /**
   * Sync parent product aggregates (price_min, price_max, stock_total, variant_options_index)
   */
  syncParentAggregates: async (parentId: string): Promise<void> => {
    await catalogApi.post(`/products/${parentId}/sync-aggregates`);
  },

  /**
   * Set a child product as the default variant for its parent
   */
  setDefaultVariant: async (childId: string): Promise<void> => {
    await catalogApi.put(`/products/${childId}/default-variant`);
  },

  /**
   * Generate child variants for a parent product based on its variant_options_index
   */
  generateVariants: async (
    parentId: string,
    options: {
      defaultPrice?: number;
      defaultStock?: number;
      skipExisting?: boolean;
    } = {}
  ): Promise<{
    created: number;
    skipped: number;
    totalPossible: number;
    variants: number[];
  }> => {
    const response = await catalogApi.post<{
      created: number;
      skipped: number;
      total_possible: number;
      variants: number[];
    }>(`/products/${parentId}/generate-variants`, {
      default_price: options.defaultPrice ?? 0,
      default_stock: options.defaultStock ?? 0,
      skip_existing: options.skipExisting ?? true,
    });
    return {
      created: response.data.created,
      skipped: response.data.skipped,
      totalPossible: response.data.total_possible,
      variants: response.data.variants,
    };
  },

  /**
   * Bulk update multiple child variants at once
   */
  bulkUpdateVariants: async (
    parentId: string,
    data: {
      variantIds: number[];
      price?: number;
      stock?: number;
      isActive?: boolean;
    }
  ): Promise<void> => {
    await catalogApi.put(`/products/${parentId}/bulk-update-variants`, {
      variant_ids: data.variantIds,
      price: data.price,
      stock: data.stock,
      is_active: data.isActive,
    });
  },

  // ============================================
  // IMAGE UPLOAD API
  // ============================================

  /**
   * Get a presigned URL for uploading an image to S3
   */
  getImageUploadUrl: async (
    productId: string,
    fileName: string,
    contentType: string
  ): Promise<{
    uploadUrl: string;
    objectKey: string;
    publicUrl: string;
    expiresIn: number;
  }> => {
    const response = await catalogApi.get<{
      upload_url: string;
      object_key: string;
      public_url: string;
      expires_in: number;
    }>(`/products/${productId}/images/upload-url`, {
      params: { file_name: fileName, content_type: contentType },
    });
    return {
      uploadUrl: response.data.upload_url,
      objectKey: response.data.object_key,
      publicUrl: response.data.public_url,
      expiresIn: response.data.expires_in,
    };
  },

  /**
   * Upload a file directly to S3 using a presigned URL
   */
  uploadImageToS3: async (uploadUrl: string, file: File): Promise<void> => {
    await fetch(uploadUrl, {
      method: 'PUT',
      body: file,
      headers: {
        'Content-Type': file.type,
      },
    });
  },

  /**
   * Create an image record after upload
   */
  createImage: async (
    productId: string,
    data: {
      imageUrl: string;
      displayOrder?: number;
      isPrimary?: boolean;
    }
  ): Promise<ProductImage> => {
    const response = await catalogApi.post<{
      image_id: number;
      product_id: number;
      image_url: string;
      display_order: number;
      is_primary: boolean;
      created_at: string;
    }>(`/products/${productId}/images`, {
      image_url: data.imageUrl,
      display_order: data.displayOrder ?? 0,
      is_primary: data.isPrimary ?? false,
    });
    return {
      id: String(response.data.image_id),
      productId: String(response.data.product_id),
      imageUrl: response.data.image_url,
      displayOrder: response.data.display_order,
      isPrimary: response.data.is_primary,
      createdAt: response.data.created_at,
    };
  },

  /**
   * Delete an image from the product and S3
   */
  deleteImage: async (productId: string, imageId: string): Promise<void> => {
    await catalogApi.delete(`/products/${productId}/images/${imageId}`);
  },

  /**
   * Set an image as the primary image for a product
   */
  setImagePrimary: async (productId: string, imageId: string): Promise<void> => {
    await catalogApi.put(`/products/${productId}/images/${imageId}/primary`);
  },

  /**
   * Reorder images for a product
   */
  reorderImages: async (productId: string, imageIds: number[]): Promise<void> => {
    await catalogApi.put(`/products/${productId}/images/reorder`, {
      image_ids: imageIds,
    });
  },

  /**
   * Upload an image file and create the image record (convenience method)
   */
  uploadAndCreateImage: async (
    productId: string,
    file: File,
    displayOrder?: number,
    isPrimary?: boolean,
    onProgress?: (progress: number) => void
  ): Promise<string> => {
    // Step 1: Get presigned upload URL
    onProgress?.(10);
    const { uploadUrl, publicUrl } = await productApi.getImageUploadUrl(
      productId,
      file.name,
      file.type
    );

    // Step 2: Upload file to S3 with progress tracking
    onProgress?.(30);
    await new Promise<void>((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      
      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          // Map upload progress from 30% to 90%
          const uploadProgress = (event.loaded / event.total) * 60;
          onProgress?.(30 + uploadProgress);
        }
      };
      
      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve();
        } else {
          reject(new Error(`Upload failed with status ${xhr.status}`));
        }
      };
      
      xhr.onerror = () => reject(new Error('Upload failed'));
      
      xhr.open('PUT', uploadUrl);
      xhr.setRequestHeader('Content-Type', file.type);
      xhr.send(file);
    });

    onProgress?.(90);

    // Step 3: Create image record in database
    await productApi.createImage(productId, {
      imageUrl: publicUrl,
      displayOrder,
      isPrimary,
    });

    onProgress?.(100);
    return publicUrl;
  },
};

// ============================================
// SPECIFICATION SERVICE
// ============================================

export interface CreateSpecificationData {
  productId: string;
  specName: string;
  specValue: string;
  displayOrder?: number;
}

export interface UpdateSpecificationData {
  specName?: string;
  specValue?: string;
  displayOrder?: number;
}

export interface BatchCreateSpecificationData {
  productId: string;
  specifications: Array<{
    specName: string;
    specValue: string;
    displayOrder?: number;
  }>;
}

export const specificationApi = {
  /**
   * Get all specifications for a product
   */
  getSpecifications: async (productId: string): Promise<ProductSpecification[]> => {
    const response = await catalogApi.get<ApiProductSpecification[]>('/specifications', {
      params: { product_id: productId },
    });
    return response.data.map(mapApiSpecification);
  },

  /**
   * Create a new specification
   */
  createSpecification: async (data: CreateSpecificationData): Promise<ProductSpecification> => {
    const apiData = {
      product_id: Number(data.productId),
      spec_name: data.specName,
      spec_value: data.specValue,
      display_order: data.displayOrder ?? 0,
    };
    const response = await catalogApi.post<ApiProductSpecification>('/specifications', apiData);
    return mapApiSpecification(response.data);
  },

  /**
   * Update an existing specification
   */
  updateSpecification: async (id: string, data: UpdateSpecificationData): Promise<ProductSpecification> => {
    const apiData: Record<string, unknown> = {};
    if (data.specName !== undefined) apiData.spec_name = data.specName;
    if (data.specValue !== undefined) apiData.spec_value = data.specValue;
    if (data.displayOrder !== undefined) apiData.display_order = data.displayOrder;
    
    const response = await catalogApi.put<ApiProductSpecification>(`/specifications/${id}`, apiData);
    return mapApiSpecification(response.data);
  },

  /**
   * Delete a specification
   */
  deleteSpecification: async (id: string): Promise<void> => {
    await catalogApi.delete(`/specifications/${id}`);
  },

  /**
   * Batch create specifications for a product
   */
  batchCreateSpecifications: async (data: BatchCreateSpecificationData): Promise<ProductSpecification[]> => {
    const apiData = {
      product_id: Number(data.productId),
      specifications: data.specifications.map((spec, index) => ({
        spec_name: spec.specName,
        spec_value: spec.specValue,
        display_order: spec.displayOrder ?? index,
      })),
    };
    const response = await catalogApi.post<ApiProductSpecification[]>('/specifications/batch', apiData);
    return response.data.map(mapApiSpecification);
  },

  /**
   * Replace all specifications for a product (delete existing and create new)
   */
  replaceAllSpecifications: async (
    productId: string,
    specifications: Array<{ specName: string; specValue: string; displayOrder?: number }>
  ): Promise<ProductSpecification[]> => {
    const apiData = {
      specifications: specifications.map((spec, index) => ({
        spec_name: spec.specName,
        spec_value: spec.specValue,
        display_order: spec.displayOrder ?? index,
      })),
    };
    const response = await catalogApi.put<ApiProductSpecification[]>(
      `/specifications/replace/${productId}`,
      apiData
    );
    return response.data.map(mapApiSpecification);
  },
};

// ============================================
// CATEGORY SERVICE
// ============================================

export const categoryApi = {
  /**
   * Get all categories with optional filtering
   */
  getCategories: async (params: CategoryQueryParams = {}): Promise<{ items: Category[]; pagination: PaginationInfo }> => {
    const response = await catalogApi.get<PaginatedResponse<ApiCategory>>('/categories', { params });
    return {
      items: response.data.items.map(mapApiCategory),
      pagination: response.data.pagination,
    };
  },

  /**
   * Get a single category by ID
   */
  getCategory: async (id: string): Promise<Category> => {
    const response = await catalogApi.get<ApiCategory>(`/categories/${id}`);
    return mapApiCategory(response.data);
  },

  /**
   * Get category tree (categories with their subcategories)
   */
  getCategoryTree: async (): Promise<Array<Category & { subcategories: Subcategory[] }>> => {
    const response = await catalogApi.get<Array<ApiCategory & { subcategories: ApiSubcategory[] }>>('/categories/tree');
    return response.data.map((cat) => ({
      ...mapApiCategory(cat),
      subcategories: cat.subcategories?.map(mapApiSubcategory) || [],
    }));
  },

  /**
   * Create a new category
   */
  createCategory: async (data: Partial<Category>): Promise<Category> => {
    const apiData = {
      name: data.name,
      description: data.description,
      image_url: data.imageUrl,
      display_order: data.displayOrder,
      is_active: data.isActive,
      store_id: data.storeId ? Number(data.storeId) : null,
    };
    const response = await catalogApi.post<ApiCategory>('/categories', apiData);
    return mapApiCategory(response.data);
  },

  /**
   * Update an existing category
   */
  updateCategory: async (id: string, data: Partial<Category>): Promise<Category> => {
    const apiData = {
      name: data.name,
      description: data.description,
      image_url: data.imageUrl,
      display_order: data.displayOrder,
      is_active: data.isActive,
      store_id: data.storeId ? Number(data.storeId) : null,
    };
    const response = await catalogApi.put<ApiCategory>(`/categories/${id}`, apiData);
    return mapApiCategory(response.data);
  },

  /**
   * Delete a category
   */
  deleteCategory: async (id: string): Promise<void> => {
    await catalogApi.delete(`/categories/${id}`);
  },

  /**
   * Get subcategories for a category
   */
  getSubcategories: async (categoryId: string): Promise<Subcategory[]> => {
    const response = await catalogApi.get<ApiSubcategory[]>(`/categories/${categoryId}/subcategories`);
    return response.data.map(mapApiSubcategory);
  },

  /**
   * Create a subcategory
   */
  createSubcategory: async (categoryId: string, data: Partial<Subcategory>): Promise<Subcategory> => {
    const apiData = {
      name: data.name,
      description: data.description,
      image_url: data.imageUrl,
      display_order: data.displayOrder,
      is_active: data.isActive,
    };
    const response = await catalogApi.post<ApiSubcategory>(`/categories/${categoryId}/subcategories`, apiData);
    return mapApiSubcategory(response.data);
  },

  /**
   * Update a subcategory
   */
  updateSubcategory: async (id: string, data: Partial<Subcategory>): Promise<Subcategory> => {
    const apiData = {
      name: data.name,
      description: data.description,
      image_url: data.imageUrl,
      display_order: data.displayOrder,
      is_active: data.isActive,
    };
    const response = await catalogApi.put<ApiSubcategory>(`/subcategories/${id}`, apiData);
    return mapApiSubcategory(response.data);
  },

  /**
   * Delete a subcategory
   */
  deleteSubcategory: async (id: string): Promise<void> => {
    await catalogApi.delete(`/subcategories/${id}`);
  },
};

// ============================================
// STORE SERVICE
// ============================================

export const storeApi = {
  /**
   * Get all stores with optional filtering
   */
  getStores: async (params: StoreQueryParams = {}): Promise<{ items: Store[]; pagination: PaginationInfo }> => {
    const response = await catalogApi.get<BackendPaginatedResponse<ApiStore>>('/stores', { params });
    return mapBackendPagination(response.data, mapApiStore);
  },

  /**
   * Get a single store by ID
   */
  getStore: async (id: string): Promise<Store> => {
    const response = await catalogApi.get<ApiStore>(`/stores/${id}`);
    return mapApiStore(response.data);
  },

  /**
   * Create a new store
   */
  createStore: async (data: Partial<Store>): Promise<Store> => {
    const apiData = {
      name: data.name,
      city: data.city,
      address: data.address,
      latitude: data.latitude,
      longitude: data.longitude,
      image_url: data.imageUrl,
      region_id: data.regionId ? Number(data.regionId) : null,
      etw_store_type: data.etwStoreType,
      etw_mini_app_type: data.etwMiniAppType,
      is_active: data.isActive,
    };
    const response = await catalogApi.post<ApiStore>('/stores', apiData);
    return mapApiStore(response.data);
  },

  /**
   * Update an existing store
   */
  updateStore: async (id: string, data: Partial<Store>): Promise<Store> => {
    const apiData = {
      name: data.name,
      city: data.city,
      address: data.address,
      latitude: data.latitude,
      longitude: data.longitude,
      image_url: data.imageUrl,
      region_id: data.regionId ? Number(data.regionId) : null,
      etw_store_type: data.etwStoreType,
      etw_mini_app_type: data.etwMiniAppType,
      is_active: data.isActive,
    };
    const response = await catalogApi.put<ApiStore>(`/stores/${id}`, apiData);
    return mapApiStore(response.data);
  },

  /**
   * Delete a store
   */
  deleteStore: async (id: string): Promise<void> => {
    await catalogApi.delete(`/stores/${id}`);
  },

  // ============================================
  // STORE IMAGE UPLOAD API
  // ============================================

  /**
   * Get a presigned URL for uploading a store image to S3
   */
  getImageUploadUrl: async (
    storeId: string,
    fileName: string,
    contentType: string
  ): Promise<{
    uploadUrl: string;
    objectKey: string;
    publicUrl: string;
    expiresIn: number;
  }> => {
    const response = await catalogApi.get<{
      upload_url: string;
      object_key: string;
      public_url: string;
      expires_in: number;
    }>(`/stores/${storeId}/image/upload-url`, {
      params: { file_name: fileName, content_type: contentType },
    });
    return {
      uploadUrl: response.data.upload_url,
      objectKey: response.data.object_key,
      publicUrl: response.data.public_url,
      expiresIn: response.data.expires_in,
    };
  },

  /**
   * Upload a file directly to S3 using a presigned URL
   */
  uploadImageToS3: async (uploadUrl: string, file: File): Promise<void> => {
    await fetch(uploadUrl, {
      method: 'PUT',
      body: file,
      headers: {
        'Content-Type': file.type,
      },
    });
  },

  /**
   * Upload a store image file and return the public URL (convenience method)
   */
  uploadStoreImage: async (
    storeId: string,
    file: File,
    onProgress?: (progress: number) => void
  ): Promise<string> => {
    // Step 1: Get presigned upload URL
    onProgress?.(10);
    const { uploadUrl, publicUrl } = await storeApi.getImageUploadUrl(
      storeId,
      file.name,
      file.type
    );

    // Step 2: Upload file to S3 with progress tracking
    onProgress?.(30);
    await new Promise<void>((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          // Map upload progress from 30% to 90%
          const uploadProgress = 30 + (event.loaded / event.total) * 60;
          onProgress?.(Math.round(uploadProgress));
        }
      };

      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve();
        } else {
          reject(new Error(`Upload failed with status ${xhr.status}`));
        }
      };

      xhr.onerror = () => reject(new Error('Upload failed'));

      xhr.open('PUT', uploadUrl);
      xhr.setRequestHeader('Content-Type', file.type);
      xhr.send(file);
    });

    onProgress?.(100);
    return publicUrl;
  },
};

// ============================================
// REGION SERVICE
// ============================================

export const regionApi = {
  /**
   * Get all regions
   */
  getRegions: async (): Promise<{ items: Region[]; pagination: PaginationInfo }> => {
    const response = await catalogApi.get<PaginatedResponse<ApiRegion>>('/regions');
    return {
      items: response.data.items.map(mapApiRegion),
      pagination: response.data.pagination,
    };
  },

  /**
   * Get a single region by ID
   */
  getRegion: async (id: string): Promise<Region> => {
    const response = await catalogApi.get<ApiRegion>(`/regions/${id}`);
    return mapApiRegion(response.data);
  },

  /**
   * Create a new region
   */
  createRegion: async (data: Partial<Region>): Promise<Region> => {
    const apiData = {
      name: data.name,
      description: data.description,
      is_active: data.isActive,
    };
    const response = await catalogApi.post<ApiRegion>('/regions', apiData);
    return mapApiRegion(response.data);
  },

  /**
   * Update an existing region
   */
  updateRegion: async (id: string, data: Partial<Region>): Promise<Region> => {
    const apiData = {
      name: data.name,
      description: data.description,
      is_active: data.isActive,
    };
    const response = await catalogApi.put<ApiRegion>(`/regions/${id}`, apiData);
    return mapApiRegion(response.data);
  },

  /**
   * Delete a region
   */
  deleteRegion: async (id: string): Promise<void> => {
    await catalogApi.delete(`/regions/${id}`);
  },
};

// Export the axios instance for custom requests
export { catalogApi };
