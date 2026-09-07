//! Error types for the rendering engine

use thiserror::Error;

#[derive(Error, Debug)]
pub enum RenderError {
    #[error("No GPU device available")]
    NoGpuAvailable,

    #[error("Failed to initialize GPU device: {0}")]
    DeviceInit(String),

    #[error("Failed to create render pipeline: {0}")]
    PipelineCreation(String),

    #[error("Image processing error: {0}")]
    ImageProcessing(String),

    #[error("Unsupported image format: {0}")]
    UnsupportedFormat(String),

    #[error("Out of memory")]
    OutOfMemory,

    #[error("Invalid parameters: {0}")]
    InvalidParameters(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Image error: {0}")]
    Image(#[from] image::ImageError),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

impl axum::response::IntoResponse for RenderError {
    fn into_response(self) -> axum::response::Response {
        (
            axum::http::StatusCode::INTERNAL_SERVER_ERROR,
            axum::Json(serde_json::json!({
                "error": self.to_string(),
            })),
        )
            .into_response()
    }
}
