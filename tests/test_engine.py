def test_color_pipeline():
    from engine.color.pipeline import ColorPipeline, ExposureTriangle
    p = ColorPipeline()
    assert p.transform(b"pixels", "sRGB", "ACEScg")["working"] == "ACEScg"
    assert p.film_emulation(b"p", "Portra 400")["emulated"]
    ev = ExposureTriangle(aperture=2.8, shutter=1/250, iso=100)
    assert ev.is_valid()
    assert abs(ev.ev() - 11) < 1

def test_raw_decoder():
    from engine.raw.decoder import RawDecoder
    d = RawDecoder()
    assert "DNG" in d.supported_formats()
    res = d.decode("test.dng")
    assert res["decoded"]
    try:
        d.decode("test.jpg")
        assert False
    except ValueError:
        pass

def test_runtime():
    from engine.ai.model_runtime.runtime import ModelRunner, ModelSpec, Runtime
    spec = ModelSpec(id="test", runtime=Runtime.onnx, path="/tmp/model.onnx", input_shape=(1,3,224,224))
    r = ModelRunner(spec).load()
    out = r.infer(None)
    assert out["runtime"] == "onnx"
    assert Runtime.onnx.value in ModelRunner.list_runtimes()
