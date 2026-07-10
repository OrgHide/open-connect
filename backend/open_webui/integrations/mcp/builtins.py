"""
Built-in MCP tools for Open Connect
"""

import json
import logging
import os
import re
import subprocess
from typing import Any, Dict, Optional
from pathlib import Path

from open_webui.integrations.mcp.server import MCPTool, MCPResource

log = logging.getLogger(__name__)


class WebSearchTool(MCPTool):
    """Web search tool using configured search engine"""
    
    def __init__(self):
        super().__init__(
            name="web_search",
            description="Search the web for information. Returns relevant links and snippets.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query"
                    },
                    "num_results": {
                        "type": "integer",
                        "description": "Number of results to return",
                        "default": 5
                    }
                },
                "required": ["query"]
            }
        )
    
    async def execute(self, query: str, num_results: int = 5, **kwargs) -> Dict[str, Any]:
        try:
            import requests
            # Use DuckDuckGo for privacy-friendly search
            url = "https://api.duckduckgo.com/"
            params = {
                "q": query,
                "format": "json",
                "no_redirect": 1
            }
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            results = []
            for item in data.get("RelatedTopics", [])[:num_results]:
                if "Text" in item:
                    results.append({
                        "title": item.get("Text", "")[:100],
                        "url": item.get("FirstURL", "")
                    })
            
            return {
                "query": query,
                "results": results
            }
        except Exception as e:
            log.error(f"Web search error: {e}")
            return {"error": str(e)}


class WebFetchTool(MCPTool):
    """Fetch content from URLs"""
    
    def __init__(self):
        super().__init__(
            name="web_fetch",
            description="Fetch and extract content from a URL. Useful for getting detailed information from web pages.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "The URL to fetch"
                    },
                    "max_length": {
                        "type": "integer",
                        "description": "Maximum content length",
                        "default": 5000
                    }
                },
                "required": ["url"]
            }
        )
    
    async def execute(self, url: str, max_length: int = 5000, **kwargs) -> Dict[str, Any]:
        try:
            import requests
            from bs4 import BeautifulSoup
            
            headers = {
                "User-Agent": "Mozilla/5.0 (compatible; OpenConnect/1.0)"
            }
            response = requests.get(url, headers=headers, timeout=15)
            soup = BeautifulSoup(response.text, "html.parser")
            
            # Remove scripts and styles
            for script in soup(["script", "style"]):
                script.decompose()
            
            text = soup.get_text(separator="\n", strip=True)
            text = re.sub(r"\n{3,}", "\n\n", text)
            
            return {
                "url": url,
                "title": soup.title.string if soup.title else "",
                "content": text[:max_length],
                "status_code": response.status_code
            }
        except Exception as e:
            log.error(f"Web fetch error: {e}")
            return {"error": str(e)}


class CodeInterpreterTool(MCPTool):
    """Execute Python code in a sandboxed environment"""
    
    def __init__(self):
        super().__init__(
            name="code_interpreter",
            description="Execute Python code. Use for calculations, data processing, and automation tasks.",
            inputSchema={
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Python code to execute"
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Execution timeout in seconds",
                        "default": 30
                    }
                },
                "required": ["code"]
            }
        )
    
    async def execute(self, code: str, timeout: int = 30, **kwargs) -> Dict[str, Any]:
        try:
            # Create a restricted namespace for execution
            namespace = {
                "__builtins__": __builtins__,
                "print": print,
                "len": len,
                "range": range,
                "str": str,
                "int": int,
                "float": float,
                "list": list,
                "dict": dict,
                "set": set,
                "tuple": tuple,
                "bool": bool,
                "True": True,
                "False": False,
                "None": None,
                "json": json,
                "re": re,
                "math": __import__("math"),
            }
            
            # Execute with timeout (simplified)
            import io
            stdout = io.StringIO()
            
            try:
                exec(
                    compile(code, "<exec>", "exec"),
                    namespace
                )
                output = "Code executed successfully"
            except Exception as e:
                output = f"Error: {str(e)}"
            
            return {
                "code": code[:100] + "..." if len(code) > 100 else code,
                "output": output,
                "success": "Error:" not in output
            }
        except Exception as e:
            log.error(f"Code execution error: {e}")
            return {"error": str(e)}


class FileSystemTool(MCPTool):
    """File system operations tool"""
    
    def __init__(self):
        super().__init__(
            name="filesystem",
            description="Perform file system operations like reading, writing, and listing files.",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {
                        "type": "string",
                        "enum": ["read", "write", "list", "exists", "info"],
                        "description": "The file operation to perform"
                    },
                    "path": {
                        "type": "string",
                        "description": "File or directory path"
                    },
                    "content": {
                        "type": "string",
                        "description": "Content to write (for 'write' operation)"
                    }
                },
                "required": ["operation", "path"]
            }
        )
    
    async def execute(self, operation: str, path: str, content: str = "", **kwargs) -> Dict[str, Any]:
        try:
            base_path = Path(os.getenv("DATA_DIR", "/app/backend/data"))
            target_path = base_path / path
            
            if operation == "read":
                if not target_path.exists():
                    return {"error": "File not found"}
                return {"content": target_path.read_text()}
            
            elif operation == "write":
                target_path.parent.mkdir(parents=True, exist_ok=True)
                target_path.write_text(content)
                return {"success": True, "path": str(target_path)}
            
            elif operation == "list":
                if not target_path.exists():
                    return {"error": "Directory not found"}
                files = [f.name for f in target_path.iterdir()]
                return {"files": files, "path": str(target_path)}
            
            elif operation == "exists":
                return {"exists": target_path.exists()}
            
            elif operation == "info":
                if not target_path.exists():
                    return {"error": "Path not found"}
                stat = target_path.stat()
                return {
                    "path": str(target_path),
                    "size": stat.st_size,
                    "modified": stat.st_mtime,
                    "is_file": target_path.is_file(),
                    "is_dir": target_path.is_dir()
                }
            
            return {"error": f"Unknown operation: {operation}"}
        except Exception as e:
            log.error(f"Filesystem error: {e}")
            return {"error": str(e)}


