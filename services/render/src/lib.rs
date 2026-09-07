//! LUMOS AI — GPU-Accelerated Rendering Engine
//! 
//! High-performance image processing pipeline with Vulkan/Metal/DX12 support.
//! Handles RAW demosaicing, tone mapping, color space conversion, and
//! non-destructive adjustment rendering.

pub mod device;
pub mod dodgeburn;
pub mod error;
pub mod operations;
pub mod pipeline;
pub mod processor;

pub use dodgeburn::{DodgeBurnParams, DodgeBurnMode, ToneRange, BrushStroke, StrokePoint};
pub use error::RenderError;
pub use operations::Operation;
pub use pipeline::RenderPipeline;
pub use processor::ImageProcessor;

use serde::{Deserialize, Serialize};

/// Image format enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ImageFormat {
    Rgb8,
    Rgba8,
    Rgb16,
    Rgba16,
    Rgb32F,
    Rgba32F,
    Bgr8,
    Bgra8,
}

/// Color space for rendering operations
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ColorSpace {
    Srgb,
    AdobeRgb,
    DisplayP3,
    ProPhotoRgb,
    Rec2020,
    Rec709,
    Linear,
    Cmyk,
}

/// Image metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageMetadata {
    pub width: u32,
    pub height: u32,
    pub format: ImageFormat,
    pub color_space: ColorSpace,
    pub bit_depth: u8,
    pub dpi: f32,
    pub icc_profile: Option<String>,
    pub exif: Option<serde_json::Value>,
}

/// A rendered image buffer
#[derive(Debug)]
pub struct ImageBuffer {
    pub data: Vec<u8>,
    pub metadata: ImageMetadata,
}

impl ImageBuffer {
    pub fn new(data: Vec<u8>, metadata: ImageMetadata) -> Self {
        Self { data, metadata }
    }

    pub fn size_in_bytes(&self) -> usize {
        self.data.len()
    }

    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}
