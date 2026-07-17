# XStack - AI Resource Manager for Open-Connect

## 🎯 Vision & Core Concept

**XStack is the control plane of Open-Connect, not another plugin manager.**

Users do not install Skills, Tools, Agents, or MCP servers into Open-Connect. Instead, they connect them once, and every AI client consumes them through the Open-Connect Gateway.

### ✅ Core Principles
- **Connect Once, Use Everywhere**: Resources stay at their source
- **No Installation**: No downloading or copying into Open-Connect
- **Gateway-Centric**: All AI clients consume through a single gateway
- **Resource Discovery**: Find and connect resources from multiple sources
- **Unified Access**: Standardized interface for all resource types

## 🚀 Quick Start

### Installation

```bash
cd xstack
npm install
cp .env.example .env
npm start
```

### Docker

```bash
docker-compose up -d
```

## 📋 Available Chat Commands

### Navigation
- `/open_xstack` - Open XStack Dashboard
- `/open_resources` - Open Resources Page
- `/open_connections` - Open Connections Page
- `/open_marketplace` - Open Marketplace
- `/open_secret` - Open Secrets Management

### Resources
- `/list_resources` - List all resources
- `/search_resources?q=query` - Search resources

### Connections
- `/list_connections` - List all connections
- `/add_connection` - Add new connection

## 🔗 Pre-Configured External Connections

XStack comes with pre-configured connections to:

- **OpenClaw** (https://openclaw.ai/)
- **SwarmClaw** (https://www.swarmclaw.ai/)
- **SwarmDock** (https://www.swarmdock.ai/)
- **SkillsLLM** (https://skillsllm.com/)
- **AgentField** (https://agentfield.ai/)
- **Agency Agents** (https://agencyagents.dev/)
- **ClawHub** (https://clawhub.ai/)
- **MultiOn** (https://docs.multion.ai/)
- **Omni** (https://omni.co/)
- **Open Agent** (https://app.open-agent.io/)

## 🏗️ Architecture

The XStack architecture implements a gateway pattern where:

1. **Resources stay at their source** - No installation or copying
2. **Single point of connection** - Connect once, use everywhere
3. **Unified access** - All AI clients consume through the gateway
4. **Centralized management** - Secrets, connections, and resources in one place

## 📚 API Documentation

### Main Endpoints
- `/api/v1/resources` - Resource management
- `/api/v1/connections` - Connection management
- `/api/v1/marketplace` - Marketplace discovery
- `/api/v1/secrets` - Secrets management
- `/api/v1/gateway` - Gateway status and config
- `/api/v1/mcp` - MCP server routing

## 🤝 Contributing

Contributions welcome! Please fork and create pull requests.

## 📄 License

MIT License

---

**XStack - The Control Plane for AI Resources**