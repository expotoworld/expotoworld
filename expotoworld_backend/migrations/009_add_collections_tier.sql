-- Migration 009: Add collections tier (3rd level in category hierarchy)
-- Hierarchy: Category → Subcategory → Collection → Products

-- Collections table
CREATE TABLE IF NOT EXISTS admin_product_collection (
  collection_id SERIAL PRIMARY KEY,
  parent_subcategory_id INTEGER NOT NULL REFERENCES admin_product_subcategory(subcategory_id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  image_url TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_product_collection_parent_subcategory_id ON admin_product_collection(parent_subcategory_id);
CREATE INDEX IF NOT EXISTS idx_admin_product_collection_display_order ON admin_product_collection(display_order);

-- Product-collection mapping table
CREATE TABLE IF NOT EXISTS admin_product_collection_mapping (
  product_id INTEGER NOT NULL REFERENCES admin_product(product_id) ON DELETE CASCADE,
  collection_id INTEGER NOT NULL REFERENCES admin_product_collection(collection_id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, collection_id)
);

CREATE INDEX IF NOT EXISTS idx_admin_product_collection_mapping_collection_id ON admin_product_collection_mapping(collection_id);
