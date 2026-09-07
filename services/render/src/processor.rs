//! Image Processor
//! 
//! High-level image processing interface for the rendering engine.

use std::sync::Arc;
use serde::{Deserialize, Serialize};

use crate::device::GpuDevice;
use crate::error::RenderError;
use crate::operations::Operation;
use crate::pipeline::{PipelineConfig, RenderPipeline, RenderRequest, RenderResponse, PreviewRequest, PreviewResponse};
use crate::ImageBuffer;

/// Image processor configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessorConfig {
    pub pipeline: PipelineConfig,
    pub max_image_dimension: u32,
    pub default_jpeg_quality: u8,
}

impl Default for ProcessorConfig {
    fn default() -> Self {
        Self {
            pipeline: PipelineConfig::default(),
            max_image_dimension: 16384,
            default_jpeg_quality: 90,
        }
    }
}

/// Image processor
pub struct ImageProcessor {
    pipeline: RenderPipeline,
    config: ProcessorConfig,
}

/// Processing statistics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessingStats {
    pub total_processed: u64,
    pub total_errors: u64,
    pub average_processing_time_ms: f64,
    pub peak_memory_mb: u64,
}

impl ImageProcessor {
    /// Create a new image processor
    pub async fn new(config: ProcessorConfig) -> Result<Self, RenderError> {
        let device = crate::device::create_device().await?;
        let pipeline = RenderPipeline::new(device, config.pipeline.clone());
        
        Ok(Self {
            pipeline,
            config,
        })
    }

    /// Process an image with the given operations
    pub async fn process(&self, request: RenderRequest) -> Result<RenderResponse, RenderError> {
        // Validate dimensions
        if request.width > self.config.max_image_dimension 
            || request.height > self.config.max_image_dimension {
            return Err(RenderError::InvalidParameters(
                format!("Image dimensions {}x{} exceed maximum {}", 
                    request.width, request.height, self.config.max_image_dimension)
            ));
        }

        self.pipeline.render(request).await
    }

    /// Generate a preview
    pub async fn preview(&self, request: PreviewRequest) -> Result<PreviewResponse, RenderError> {
        self.pipeline.preview(request).await
    }

    /// Get processor statistics
    pub fn stats(&self) -> ProcessingStats {
        ProcessingStats {
            total_processed: 0,
            total_errors: 0,
            average_processing_time_ms: 0.0,
            peak_memory_mb: 0,
        }
    }
}

/// Create a default image processor
pub async fn create_processor() -> Result<ImageProcessor, RenderError> {
    ImageProcessor::new(ProcessorConfig::default()).await
}
