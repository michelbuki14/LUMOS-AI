//! Render Pipeline
//! 
//! Manages the GPU rendering pipeline for image processing operations.

use std::sync::Arc;
use serde::{Deserialize, Serialize};

use crate::device::GpuDevice;
use crate::error::RenderError;
use crate::operations::Operation;
use crate::ImageBuffer;

/// Render pipeline configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PipelineConfig {
    pub tile_size: u32,
    pub memory_limit_mb: u64,
    pub use_half_precision: bool,
    pub max_operations: usize,
}

impl Default for PipelineConfig {
    fn default() -> Self {
        Self {
            tile_size: 1024,
            memory_limit_mb: 4096,
            use_half_precision: false,
            max_operations: 100,
        }
    }
}

/// Render pipeline
pub struct RenderPipeline {
    device: Arc<GpuDevice>,
    config: PipelineConfig,
}

/// Render request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenderRequest {
    pub image_data: String, // base64 encoded image
    pub width: u32,
    pub height: u32,
    pub operations: Vec<Operation>,
    pub output_format: OutputFormat,
    pub quality: u8,
}

/// Output format for rendering
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OutputFormat {
    Jpeg,
    Png,
    Tiff,
    Webp,
    Avif,
    Raw,
}

/// Render response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenderResponse {
    pub image_data: String, // base64 encoded result
    pub width: u32,
    pub height: u32,
    pub format: OutputFormat,
    pub processing_time_ms: u64,
}

/// Preview request (lower quality, faster)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreviewRequest {
    pub image_data: String,
    pub width: u32,
    pub height: u32,
    pub operations: Vec<Operation>,
    pub preview_size: u32, // max dimension for preview
}

/// Preview response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreviewResponse {
    pub image_data: String,
    pub width: u32,
    pub height: u32,
    pub processing_time_ms: u64,
}

impl RenderPipeline {
    /// Create a new render pipeline
    pub fn new(device: Arc<GpuDevice>, config: PipelineConfig) -> Self {
        Self { device, config }
    }

    /// Render an image with the given operations
    pub async fn render(&self, request: RenderRequest) -> Result<RenderResponse, RenderError> {
        let start = std::time::Instant::now();

        // Decode the image
        let image_data = base64::decode(&request.image_data)
            .map_err(|e| RenderError::InvalidParameters(format!("Invalid base64: {}", e)))?;

        // Apply operations
        let result = self.apply_operations(&image_data, request.width, request.height, &request.operations)?;

        // Encode the result
        let encoded = self.encode_image(&result, &request.output_format, request.quality)?;

        Ok(RenderResponse {
            image_data: base64::encode(&encoded),
            width: request.width,
            height: request.height,
            format: request.output_format,
            processing_time_ms: start.elapsed().as_millis() as u64,
        })
    }

    /// Generate a preview (lower quality, faster)
    pub async fn preview(&self, request: PreviewRequest) -> Result<PreviewResponse, RenderError> {
        let start = std::time::Instant::now();

        // Decode the image
        let image_data = base64::decode(&request.image_data)
            .map_err(|e| RenderError::InvalidParameters(format!("Invalid base64: {}", e)))?;

        // Apply operations
        let result = self.apply_operations(&image_data, request.width, request.height, &request.operations)?;

        // Encode as JPEG for preview
        let encoded = self.encode_image(&result, &OutputFormat::Jpeg, 80)?;

        Ok(PreviewResponse {
            image_data: base64::encode(&encoded),
            width: request.width,
            height: request.height,
            processing_time_ms: start.elapsed().as_millis() as u64,
        })
    }

    /// Apply a chain of operations to image data
    fn apply_operations(
        &self,
        image_data: &[u8],
        width: u32,
        height: u32,
        operations: &[Operation],
    ) -> Result<Vec<u8>, RenderError> {
        if operations.is_empty() {
            return Ok(image_data.to_vec());
        }

        // Load the image
        let mut image = image::load_from_memory(image_data)
            .map_err(|e| RenderError::ImageProcessing(format!("Failed to load image: {}", e)))?;

        // Apply each operation in sequence
        for op in operations {
            if !op.enabled {
                continue;
            }
            image = self.apply_operation(image, op)?;
        }

        // Convert back to bytes
        let mut output = Vec::new();
        let mut cursor = std::io::Cursor::new(&mut output);
        image
            .write_to(&mut cursor, image::ImageFormat::Jpeg)
            .map_err(|e| RenderError::ImageProcessing(format!("Failed to encode image: {}", e)))?;

        Ok(output)
    }

