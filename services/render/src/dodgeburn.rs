//! Dodge & Burn Operations
//! 
//! Professional-grade dodge (lighten) and burn (darkown) adjustments
//! with full control over tone range, brush dynamics, and luminosity masking.

use serde::{Deserialize, Serialize};
use crate::operations::{Operation, OperationType};

/// Dodge & burn mode
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum DodgeBurnMode {
    /// Lighten image areas
    Dodge,
    /// Darken image areas
    Burn,
    /// Sponge tool (saturation adjust)
    Sponge,
    /// Target midtones only
    Midtone,
    /// Target highlights only
    Highlight,
    /// Target shadows only
    Shadow,
}

/// Tone range targeting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToneRange {
    pub shadows: bool,
    pub midtones: bool,
    pub highlights: bool,
    pub shadow_range: (f64, f64),     // Luminance range 0-1
    pub midtone_range: (f64, f64),
    pub highlight_range: (f64, f64),
}

impl Default for ToneRange {
    fn default() -> Self {
        Self {
            shadows: true,
            midtones: true,
            highlights: true,
            shadow_range: (0.0, 0.33),
            midtone_range: (0.33, 0.66),
            highlight_range: (0.66, 1.0),
        }
    }
}

/// A single brush stroke
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrushStroke {
    pub points: Vec<StrokePoint>,
    pub pressure_data: Option<Vec<f64>>,
    pub timestamp: f64,
}

/// A point within a brush stroke
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StrokePoint {
    pub x: f64,
    pub y: f64,
    pub pressure: f64,      // 0.0 to 1.0
    pub tilt: f64,          // 0.0 to 1.0 (stylus tilt)
    pub timestamp: f64,
}

/// Dodge & burn parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DodgeBurnParams {
    pub mode: DodgeBurnMode,
    pub tone_range: ToneRange,
    pub exposure: f64,           // -1.0 to +1.0 (stops)
    pub softness: f64,           // 0.0 to 1.0 (brush edge feather)
    pub brush_size: f64,         // In pixels
    pub flow: f64,               // 0.0 to 1.0 (build-up rate)
    pub density: f64,           // 0.0 to 1.0 (max opacity per stroke)
    pub is_luminosity_mask: bool, // Protect hue/sat in color DB
    pub strokes: Vec<BrushStroke>,
}

impl Default for DodgeBurnParams {
    fn default() -> Self {
        Self {
            mode: DodgeBurnMode::Dodge,
            tone_range: ToneRange::default(),
            exposure: 0.3,
            softness: 0.8,
            brush_size: 100.0,
            flow: 0.3,
            density: 0.8,
            is_luminosity_mask: true,
            strokes: Vec::new(),
        }
    }
}

/// Apply dodge & burn to a single pixel value
/// 
/// # Arguments
/// * `pixel_value` - Original luminance value (0.0 to 1.0)
/// * `mode` - Dodge, Burn, or Sponge mode
/// * `exposure` - Strength of the effect (-1.0 to +1.0)
/// * `tone_range` - Which tonal ranges are affected
/// * `pixel_luminance` - The pixel's luminance for range checking
pub fn apply_dodge_burn_pixel(
    pixel_value: f64,
    mode: &DodgeBurnMode,
    exposure: f64,
    tone_range: &ToneRange,
    pixel_luminance: f64,
) -> f64 {
    // Check if pixel luminance falls within the targeted tone range
    let in_range = match mode {
        DodgeBurnMode::Dodge | DodgeBurnMode::Burn | DodgeBurnMode::Sponge => {
            (tone_range.shadows && pixel_luminance >= tone_range.shadow_range.0 && pixel_luminance <= tone_range.shadow_range.1)
            || (tone_range.midtones && pixel_luminance >= tone_range.midtone_range.0 && pixel_luminance <= tone_range.midtone_range.1)
            || (tone_range.highlights && pixel_luminance >= tone_range.highlight_range.0 && pixel_luminance <= tone_range.highlight_range.1)
        }
        DodgeBurnMode::Midtone => {
            pixel_luminance >= tone_range.midtone_range.0 && pixel_luminance <= tone_range.midtone_range.1
        }
        DodgeBurnMode::Highlight => {
            pixel_luminance >= tone_range.highlight_range.0 && pixel_luminance <= tone_range.highlight_range.1
        }
        DodgeBurnMode::Shadow => {
            pixel_luminance >= tone_range.shadow_range.0 && pixel_luminance <= tone_range.shadow_range.1
        }
    };

    if !in_range {
        return pixel_value;
    }

    match mode {
        DodgeBurnMode::Dodge => {
            // Dodge: lighten by multiplying by exposure factor
            let factor = 1.0 + exposure * 0.5;
            (pixel_value * factor).min(1.0)
        }
        DodgeBurnMode::Burn => {
            // Burn: darken by dividing by exposure factor
            let factor = 1.0 + exposure * 0.5;
            (pixel_value / factor).max(0.0)
        }
        DodgeBurnMode::Sponge => {
            // Sponge: adjust saturation (handled in color channel adjustment)
            pixel_value
        }
        DodgeBurnMode::Midtone | DodgeBurnMode::Highlight | DodgeBurnMode::Shadow => {
            // Targeted modes use the same dodge/burn logic
            let factor = 1.0 + exposure * 0.5;
            if exposure > 0.0 {
                (pixel_value * factor).min(1.0)
            } else {
                (pixel_value / factor.abs()).max(0.0)
            }
        }
    }
}

