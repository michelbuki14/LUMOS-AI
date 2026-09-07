"""
LUMOS AI — Database Models
SQLAlchemy ORM models for PostgreSQL.
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, BigInteger, Text, ForeignKey, JSON, ARRAY, Float, Enum, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
import enum

from lumos.database import Base


class UserRole(str, enum.Enum):
    OWNER = "owner"
    ADMIN = "admin"
    EDITOR = "editor"
    VIEWER = "viewer"
    PROOFER = "proofer"


class AssetStatus(str, enum.Enum):
    INGESTING = "ingesting"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"
    ARCHIVED = "archived"


class ProjectStatus(str, enum.Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    COMPLETED = "completed"
    ARCHIVED = "archived"


class GalleryStatus(str, enum.Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    EXPIRED = "expired"
    CLOSED = "closed"


class ExportFormat(str, enum.Enum):
    JPEG = "jpeg"
    PNG = "png"
    TIFF = "tiff"
    PSD = "psd"
    DNG = "dng"
    WEBP = "webp"
    AVIF = "avif"


class User(Base):
    """User account model."""
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String)
    name = Column(String)
    avatar_url = Column(String)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    workspaces = relationship("WorkspaceMember", back_populates="user")
    projects = relationship("Project", back_populates="created_by_user")


class Workspace(Base):
    """Top-level organization unit."""
    __tablename__ = "workspaces"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    owner_id = Column(String, ForeignKey("users.id"))
    billing_plan = Column(String, default="free")
    storage_quota_bytes = Column(BigInteger, default=10737418240)  # 10GB
    storage_used_bytes = Column(BigInteger, default=0)
    max_seats = Column(Integer, default=1)
    settings = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    assets = relationship("Asset", back_populates="workspace")
    projects = relationship("Project", back_populates="workspace")
    galleries = relationship("Gallery", back_populates="workspace")


class WorkspaceMember(Base):
    """Many-to-many relationship between users and workspaces."""
    __tablename__ = "workspace_members"

    workspace_id = Column(String, ForeignKey("workspaces.id"), primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    role = Column(String, default="editor")
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="workspaces")
    workspace = relationship("Workspace")


class Asset(Base):
    """Image asset with full metadata."""
    __tablename__ = "assets"
    __table_args__ = (
        Index("idx_assets_workspace", "workspace_id"),
        Index("idx_assets_content_hash", "content_hash"),
        Index("idx_assets_rating", "workspace_id", "rating"),
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    workspace_id = Column(String, ForeignKey("workspaces.id"))
    
    # File info
    original_filename = Column(String, nullable=False)
    storage_path = Column(String, nullable=False)
    content_hash = Column(String, unique=True)  # SHA-256
    file_size_bytes = Column(BigInteger)
    
    # Image properties
    width = Column(Integer)
    height = Column(Integer)
    format = Column(String)
    color_space = Column(String)
    bit_depth = Column(Integer)
    
    # EXIF metadata
    camera_make = Column(String)
    camera_model = Column(String)
    lens_make = Column(String)
    lens_model = Column(String)
    focal_length_mm = Column(Float)
    aperture = Column(Float)
    shutter_speed = Column(String)
    iso = Column(Integer)
    datetime_original = Column(DateTime(timezone=True))
    gps_lat = Column(Float)
    gps_lng = Column(Float)
    
    # AI analysis
    ai_metadata = Column(JSON, default=dict)
    ai_processing_status = Column(String, default="ingesting")
    
    # User metadata
    rating = Column(Integer)
    is_starred = Column(Boolean, default=False)
    is_picked = Column(Boolean, default=True)
    color_label = Column(String)
    tags = Column(ARRAY(String), default=list)
    keywords = Column(ARRAY(String), default=list)
    
    # Timestamps
    imported_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    workspace = relationship("Workspace", back_populates="assets")
    adjustment_graphs = relationship("AdjustmentGraph", back_populates="asset")
    masks = relationship("Mask", back_populates="asset")


class Project(Base):
    """Photography project."""
    __tablename__ = "projects"
    __table_args__ = (
        Index("idx_projects_workspace", "workspace_id"),
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    workspace_id = Column(String, ForeignKey("workspaces.id"))
    created_by = Column(String, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    description = Column(Text)
    project_type = Column(String)
    status = Column(String, default="draft")
    due_date = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    settings = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    workspace = relationship("Workspace", back_populates="projects")
    created_by_user = relationship("User", back_populates="projects")
    project_assets = relationship("ProjectAsset", back_populates="project")


class ProjectAsset(Base):
    """Many-to-many between projects and assets."""
    __tablename__ = "project_assets"
    project_id = Column(String, ForeignKey("projects.id"), primary_key=True)
    asset_id = Column(String, ForeignKey("assets.id"), primary_key=True)
    added_at = Column(DateTime(timezone=True), server_default=func.now())

    project = relationship("Project", back_populates="project_assets")
    asset = relationship("Asset")


class Album(Base):
    """Image collection/album."""
    __tablename__ = "albums"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    workspace_id = Column(String, ForeignKey("workspaces.id"))
    created_by = Column(String, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    description = Column(Text)
    is_smart = Column(Boolean, default=False)
    smart_query = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Gallery(Base):
    """Client delivery gallery."""
    __tablename__ = "galleries"
    __table_args__ = (
        Index("idx_galleries_workspace", "workspace_id"),
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    workspace_id = Column(String, ForeignKey("workspaces.id"))
    created_by = Column(String, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    description = Column(Text)
    status = Column(String, default="draft")
    password_hash = Column(String)
    expires_at = Column(DateTime(timezone=True))
    theme = Column(JSON, default=dict)
    view_count = Column(Integer, default=0)
    download_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    published_at = Column(DateTime(timezone=True))

    # Relationships
    workspace = relationship("Workspace", back_populates="galleries")


class AdjustmentGraph(Base):
    """Non-destructive adjustment graph."""
    __tablename__ = "adjustment_graphs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    asset_id = Column(String, ForeignKey("assets.id"))
    created_by = Column(String, ForeignKey("users.id"))
    name = Column(String, default="Default")
    graph_data = Column(JSON, nullable=False)
    graph_hash = Column(String)
    version = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    asset = relationship("Asset", back_populates="adjustment_graphs")


class Mask(Base):
    """AI-generated or manual masks."""
    __tablename__ = "masks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    asset_id = Column(String, ForeignKey("assets.id"))
    mask_type = Column(String, nullable=False)
    generation_method = Column(String)
    model_version = Column(String)
    parameters = Column(JSON, default=dict)
    raster_path = Column(String)
    feather_radius = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    asset = relationship("Asset", back_populates="masks")


class BatchJob(Base):
    """Batch processing job."""
    __tablename__ = "batch_jobs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    workspace_id = Column(String, ForeignKey("workspaces.id"))
    created_by = Column(String, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    status = Column(String, default="pending")
    total_items = Column(Integer, default=0)
    completed_items = Column(Integer, default=0)
    failed_items = Column(Integer, default=0)
    config = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))


class AuditLog(Base):
    """Audit trail for all mutations."""
    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("idx_audit_logs_workspace", "workspace_id"),
        Index("idx_audit_logs_created", "created_at"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    workspace_id = Column(String, ForeignKey("workspaces.id"))
    user_id = Column(String, ForeignKey("users.id"))
    action = Column(String, nullable=False)
    resource_type = Column(String)
    resource_id = Column(String)
    details = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
