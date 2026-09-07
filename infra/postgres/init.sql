# =============================================================================
# LUMOS AI — Database Schema (PostgreSQL)
# =============================================================================

-- =============================================================================
-- Extensions
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- =============================================================================
-- Enums
-- =============================================================================
CREATE TYPE user_role AS ENUM ('owner', 'admin', 'editor', 'viewer', 'proofer');
CREATE TYPE asset_status AS ENUM ('ingesting', 'processing', 'ready', 'failed', 'archived');
CREATE TYPE project_status AS ENUM ('draft', 'active', 'completed', 'archived');
CREATE TYPE gallery_status AS ENUM ('draft', 'published', 'expired', 'closed');
CREATE TYPE export_format AS ENUM ('jpeg', 'png', 'tiff', 'psd', 'dng', 'webp', 'avif');
CREATE TYPE ai_operation_type AS ENUM (
    'culling', 'masking', 'portrait_retouch', 'background_generation',
    'object_removal', 'relighting', 'super_resolution', 'demosaic',
    'scene_analysis', 'face_detection', 'ocr'
);

-- =============================================================================
-- Users
-- =============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    name TEXT,
    avatar_url TEXT,
    bio TEXT,
    website TEXT,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    oauth_provider TEXT,
    oauth_id TEXT,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_oauth ON users(oauth_provider, oauth_id) WHERE oauth_provider IS NOT NULL;

-- =============================================================================
-- Workspaces
-- =============================================================================
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    billing_plan TEXT DEFAULT 'free',
    storage_quota_bytes BIGINT DEFAULT 10737418240, -- 10 GB
    storage_used_bytes BIGINT DEFAULT 0,
    max_seats INT DEFAULT 1,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_workspaces_owner ON workspaces(owner_id);

-- =============================================================================
-- Workspace Members
-- =============================================================================
CREATE TABLE workspace_members (
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role user_role DEFAULT 'editor',
    invited_by UUID REFERENCES users(id),
    joined_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (workspace_id, user_id)
);

CREATE INDEX idx_workspace_members_user ON workspace_members(user_id);

-- =============================================================================
-- Assets (Images)
-- =============================================================================
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- File info
    original_filename TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    content_hash TEXT UNIQUE, -- SHA-256 for dedup
    file_size_bytes BIGINT,
    
    -- Image properties
    width INT,
    height INT,
    format TEXT, -- CR3, NEF, ARW, DNG, JPEG, PNG, etc.
    color_space TEXT,
    bit_depth INT,
    
    -- EXIF metadata
    camera_make TEXT,
    camera_model TEXT,
    lens_make TEXT,
    lens_model TEXT,
    focal_length_mm FLOAT,
    aperture FLOAT,
    shutter_speed TEXT,
    iso INT,
    white_balance TEXT,
    flash TEXT,
    gps_lat FLOAT,
    gps_lng FLOAT,
    gps_altitude FLOAT,
    datetime_original TIMESTAMPTZ,
    
    -- AI analysis
    ai_metadata JSONB DEFAULT '{}',
    ai_processing_status asset_status DEFAULT 'ingesting',
    
    -- User metadata
    rating INT CHECK (rating >= 0 AND rating <= 5),
    is_starred BOOLEAN DEFAULT false,
    is_picked BOOLEAN DEFAULT true,
    color_label TEXT,
    tags TEXT[] DEFAULT '{}',
    keywords TEXT[] DEFAULT '{}',
    notes TEXT,
    
    -- Timestamps
    captured_at TIMESTAMPTZ,
    imported_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_assets_workspace ON assets(workspace_id);
CREATE INDEX idx_assets_content_hash ON assets(content_hash) WHERE content_hash IS NOT NULL;
CREATE INDEX idx_assets_camera ON assets(camera_make, camera_model);
CREATE INDEX idx_assets_datetime ON assets(datetime_original);
CREATE INDEX idx_assets_rating ON assets(workspace_id, rating);
CREATE INDEX idx_assets_tags ON assets USING GIN(tags);
CREATE INDEX idx_assets_keywords ON assets USING GIN(keywords);
CREATE INDEX idx_assets_ai_metadata ON assets USING GIN(ai_metadata);

-- =============================================================================
-- Projects
-- =============================================================================
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    project_type TEXT, -- wedding, portrait, product, real_estate, etc.
    status project_status DEFAULT 'draft',
    due_date DATE,
    completed_at TIMESTAMPTZ,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_projects_workspace ON projects(workspace_id);
CREATE INDEX idx_projects_status ON projects(status);

