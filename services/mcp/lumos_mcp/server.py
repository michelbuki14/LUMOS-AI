"""
LUMOS MCP — Python server (mirrors Dart package)
JSON-RPC 2.0 over stdio / HTTP+SSE. Permission-aware.
"""
import json
import sys
import asyncio
from typing import Any, Dict, List, Optional

class McpTool:
    name: str = ""
    description: str = ""
    input_schema: Dict[str, Any] = {}
    required_permissions: List[str] = ["read"]

    async def invoke(self, args: Dict[str, Any], perms: List[str]) -> Dict[str, Any]:
        raise NotImplementedError

    def definition(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "inputSchema": self.input_schema,
            "permissions": self.required_permissions,
        }

    def assert_perms(self, perms: List[str]):
        for p in self.required_permissions:
            if p not in perms:
                raise PermissionError(f"Tool {self.name} requires {self.required_permissions}, granted {perms}")

# ── Tools ──
class CatalogTool(McpTool):
    name = "catalog.list"
    description = "List catalog assets"
    input_schema = {"type": "object", "properties": {"query": {"type": "string"}, "limit": {"type": "integer"}}, "required": []}
    async def invoke(self, args, perms):
        self.assert_perms(perms)
        return {"assets": [], "query": args.get("query")}

class ExifTool(McpTool):
    name = "exif.get"
    description = "Read EXIF/XMP/IPTC"
    input_schema = {"type": "object", "properties": {"assetId": {"type": "string"}}, "required": ["assetId"]}
    async def invoke(self, args, perms):
        self.assert_perms(perms)
        # real: use exiftool / pillow exif
        return {"exif": {}, "assetId": args["assetId"]}

class RawTool(McpTool):
    name = "raw.decode"
    description = "Decode RAW via LibRaw/OpenImageIO"
    input_schema = {"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"]}
    required_permissions = ["read", "filesystem"]
    async def invoke(self, args, perms):
        self.assert_perms(perms)
        return {"decoded": True, "path": args["path"]}

class BatchTool(McpTool):
    name = "batch.enqueue"
    description = "Enqueue batch jobs"
    input_schema = {"type": "object", "properties": {"jobs": {"type": "array"}}, "required": ["jobs"]}
    required_permissions = ["write"]
    async def invoke(self, args, perms):
        self.assert_perms(perms)
        return {"enqueued": len(args.get("jobs", []))}

class ColorTool(McpTool):
    name = "color.profile.list"
    description = "List ICC/ACES/OCIO profiles"
    input_schema = {"type": "object", "properties": {}, "required": []}
    async def invoke(self, args, perms):
        self.assert_perms(perms)
        return {"profiles": ["sRGB", "AdobeRGB", "ACEScg", "Rec.2020"]}

class FaceTool(McpTool):
    name = "ai.face.detect"
    description = "Face detection"
    input_schema = {"type": "object", "properties": {"assetId": {"type": "string"}}, "required": ["assetId"]}
    async def invoke(self, args, perms):
        self.assert_perms(perms)
        return {"faces": []}

DEFAULT_TOOLS = [CatalogTool(), ExifTool(), RawTool(), BatchTool(), ColorTool(), FaceTool()]

class LumosMcpServer:
    def __init__(self, tools: Optional[List[McpTool]] = None, perms: Optional[List[str]] = None):
        self.tools = {t.name: t for t in (tools or DEFAULT_TOOLS)}
        self.default_perms = perms or ["read"]

    async def handle(self, req: Dict[str, Any], perms: Optional[List[str]] = None) -> Dict[str, Any]:
        p = perms or self.default_perms
        method = req.get("method")
        rid = req.get("id", "1")
        try:
            if method == "initialize":
                return {"jsonrpc": "2.0", "id": rid, "result": {"serverInfo": {"name": "lumos-mcp-py", "version": "0.1.0"}, "capabilities": {"tools": {}}, "protocolVersion": "2024-11-05"}}
            if method == "tools/list":
                return {"jsonrpc": "2.0", "id": rid, "result": {"tools": [t.definition() for t in self.tools.values()]}}
            if method == "tools/call":
                params = req.get("params", {})
                name = params.get("name")
                args = params.get("arguments", {})
                tool = self.tools.get(name)
                if not tool:
                    raise ValueError(f"Unknown tool {name}")
                result = await tool.invoke(args, p)
                return {"jsonrpc": "2.0", "id": rid, "result": {"content": [{"type": "text", "text": json.dumps(result)}]}}
            return {"jsonrpc": "2.0", "id": rid, "error": {"code": -32601, "message": f"Method not found {method}"}}
        except Exception as e:
            return {"jsonrpc": "2.0", "id": rid, "error": {"code": -32603, "message": str(e)}}

    async def serve_stdio(self):
        loop = asyncio.get_event_loop()
        reader = asyncio.StreamReader()
        protocol = asyncio.StreamReaderProtocol(reader)
        await loop.connect_read_pipe(lambda: protocol, sys.stdin)
        while True:
            line = await reader.readline()
            if not line:
                break
            if not line.strip():
                continue
            req = json.loads(line)
            resp = await self.handle(req)
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()

if __name__ == "__main__":
    s = LumosMcpServer()
    asyncio.run(s.serve_stdio())
