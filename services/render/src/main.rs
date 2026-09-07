//! LUMOS AI — Rendering Engine Entry Point
//! 
//! High-performance GPU-accelerated image rendering service.

use std::net::SocketAddr;
use std::sync::Arc;

use axum::{
    routing::{get, post},
    Router, Json, extract::State,
};
use serde::{Deserialize, Serialize};
use tower_http::cors::CorsLayer;

use lumos_render::device::create_device;
use lumos_render::pipeline::{RenderRequest, RenderResponse, PreviewRequest, PreviewResponse};
use lumos_render::processor::{ImageProcessor, ProcessorConfig};

/// Application state
struct AppState {
    processor: ImageProcessor,
}

/// Health check response
#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
    gpu: Option<String>,
}

/// GPU info response
#[derive(Serialize)]
struct GpuInfoResponse {
    name: String,
    vendor: String,
    backend: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    tracing::info!("Starting LUMOS AI Rendering Engine v1.0.0");

    // Initialize GPU device
    let device = create_device().await?;
    let gpu_info = device.info().clone();
    tracing::info!(
        "GPU initialized: {} ({:?})",
        gpu_info.name,
        gpu_info.backend
    );

    // Create image processor
    let processor = ImageProcessor::new(ProcessorConfig::default()).await?;
    let state = Arc::new(AppState { processor });

    // Build the router
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/gpu", get(gpu_info_handler))
        .route("/render", post(render_image))
        .route("/preview", post(preview_image))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start the server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8002));
    tracing::info!("Rendering engine listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

/// Health check endpoint
async fn health_check(State(state): State<Arc<AppState>>) -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        gpu: Some(state.processor.stats().total_processed.to_string()),
    })
}

/// GPU info endpoint
async fn gpu_info_handler() -> Json<GpuInfoResponse> {
    Json(GpuInfoResponse {
        name: "GPU".to_string(),
        vendor: "Unknown".to_string(),
        backend: "Vulkan".to_string(),
    })
}

/// Render an image
async fn render_image(
    State(state): State<Arc<AppState>>,
    Json(request): Json<RenderRequest>,
) -> Result<Json<RenderResponse>, lumos_render::RenderError> {
    let response = state.processor.process(request).await?;
    Ok(Json(response))
}

/// Generate a preview
async fn preview_image(
    State(state): State<Arc<AppState>>,
    Json(request): Json<PreviewRequest>,
) -> Result<Json<PreviewResponse>, lumos_render::RenderError> {
    let response = state.processor.preview(request).await?;
    Ok(Json(response))
}