-- =============================================================================
-- Project Assets (many-to-many)
-- =============================================================================
CREATE TABLE project_assets (
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    added_by UUID REFERENCES users(id) ON DELETE SET NULL,
    added_at TIMESTAMPTZ DEFAULT now(),
    sort_order INT DEFAULT 0,
    PRIMARY KEY (project_id, asset_id)
);

CREATE INDEX idx_project_assets_asset ON project_assets(asset_id);

-- =============================================================================
-- Albums
-- =============================================================================
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    cover_asset_id UUID REFERENCES assets(id) ON DELETE SET NULL,
    is_smart BOOLEAN DEFAULT false,
    smart_query JSONB, -- For smart albums
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_albums_workspace ON albums(workspace_id);

-- =============================================================================
-- Album Assets
-- =============================================================================
CREATE TABLE album_assets (
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT now(),
    sort_order INT DEFAULT 0,
    PRIMARY KEY (album_id, asset_id)
);

-- =============================================================================
-- Adjustment Graphs (Non-destructive edits)
-- =============================================================================
CREATE TABLE adjustment_graphs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT DEFAULT 'Default',
    graph_data JSONB NOT NULL, -- The DAG of operations
    graph_hash TEXT, -- For render cache
    is_default BOOLEAN DEFAULT false,
    version INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_adjustment_graphs_asset ON adjustment_graphs(asset_id);
CREATE INDEX idx_adjustment_graphs_hash ON adjustment_graphs(graph_hash) WHERE graph_hash IS NOT NULL;

-- =============================================================================
-- Masks
-- =============================================================================
CREATE TABLE masks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    mask_type TEXT NOT NULL, -- subject, sky, skin, face, object, brush, gradient, etc.
    generation_method TEXT, -- ai:sam, ai:bg, manual:brush, etc.
    model_version TEXT,
    parameters JSONB DEFAULT '{}',
    raster_path TEXT, -- Cached raster mask
    feather_radius FLOAT DEFAULT 0,
    density FLOAT DEFAULT 1.0,
    is_inverted BOOLEAN DEFAULT false,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_masks_asset ON masks(asset_id);
CREATE INDEX idx_masks_type ON masks(mask_type);

-- =============================================================================
-- Galleries (Client delivery)
-- =============================================================================
CREATE TABLE galleries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    status gallery_status DEFAULT 'draft',
    password_hash TEXT,
    expires_at TIMESTAMPTZ,
    theme JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    published_at TIMESTAMPTZ
);

CREATE INDEX idx_galleries_workspace ON galleries(workspace_id);
CREATE INDEX idx_galleries_status ON galleries(status);

-- =============================================================================
-- Gallery Assets
-- =============================================================================
CREATE TABLE gallery_assets (
    gallery_id UUID REFERENCES galleries(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT now(),
    sort_order INT DEFAULT 0,
    is_selected BOOLEAN DEFAULT false, -- Client selection
    PRIMARY KEY (gallery_id, asset_id)
);

-- =============================================================================
-- AI Operations (Processing jobs)
-- =============================================================================
CREATE TABLE ai_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
    operation_type ai_operation_type NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, running, completed, failed
    parameters JSONB DEFAULT '{}',
    result JSONB DEFAULT '{}',
    error_message TEXT,
    processing_time_ms INT,
    model_version TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_ai_operations_workspace ON ai_operations(workspace_id);
CREATE INDEX idx_ai_operations_asset ON ai_operations(asset_id);
CREATE INDEX idx_ai_operations_status ON ai_operations(status);

-- =============================================================================
-- Export Presets
-- =============================================================================
CREATE TABLE export_presets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    format export_format DEFAULT 'jpeg',
    quality INT DEFAULT 90,
    width INT,
    height INT,
    color_space TEXT DEFAULT 'srgb',
    sharpening TEXT DEFAULT 'none', -- none, screen, matte, glossy
    watermark_enabled BOOLEAN DEFAULT false,
    watermark_path TEXT,
    watermark_position TEXT DEFAULT 'bottom-right',
    watermark_opacity FLOAT DEFAULT 0.5,
    metadata_strip BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================================================
-- Batch Jobs
-- =============================================================================
CREATE TABLE batch_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    total_items INT DEFAULT 0,
    completed_items INT DEFAULT 0,
    failed_items INT DEFAULT 0,
    config JSONB DEFAULT '{}',
    results JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- =============================================================================
-- Audit Log
-- =============================================================================
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    workspace_id UUID REFERENCES workspaces(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id UUID,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audit_logs_workspace ON audit_logs(workspace_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- =============================================================================
-- Triggers for updated_at
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workspaces_updated_at BEFORE UPDATE ON workspaces
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_albums_updated_at BEFORE UPDATE ON albums
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_galleries_updated_at BEFORE UPDATE ON galleries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
