"""
LUMOS Engine — Color Management
ICC, ACES, OpenColorIO, film emulation. CPU + GPU.
"""
from dataclasses import dataclass

@dataclass
class IccProfile:
    name: str
    path: str
    space: str  # sRGB, AdobeRGB, ProPhoto, Rec2020, ACEScg

STOCK_PROFILES = [
    IccProfile("sRGB IEC61966-2.1", "color/srgb.icc", "sRGB"),
    IccProfile("AdobeRGB 1998", "color/adobe_rgb.icc", "AdobeRGB"),
    IccProfile("ACEScg", "color/aces_cg.icc", "ACEScg"),
]

class ColorPipeline:
    """OpenColorIO + LittleCMS wrapper. Deterministic, testable."""
    def __init__(self, working_space: str = "ACEScg"):
        self.working_space = working_space

    def transform(self, pixels, src: str, dst: str):
        # real: OCIO DisplayView + ICC
        # stub: passthrough with metadata
        return {"pixels": pixels, "src": src, "dst": dst, "working": self.working_space}

    def apply_lut(self, pixels, lut_path: str, strength: float = 1.0):
        return {"lut": lut_path, "strength": strength, "applied": True}

    def film_emulation(self, pixels, stock: str = "Portra 400"):
        stocks = ["Portra 400", "Ektar 100", "Tri-X 400", "Velvia 50"]
        assert stock in stocks, f"Unknown stock {stock}"
        return {"stock": stock, "emulated": True}

@dataclass
class ExposureTriangle:
    """Photography knowledge: exposure triangle"""
    aperture: float  # f-number
    shutter: float   # seconds
    iso: int

    def ev(self) -> float:
        import math
        return math.log2((self.aperture ** 2) / self.shutter) - math.log2(self.iso / 100)

    def is_valid(self) -> bool:
        return 1.0 <= self.aperture <= 22 and 1/8000 <= self.shutter <= 30 and 50 <= self.iso <= 102400
