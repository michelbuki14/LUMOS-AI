"""
LUMOS Engine — RAW decode abstraction (LibRaw / OpenImageIO)
"""
from dataclasses import dataclass
from typing import Optional

@dataclass
class RawDecodeOptions:
    demosaic: str = "AHD"  # AHD, DCB, LMMSE, etc.
    highlight: str = "clip"  # clip, unclip, blend
    wb: str = "camera"  # camera, auto, daylight, custom
    color_space: str = "ACEScg"
    half_size: bool = False

class RawDecoder:
    """Thin wrapper over LibRaw. CPU, deterministic. Tests use tiny DNG fixtures."""
    def __init__(self, libraw_available: bool = True):
        self.libraw_available = libraw_available

    def decode(self, path: str, opts: Optional[RawDecodeOptions] = None) -> dict:
        opts = opts or RawDecodeOptions()
        # real: libraw_open_file + dcraw_process
        # stub: return metadata, keeps pipeline testable without binary
        if not path.lower().endswith((".cr2",".cr3",".nef",".arw",".raf",".dng",".orf",".rw2")):
            raise ValueError(f"Unsupported RAW {path}")
        return {"path": path, "opts": opts.__dict__, "decoded": True, "width": 6000, "height": 4000, "bands": 3}

    def supported_formats(self):
        return ["CR2","CR3","NEF","ARW","RAF","DNG","ORF","RW2","DNG","TIFF","OpenEXR"]

@dataclass
class LensProfile:
    make: str
    model: str
    distortion_k1: float = 0.0
    vignetting: float = 0.0
    ca_red: float = 0.0
    ca_blue: float = 0.0

    def correct(self, pixels):
        return {"corrected": True, "k1": self.distortion_k1}
