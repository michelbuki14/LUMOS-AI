"""
LUMOS AI — Model runtime abstraction
ONNX Runtime, PyTorch, TensorFlow, OpenVINO, DirectML, Core ML, TensorRT — interchangeable.
"""
from dataclasses import dataclass
from typing import Dict, Any
from enum import Enum

class Runtime(str, Enum):
    onnx = "onnx"
    pytorch = "pytorch"
    tensorflow = "tensorflow"
    openvino = "openvino"
    directml = "directml"
    coreml = "coreml"
    tensorrt = "tensorrt"

@dataclass
class ModelSpec:
    id: str
    runtime: Runtime
    path: str
    input_shape: tuple
    mean: tuple = (0.485, 0.456, 0.406)
    std: tuple = (0.229, 0.224, 0.225)

class ModelRunner:
    """One interface, many backends. Prefer ONNX for portability."""
    def __init__(self, spec: ModelSpec):
        self.spec = spec
        self.loaded = False

    def load(self):
        # real: ort.InferenceSession / torch.jit.load / tf.saved_model
        self.loaded = True
        return self

    def infer(self, tensor) -> Dict[str, Any]:
        if not self.loaded:
            self.load()
        # stub: deterministic mock
        return {"runtime": self.spec.runtime.value, "id": self.spec.id, "scores": [0.9, 0.05, 0.05]}

    @staticmethod
    def list_runtimes():
        return [r.value for r in Runtime]
