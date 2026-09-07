//! Image Processing Operations
//! 
//! Defines all non-destructive image adjustment operations.

use serde::{Deserialize, Serialize};

/// A single image adjustment operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Operation {
    pub id: String,
    pub op_type: OperationType,
    pub enabled: bool,
    pub params: serde_json::Value,
}

/// Types of image operations
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OperationType {
    // Basic adjustments
    Exposure,
    Contrast,
    Highlights,
    Shadows,
    Whites,
    Blacks,
    
    // Tone curve
    ToneCurve,
    ParametricCurve,
    
    // Color
    WhiteBalance,
    Saturation,
    Vibrance,
    Hue,
    ColorMixer,
    Hsl,
    ColorGrading,
    Calibration,
    
    // Detail
    Sharpening,
    NoiseReduction,
    Defringe,
    
    // Optics
    LensCorrection,
    ChromaticAberration,
    Vignette,
    Grain,
    Defocus,
    
    // Geometry
    Crop,
    Rotate,
    Perspective,
    Distortion,
    
    // Local adjustments
    BrushMask,
    GradientMask,
    RadialMask,
    LuminanceRange,
    ColorRange,
    DodgeBurn,
    
    // AI operations
    AiMask,
    AiRelight,
    AiBackground,
    AiObjectRemoval,
    AiPortraitRetouch,
    AiSuperResolution,
    AiDenoise,
    AiDemosaic,
    
    // Effects
    Dehaze,
    Texture,
    Clarity,
    SplitTone,
    FilmGrain,
    PostCropVignette,
}

/// Exposure adjustment parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExposureParams {
    pub stops: f64, // -5.0 to +5.0
}

/// White balance parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WhiteBalanceParams {
    pub temperature: f64, // 2000-50000 Kelvin
    pub tint: f64,        // -150 to +150
}

/// Tone curve parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToneCurveParams {
    pub control_points: Vec<CurvePoint>,
    pub channel: CurveChannel,
}

/// A single curve control point
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CurvePoint {
    pub input: f64,  // 0.0 to 1.0
    pub output: f64, // 0.0 to 1.0
}

/// Curve channel
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CurveChannel {
    Luminance,
    Red,
    Green,
    Blue,
    Rgb,
}

/// HSL adjustment parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HslParams {
    pub hue_shift: f64,        // -180 to +180
    pub saturation: f64,       // -100 to +100
    pub lightness: f64,        // -100 to +100
    pub color_range: ColorRange,
}

/// Color range for targeted adjustments
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColorRange {
    pub center: f64,  // 0-360 hue
    pub width: f64,   // 0-180
    pub feather: f64, // 0-100
}

/// Sharpening parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SharpeningParams {
    pub amount: f64,  // 0-150
    pub radius: f64,  // 0.5-3.0
    pub detail: f64,  // 0-100
    pub masking: f64, // 0-100
}

/// Noise reduction parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoiseReductionParams {
    pub luminance: f64,    // 0-100
    pub color: f64,        // 0-100
    pub detail: f64,       // 0-100
    pub color_smoothness: f64, // 0-100
}

/// Lens correction parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LensCorrectionParams {
    pub profile_id: Option<String>,
    pub distortion: f64,     // -100 to +100
    pub defringe: f64,       // 0-100
    pub vignetting: f64,     // -100 to +100
}

/// Vignette parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VignetteParams {
    pub amount: f64,     // -100 to +100
    pub midpoint: f64,   // 0-100
    pub roundness: f64,  // -100 to +100
    pub feather: f64,    // 0-100
    pub highlights: f64, // 0-100
}

/// AI portrait retouching parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiPortraitParams {
    pub skin_smoothing: f64,    // 0-100
    pub skin_texture: f64,     // 0-100 (texture preservation)
    pub eye_brighten: f64,     // 0-100
    pub eye_enhance: f64,      // 0-100
    pub teeth_whiten: f64,     // 0-100
    pub lip_enhance: f64,      // 0-100
    pub face_slim: f64,        // 0-100
    pub acne_remove: bool,
    pub wrinkle_reduce: f64,   // 0-100
    pub under_eye_reduce: f64, // 0-100
}

/// AI background generation parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiBackgroundParams {
    pub mode: BackgroundMode,
    pub prompt: Option<String>,
    pub style_preset: Option<String>,
    pub reference_image_id: Option<String>,
    pub lighting_match: f64, // 0-100
    pub perspective_match: f64, // 0-100
}

/// Background generation mode
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum BackgroundMode {
    Remove,
    Replace,
    Generate,
    Transparent,
}

/// AI object removal parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiRemovalParams {
    pub mask_data: String, // base64 encoded mask
    pub fill_method: FillMethod,
    pub semantic_hint: Option<String>,
}

/// Fill method for object removal
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FillMethod {
    AiGenerate,
    Clone,
    Heal,
    ContentAware,
}

/// AI relighting parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiRelightParams {
    pub light_direction: f64,  // 0-360 degrees
    pub light_intensity: f64,  // 0-100
    pub light_temperature: f64, // 2000-10000 Kelvin
    pub light_softness: f64,   // 0-100
    pub add_rim_light: bool,
    pub rim_intensity: f64,    // 0-100
}

/// Super resolution parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SuperResolutionParams {
    pub scale: u32, // 2 or 4
    pub denoise_strength: f64, // 0-100
    pub sharpen: bool,
}

/// Demosaic parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DemosaicParams {
    pub algorithm: DemosaicAlgorithm,
    pub noise_reduction: f64, // 0-100
}

/// Demosaic algorithm
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DemosaicAlgorithm {
    Bilinear,
    Ahd,
    Lmmse,
    Dcb,
    Amaze,
    Rcd,
    Xtrans,
}