/// Calculate the weight of a brush at a given point
/// 
/// Returns a value between 0.0 (no effect) and 1.0 (full effect)
pub fn calculate_brush_weight(
    point_x: f64,
    point_y: f64,
    stroke_x: f64,
    stroke_y: f64,
    brush_size: f64,
    softness: f64,
    pressure: f64,
) -> f64 {
    let dx = point_x - stroke_x;
    let dy = point_y - stroke_y;
    let distance = (dx * dx + dy * dy).sqrt();
    
    if distance > brush_size {
        return 0.0;
    }

    // Calculate base weight (1.0 at center, 0.0 at edge)
    let normalized_dist = distance / brush_size;
    
    // Apply softness for feathered edge
    let weight = if softness > 0.0 {
        let feather_start = 1.0 - softness;
        if normalized_dist < feather_start {
            1.0
        } else {
            let feather_progress = (normalized_dist - feather_start) / softness;
            1.0 - feather_progress * feather_progress // Quadratic falloff
        }
    } else {
        1.0
    };

    // Apply pressure sensitivity
    weight * pressure
}

/// Create a default dodge operation
pub fn create_dodge_operation(exposure: f64) -> Operation {
    let params = DodgeBurnParams {
        mode: DodgeBurnMode::Dodge,
        exposure,
        ..Default::default()
    };
    
    Operation {
        id: format!("dodge_{}", uuid::Uuid::new_v4()),
        op_type: OperationType::DodgeBurn,
        enabled: true,
        params: serde_json::to_value(params).unwrap_or_default(),
    }
}

/// Create a default burn operation
pub fn create_burn_operation(exposure: f64) -> Operation {
    let params = DodgeBurnParams {
        mode: DodgeBurnMode::Burn,
        exposure,
        ..Default::default()
    };
    
    Operation {
        id: format!("burn_{}", uuid::Uuid::new_v4()),
        op_type: OperationType::DodgeBurn,
        enabled: true,
        params: serde_json::to_value(params).unwrap_or_default(),
    }
}

/// Calculate cumulative exposure at a point from all strokes
pub fn calculate_cumulative_exposure(
    x: f64,
    y: f64,
    params: &DodgeBurnParams,
) -> f64 {
    let mut cumulative = 0.0;
    
    for stroke in &params.strokes {
        for point in &stroke.points {
            let weight = calculate_brush_weight(
                x, y,
                point.x, point.y,
                params.brush_size,
                params.softness,
                point.pressure,
            );
            cumulative += weight * params.flow;
        }
    }
    
    cumulative.min(params.density)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dodge_lightens_pixel() {
        let result = apply_dodge_burn_pixel(0.5, &DodgeBurnMode::Dodge, 0.3, &ToneRange::default(), 0.5);
        assert!(result > 0.5, "Dodge should lighten pixel");
    }

    #[test]
    fn test_burn_darkens_pixel() {
        let result = apply_dodge_burn_pixel(0.5, &DodgeBurnMode::Burn, 0.3, &ToneRange::default(), 0.5);
        assert!(result < 0.5, "Burn should darken pixel");
    }

    #[test]
    fn test_tone_range_gating() {
        let tone_range = ToneRange {
            shadows: false,
            midtones: true,
            highlights: false,
            ..Default::default()
        };
        
        // Shadow pixel should NOT be affected
        let shadow_result = apply_dodge_burn_pixel(
            0.1, &DodgeBurnMode::Dodge, 0.5, &tone_range, 0.1
        );
        assert_eq!(shadow_result, 0.1, "Shadow pixel should not be affected");
        
        // Midtone pixel SHOULD be affected
        let midtone_result = apply_dodge_burn_pixel(
            0.5, &DodgeBurnMode::Dodge, 0.5, &tone_range, 0.5
        );
        assert!(midtone_result > 0.5, "Midtone pixel should be lightened");
    }

    #[test]
    fn test_brush_weight_falloff() {
        // Center point
        let center = calculate_brush_weight(0.0, 0.0, 0.0, 0.0, 100.0, 0.8, 1.0);
        assert!(center > 0.9, "Center should have near-full weight");
        
        // Edge point
        let edge = calculate_brush_weight(95.0, 0.0, 0.0, 0.0, 100.0, 0.8, 1.0);
        assert!(edge < 0.5, "Edge should have reduced weight");
        
        // Outside brush
        let outside = calculate_brush_weight(101.0, 0.0, 0.0, 0.0, 100.0, 0.8, 1.0);
        assert_eq!(outside, 0.0, "Outside brush should have no weight");
    }

    #[test]
    fn test_cumulative_exposure() {
        let params = DodgeBurnParams {
            strokes: vec![BrushStroke {
                points: vec![StrokePoint { x: 50.0, y: 50.0, pressure: 1.0, tilt: 0.0, timestamp: 0.0 }],
                pressure_data: None,
                timestamp: 0.0,
            }],
            brush_size: 100.0,
            softness: 0.8,
            flow: 0.5,
            density: 0.8,
            ..Default::default()
        };
        
        let exposure = calculate_cumulative_exposure(50.0, 50.0, &params);
        assert!(exposure > 0.0, "Exposure should be positive at stroke center");
        assert!(exposure <= params.density, "Exposure should not exceed density");
    }
}
