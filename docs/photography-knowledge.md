# Photography Knowledge — LUMOS Engine

Covers: exposure triangle, camera calibration, lens, sensor, DR, highlight/shadow recovery, WB, color temp, tint, ICC, ACES/OpenColorIO, film, distortion, CA, focus stack, panorama, HDR, bracketing, long exposure, astro, macro, studio, flash, tether, print, DAM.

Implemented in:

- `engine/color/pipeline.py` — ICC/ACES/OCIO, `ExposureTriangle.ev()`, `film_emulation()`
- `engine/raw/decoder.py` — LibRaw wrapper, `LensProfile.correct()`

Tests: `pytest tests/test_engine.py`
