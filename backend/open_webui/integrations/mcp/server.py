"""
Model Context Protocol (MCP) Server for Open Connect
Provides standardized interface for AI agents and tools
"""

import json
import logging
import asyncio
from typing import Any, Optional, Dict, List, Callable
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime

log = logging.getLogger(__name__)


class ContentType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    RESOURCE = "resource"
    TOOL_USE = "tool_use"
    TOOL_RESULT = "tool_result"
    ERROR = "error"


class Role(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"
    TOOL = "tool"


@dataclass
class TextContent:
    type: str = "text"
    text: str = ""


@dataclass
class ImageContent:
    type: str = "image"
    data: str = ""
    mimeType: str = "image/png"


@dataclass
class ToolCall:
    id: str
    name: str
    arguments: Dict[str, Any] = field(default_factory=dict)


@dataclass
class ToolResult:
    toolUseId: str
    content: List[Any]
    isError: bool = False


@dataclass
class MCPMessage:
    role: Role
    content: List[Any]
    timestamp: datetime = field(default_factory=datetime.utcnow)


class MCPTool:
    """Base class for MCP tools"""
    
    def __init__(
        self,
        name: str,
        description: str,
        inputSchema: Dict[str, Any]
    ):
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    
    async def execute(self, **kwargs) -> Dict[str, Any]:
        """Execute the tool"""
        raise NotImplementedError


class MCPResource:
    """Base class for MCP resources"""
    
    def __init__(
        self,
        uri: str,
        name: str,
        description: str,
        mimeType: str = "text/plain"
    ):
        self.uri = uri
        self.name = name
        self.description = description
        self.mimeType = mimeType
    
    async def read(self) -> Any:
        """Read the resource"""
        raise NotImplementedError


class MCPServer:
    """
    Model Context Protocol Server for Open Connect
    Handles tool execution, resource management, and agent communication
    """
    
    def __init__(self, name: str = "open-connect"):
        self.name = name
        self.version = "1.0.0"
        self.tools: Dict[str, MCPTool] = {}
        self.resources: Dict[str, MCPResource] = {}
        self.prompts: Dict[str, Dict[str, Any]] = {}
        self._connected_clients: List[Any] = []
        
        # Initialize built-in tools
        self._register_builtin_tools()
        
        log.info(f"MCP Server '{name}' initialized")
    
    def _register_builtin_tools(self):
        """Register built-in Open Connect tools"""
        from open_webui.integrations.mcp.builtins import (
            WebSearchTool,
            CodeInterpreterTool,
            FileSystemTool,
            KnowledgeBaseTool,
            WebFetchTool,
        )
        
        # Register all built-in tools
        for tool_class in [
            WebSearchTool,
            CodeInterpreterTool,
            FileSystemTool,
            KnowledgeBaseTool,
            WebFetchTool,
        ]:
            tool = tool_class()
            self.register_tool(tool)
    
    def register_tool(self, tool: MCPTool):
        """Register a tool with the server"""
        self.tools[tool.name] = tool
        log.info(f"Registered tool: {tool.name}")
    
    def unregister_tool(self, name: str):
        """Unregister a tool"""
        if name in self.tools:
            del self.tools[name]
            log.info(f"Unregistered tool: {name}")
    
    def register_resource(self, resource: MCPResource):
        """Register a resource with the server"""
        self.resources[resource.uri] = resource
        log.info(f"Registered resource: {resource.uri}")
    
    def unregister_resource(self, uri: str):
        """Unregister a resource"""
        if uri in self.resources:
            del self.resources[uri]
            log.info(f"Unregistered resource: {uri}")
    
    def register_prompt(self, name: str, prompt: Dict[str, Any]):
        """Register a prompt template"""
        self.prompts[name] = prompt
        log.info(f"Registered prompt: {name}")
    
    async def list_tools(self) -> List[Dict[str, Any]]:
        """List all registered tools"""
        return [
            {
                "name": tool.name,
                "description": tool.description,
                "inputSchema": tool.inputSchema
            }
            for tool in self.tools.values()
        ]
    
    async def list_resources(self) -> List[Dict[str, Any]]:
        """List all registered resources"""
        return [
            {
                "uri": resource.uri,
                "name": resource.name,
                "description": resource.description,
                "mimeType": resource.mimeType
            }
            for resource in self.resources.values()
        ]
    
    async def list_prompts(self) -> List[Dict[str, Any]]:
        """List all registered prompts"""
        return list(self.prompts.values())
    
    async def call_tool(
        self,
        name: str,
        arguments: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Call a registered tool"""
        if name not in self.tools:
            return {
                "error": f"Tool '{name}' not found"
            }
        
        try:
            tool = self.tools[name]
            result = await tool.execute(**arguments)
            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(result, indent=2)
                    }
                ],
                "isError": False
            }
        except Exception as e:
            log.error(f"Tool execution error: {e}")
            return {
                "content": [
                    {
                        "type": "text",
                        "text": str(e)
                    }
                ],
                "isError": True
            }
    
    async def read_resource(self, uri: str) -> Dict[str, Any]:
        """Read a registered resource"""
        if uri not in self.resources:
            return {"error": f"Resource '{uri}' not found"}
        
        try:
            resource = self.resources[uri]
            data = await resource.read()
            return {
                "contents": [
                    {
                        "type": "resource",
                        "resource": {
                            "uri": resource.uri,
                            "mimeType": resource.mimeType,
                            "text": str(data)
                        }
                    }
                ]
            }
        except Exception as e:
            log.error(f"Resource read error: {e}")
            return {"error": str(e)}
    
    async def get_prompt(self, name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Get a prompt template with arguments"""
        if name not in self.prompts:
            return {"error": f"Prompt '{name}' not found"}
        
        prompt = self.prompts[name]
        # Process template variables
        template = prompt.get("template", "")
        for key, value in arguments.items():
            template = template.replace(f"{{{key}}}", str(value))
        
        return {
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": template}]
                }
            ]
        }
    
    def get_server_info(self) -> Dict[str, Any]:
        """Get server capabilities info"""
        return {
            "name": self.name,
            "version": self.version,
            "capabilities": {
                "tools": {
                    "listChanged": True
                },
                "resources": {
                    "subscribe": True,
                    "listChanged": True
                },
                "prompts": {
                    "listChanged": True
                }
            }
        }


# Global MCP server instance
_mcp_server: Optional[MCPServer] = None


def get_mcp_server() -> MCPServer:
    """Get the global MCP server instance"""
    global _mcp_server
    if _mcp_server is None:
        _mcp_server = MCPServer()
    return _mcp_server


def init_mcp_server(name: str = "open-connect") -> MCPServer:
    """Initialize the global MCP server"""
    global _mcp_server
    _mcp_server = MCPServer(name)
    return _mcp_server