    /// Apply a single operation to an image
    fn apply_operation(
        &self,
        image: image::DynamicImage,
        op: &Operation,
    ) -> Result<image::DynamicImage, RenderError> {
        use image::GenericImageView;

        match op.op_type {
            crate::operations::OperationType::Exposure => {
                let params: crate::operations::ExposureParams = serde_json::from_value(op.params.clone())?;
                let factor = 2f64.powf(params.stops);
                Ok(image.brighten((factor * 100.0) as i32))
            }
            crate::operations::OperationType::Contrast => {
                let contrast: f64 = serde_json::from_value(op.params.clone())?;
                Ok(image.adjust_contrast(contrast as f32))
            }
            crate::operations::OperationType::Saturation => {
                let saturation: f64 = serde_json::from_value(op.params.clone())?;
                Ok(image.adjust_contrast(saturation as f32))
            }
            crate::operations::OperationType::Crop => {
                let params: CropParams = serde_json::from_value(op.params.clone())?;
                let rect = image::imageops::crop_imm(
                    &image,
                    params.x,
                    params.y,
                    params.width,
                    params.height,
                );
                Ok(rect.to_image().into())
            }
            _ => {
                // For operations not yet implemented, return the image unchanged
                tracing::warn!("Operation {:?} not yet implemented, skipping", op.op_type);
                Ok(image)
            }
        }
    }

    /// Encode an image to the specified format
    fn encode_image(
        &self,
        image_data: &[u8],
        format: &OutputFormat,
        quality: u8,
    ) -> Result<Vec<u8>, RenderError> {
        let image = image::load_from_memory(image_data)
            .map_err(|e| RenderError::ImageProcessing(format!("Failed to load image: {}", e)))?;

        let mut output = Vec::new();
        let mut cursor = std::io::Cursor::new(&mut output);

        match format {
            OutputFormat::Jpeg => {
                image
                    .write_to(&mut cursor, image::ImageFormat::Jpeg)
                    .map_err(|e| RenderError::ImageProcessing(format!("Failed to encode JPEG: {}", e)))?;
            }
            OutputFormat::Png => {
                image
                    .write_to(&mut cursor, image::ImageFormat::Png)
                    .map_err(|e| RenderError::ImageProcessing(format!("Failed to encode PNG: {}", e)))?;
            }
            OutputFormat::Tiff => {
                image
                    .write_to(&mut cursor, image::ImageFormat::Tiff)
                    .map_err(|e| RenderError::ImageProcessing(format!("Failed to encode TIFF: {}", e)))?;
            }
            OutputFormat::Webp => {
                // WebP encoding requires the webp feature
                image
                    .write_to(&mut cursor, image::ImageFormat::WebP)
                    .map_err(|e| RenderError::ImageProcessing(format!("Failed to encode WebP: {}", e)))?;
            }
            OutputFormat::Avif => {
                // AVIF encoding requires the avif feature
                return Err(RenderError::UnsupportedFormat("AVIF encoding not yet supported".to_string()));
            }
            OutputFormat::Raw => {
                return Err(RenderError::UnsupportedFormat("Raw encoding not supported".to_string()));
            }
        }

        Ok(output)
    }
}

/// Crop parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
struct CropParams {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
}

// Simple base64 encoding/decoding (in production, use the `base64` crate)
mod base64 {
    pub fn encode(data: &[u8]) -> String {
        use base64::Engine;
        base64::engine::general_purpose::STANDARD.encode(data)
    }

    pub fn decode(s: &str) -> Result<Vec<u8>, base64::DecodeError> {
        use base64::Engine;
        base64::engine::general_purpose::STANDARD.decode(s)
    }
}