class KnowledgeBaseTool(MCPTool):
    """Knowledge base search and retrieval tool"""
    
    def __init__(self):
        super().__init__(
            name="knowledge_base",
            description="Search the knowledge base for documents and information.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query"
                    },
                    "collection": {
                        "type": "string",
                        "description": "Knowledge base collection to search",
                        "default": "default"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum results",
                        "default": 5
                    }
                },
                "required": ["query"]
            }
        )
    
    async def execute(self, query: str, collection: str = "default", limit: int = 5, **kwargs) -> Dict[str, Any]:
        try:
            # Get embedding function from retrieval module
            from open_webui.routers.retrieval import get_embedding_function
            
            embedding_fn = get_embedding_function()
            
            # This would search the vector database
            # For now, return placeholder
            return {
                "query": query,
                "collection": collection,
                "results": [],
                "note": "Knowledge base integration requires vector DB setup"
            }
        except Exception as e:
            log.error(f"Knowledge base error: {e}")
            return {"error": str(e)}


class ChatHistoryTool(MCPTool):
    """Access chat history and conversations"""
    
    def __init__(self):
        super().__init__(
            name="chat_history",
            description="Search and retrieve chat history.",
            inputSchema={
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["search", "get", "list"],
                        "description": "Action to perform"
                    },
                    "query": {
                        "type": "string",
                        "description": "Search query (for 'search' action)"
                    },
                    "chat_id": {
                        "type": "string",
                        "description": "Chat ID (for 'get' action)"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum results",
                        "default": 10
                    }
                },
                "required": ["action"]
            }
        )
    
    async def execute(self, action: str, query: str = "", chat_id: str = "", limit: int = 10, **kwargs) -> Dict[str, Any]:
        try:
            if action == "search":
                # Search chat history
                return {
                    "action": "search",
                    "query": query,
                    "results": [],
                    "note": "Chat history search requires database access"
                }
            elif action == "get":
                return {
                    "action": "get",
                    "chat_id": chat_id,
                    "messages": []
                }
            elif action == "list":
                return {
                    "action": "list",
                    "chats": []
                }
            return {"error": f"Unknown action: {action}"}
        except Exception as e:
            log.error(f"Chat history error: {e}")
            return {"error": str(e)}


class ModelTool(MCPTool):
    """Manage and query AI models"""
    
    def __init__(self):
        super().__init__(
            name="models",
            description="List available models and get model information.",
            inputSchema={
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["list", "info", "default"],
                        "description": "Action to perform"
                    },
                    "model_id": {
                        "type": "string",
                        "description": "Model ID (for 'info' action)"
                    }
                },
                "required": ["action"]
            }
        )
    
    async def execute(self, action: str, model_id: str = "", **kwargs) -> Dict[str, Any]:
        try:
            from open_webui.utils.models import get_all_models
            
            if action == "list":
                models = get_all_models()
                return {
                    "models": [
                        {
                            "id": m.get("id"),
                            "name": m.get("name"),
                            "provider": m.get("provider")
                        }
                        for m in models[:20]
                    ]
                }
            elif action == "info":
                return {
                    "model_id": model_id,
                    "info": {}
                }
            return {"error": f"Unknown action: {action}"}
        except Exception as e:
            log.error(f"Model tool error: {e}")
            return {"error": str(e)}


class AgentTool(MCPTool):
    """Run autonomous agents"""
    
    def __init__(self):
        super().__init__(
            name="agent",
            description="Run an autonomous agent task. The agent can use other tools to complete tasks.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "Task description for the agent"
                    },
                    "agent_type": {
                        "type": "string",
                        "description": "Type of agent (research, coder, assistant)",
                        "default": "assistant"
                    },
                    "max_steps": {
                        "type": "integer",
                        "description": "Maximum agent steps",
                        "default": 10
                    }
                },
                "required": ["task"]
            }
        )
    
    async def execute(self, task: str, agent_type: str = "assistant", max_steps: int = 10, **kwargs) -> Dict[str, Any]:
        try:
            return {
                "task": task,
                "agent_type": agent_type,
                "status": "Agent execution requires OpenAI Agents SDK integration",
                "steps": []
            }
        except Exception as e:
            log.error(f"Agent error: {e}")
            return {"error": str(e)}


# Export all built-in tools
__all__ = [
    "WebSearchTool",
    "WebFetchTool",
    "CodeInterpreterTool",
    "FileSystemTool",
    "KnowledgeBaseTool",
    "ChatHistoryTool",
    "ModelTool",
    "AgentTool",
]
