"""
Open Connect Integrations
Unified integration framework for AI agents, skills, and platforms
"""

from open_webui.integrations.mcp import (
    MCPServer,
    get_mcp_server,
    init_mcp_server,
    MCPTool,
    MCPResource,
)

from open_webui.integrations.agents.framework import (
    AgentHub,
    get_agent_hub,
    BaseAgent,
    AgentConfig,
    AgentType,
    OpenAIAgent,
    LangGraphAgent,
    OpenClawConnector,
    SwarmDockConnector,
)

from open_webui.integrations.skills.manager import (
    SkillManager,
    get_skill_manager,
    Skill,
    SkillSource,
    SkillsLLMConnector,
    ClawHubConnector,
    AgencyAgentsConnector,
)

from open_webui.integrations.agents.pipe import (
    Pipe,
    OpenAIPipe,
    AgentPipe,
    MCPPipe,
    get_pipe,
)

__all__ = [
    # MCP
    "MCPServer",
    "get_mcp_server",
    "init_mcp_server",
    "MCPTool",
    "MCPResource",
    # Agents
    "AgentHub",
    "get_agent_hub",
    "BaseAgent",
    "AgentConfig",
    "AgentType",
    "OpenAIAgent",
    "LangGraphAgent",
    "OpenClawConnector",
    "SwarmDockConnector",
    # Skills
    "SkillManager",
    "get_skill_manager",
    "Skill",
    "SkillSource",
    "SkillsLLMConnector",
    "ClawHubConnector",
    "AgencyAgentsConnector",
    # Pipes
    "Pipe",
    "OpenAIPipe",
    "AgentPipe",
    "MCPPipe",
    "get_pipe",
]


def init_integrations():
    """Initialize all integrations"""
    from open_webui.integrations.mcp import init_mcp_server
    from open_webui.integrations.skills.manager import get_skill_manager
    
    # Initialize MCP server
    init_mcp_server("open-connect")
    
    # Initialize skill manager
    get_skill_manager()
    
    # Initialize agent hub
    get_agent_hub()
