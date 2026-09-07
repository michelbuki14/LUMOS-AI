/// Dodge & Burn parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DodgeBurnParams {
    pub mode: DodgeBurnMode,
    pub tone_range: ToneRange,
    pub exposure: f64,       // -1.0 to +1.0 (stops)
    pub softness: f64,       // 0.0 to 1.0 (brush edge feather)
    pub brush_size: f64,     // In pixels
    pub flow: f64,           // 0.0 to 1.0 (build-up rate)
    pub density: f64,       // 0.0 to 1.0 (max opacity per stroke)
    pub is_luminosity_mask: bool, // Protect hue/sat in color DB
    pub strokes: Vec<BrushStroke>,
}

/// Dodge & burn mode
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum DodgeBurnMode {
    Dodge,      // Lighten
    Burn,       // Darken
    Sponge,     // Saturation adjust (desaturate / saturate)
    Midtone,    // Target midtones only
    Highlight,  // Target highlights only
    Shadow,     // Target shadows only
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
    pub pressure_data: Option<Vec<f64>>, // Per-point pressure
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
