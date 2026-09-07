//! GPU Device Management
//! 
//! Handles initialization and management of GPU devices for rendering.

use std::sync::Arc;
use wgpu::{Adapter, Device, Instance, Queue, Surface};

use crate::error::RenderError;

/// GPU device wrapper
pub struct GpuDevice {
    instance: Instance,
    adapter: Adapter,
    device: Device,
    queue: Queue,
    info: GpuInfo,
}

/// GPU device information
#[derive(Debug, Clone)]
pub struct GpuInfo {
    pub name: String,
    pub vendor: GpuVendor,
    pub device_type: wgpu::DeviceType,
    pub backend: wgpu::Backend,
    pub memory_mb: u64,
}

/// GPU vendor enumeration
#[derive(Debug, Clone, PartialEq)]
pub enum GpuVendor {
    Nvidia,
    Amd,
    Intel,
    Apple,
    Unknown(u32),
}

impl GpuDevice {
    /// Initialize the best available GPU device
    pub async fn new() -> Result<Self, RenderError> {
        let instance = Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::all(),
            ..Default::default()
        });

        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::HighPerformance,
                compatible_surface: None,
                force_fallback_adapter: false,
            })
            .await
            .ok_or(RenderError::NoGpuAvailable)?;

        let info = adapter.get_info();
        let gpu_info = GpuInfo {
            name: info.name.clone(),
            vendor: match info.vendor {
                0x10de => GpuVendor::Nvidia,
                0x1002 => GpuVendor::Amd,
                0x8086 => GpuVendor::Intel,
                _ if info.name.contains("Apple") => GpuVendor::Apple,
                _ => GpuVendor::Unknown(info.vendor),
            },
            device_type: info.device_type,
            backend: info.backend,
            memory_mb: 0, // wgpu doesn't expose memory directly
        };

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    required_features: wgpu::Features::empty(),
                    required_limits: wgpu::Limits::default(),
                    label: Some("LUMOS AI Render Device"),
                    memory_hints: wgpu::MemoryHints::default(),
                },
                None,
            )
            .await
            .map_err(|e| RenderError::DeviceInit(e.to_string()))?;

        tracing::info!(
            "GPU initialized: {} ({:?}, {:?})",
            gpu_info.name,
            gpu_info.vendor,
            gpu_info.backend
        );

        Ok(Self {
            instance,
            adapter,
            device,
            queue,
            info: gpu_info,
        })
    }

    /// Get the wgpu device
    pub fn device(&self) -> &Device {
        &self.device
    }

    /// Get the wgpu queue
    pub fn queue(&self) -> &Queue {
        &self.queue
    }

    /// Get GPU info
    pub fn info(&self) -> &GpuInfo {
        &self.info
    }

    /// Check if device supports float textures
    pub fn supports_float_textures(&self) -> bool {
        self.device
            .features()
            .contains(wgpu::Features::TEXTURE_ADAPTER_SPECIFIC_FORMAT_FEATURES)
    }
}

/// Create a shared GPU device
pub async fn create_device() -> Result<Arc<GpuDevice>, RenderError> {
    GpuDevice::new().await.map(Arc::new)
}
