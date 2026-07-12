# Open Connect 👋

![GitHub stars](https://img.shields.io/github/stars/OrgHide/open-connect?style=social)
![GitHub forks](https://img.shields.io/github/forks/OrgHide/open-connect?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/OrgHide/open-connect?style=social)
![GitHub repo size](https://img.shields.io/github/repo-size/OrgHide/open-connect)
![GitHub language count](https://img.shields.io/github/languages/count/OrgHide/open-connect)
![GitHub top language](https://img.shields.io/github/languages/top/OrgHide/open-connect)
![GitHub last commit](https://img.shields.io/github/last-commit/OrgHide/open-connect?color=red)

![Open Connect Banner](./banner.png)

**Open Connect is a powerful, self-hosted AI platform** built on Open WebUI, designed to provide **full control over your AI infrastructure** with enterprise-grade features. It supports various LLM runners like **Ollama** and **OpenAI-compatible APIs** (including OpenRouter with Google Vertex AI), with **built-in RAG support**, making it a **complete AI deployment solution**.

![Open Connect Demo](./demo.png)

## Live Deployment

🚀 **Production URL**: https://open-connect-production.up.railway.app

## Key Features of Open Connect ⭐

- 🚀 **Effortless Setup**: Production-ready deployment on Railway with Docker
- 🤝 **Broad Model & API Integration**: Connect any OpenAI-compatible API alongside local Ollama models. Point the API URL at **OpenRouter, GroqCloud, Mistral, LMStudio, vLLM, and more** to mix and match providers freely.
- 🔐 **Authentication & RBAC**: User registration, login, and role-based access control with JWT tokens
- 🧩 **Plugin Support**: Extend Open Connect with **Filters**, **Actions**, **Pipes**, **Tools**, and **Skills**
- 🤖 **Models & Agents**: Wrap any base model with custom instructions, tools, and knowledge to build specialized agents
- 📝 **Notes**: A dedicated workspace for content outside conversations with rich editor support
- 🧠 **Persistent Memory**: The AI remembers facts about you across conversations
- 📱 **Responsive Design & PWA**: Seamless experience across desktop, laptop, and mobile with installable app support
- ✒️ **Full Markdown and LaTeX Support**: Comprehensive Markdown and LaTeX capabilities
- 🎤 **Voice Input**: Built-in Whisper-based speech-to-text
- 💾 **Flexible Database**: SQLite (default) or PostgreSQL/Supabase for production
- 🧬 **Vector Database Support**: ChromaDB, Qdrant, and other vector stores for RAG
- 🔍 **Web Search**: Search the web and inject results directly into conversations
- 💻 **Code Execution**: Run Python code in chat with built-in interpreter
- 🔑 **API Keys**: Generate API keys for external integrations
- 📁 **Folders & Organization**: Organize chats, files, and knowledge bases
- ⚡ **Automations**: Schedule prompts and automate workflows
- ⭐ **Message Rating**: Rate AI responses to improve conversation quality
- ⚖️ **Horizontal Scalability**: Redis-backed session management and WebSocket support
- 🌐🌍 **Multilingual Support**: Use Open Connect in your preferred language with i18n support
- 🌟 **Continuous Updates**: Regular updates, fixes, and new features
- 🛡️ **Security**: Built with security best practices

## Quick Start 🚀

### Using the Live Deployment

Visit **https://open-connect-production.up.railway.app** to use the live deployment.

### Using Docker Compose

1. Clone the repository:
   ```bash
   git clone https://github.com/OrgHide/open-connect.git
   cd open-connect
   ```

2. Create a `.env` file based on `.env.example`

3. Start with Docker Compose:
   ```bash
   docker-compose up -d
   ```

4. Access at http://localhost:3000

### Railway Deployment

The application is deployed on Railway with automatic health checks and scaling.

For the canonical setup map and where each piece lives, see [docs/deployment-map.md](./docs/deployment-map.md).

## Configuration

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed configuration instructions.

## Human-friendly deployment reference

If you are trying to understand the full setup quickly, use the deployment map first. It explains:

- which file is the source of truth for runtime behavior
- where secrets belong
- how the startup bootstrap avoids resetting the workspace on every deploy
- which workflow is the automation entrypoint

Related docs:
- [docs/deployment-map.md](./docs/deployment-map.md)
- [docs/supabase-auth.md](./docs/supabase-auth.md)
- [docs/canonical-workflow.md](./docs/canonical-workflow.md)

## Documentation

For more information, check out the [Open WebUI Documentation](https://docs.openwebui.com/).

## Troubleshooting

For troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) or the [Open WebUI Documentation](https://docs.openwebui.com/troubleshooting/).

## License

This project is based on [Open WebUI](https://github.com/open-webui/open-webui) and maintains its open-source license.

## Support 💬

If you have any questions, suggestions, or need assistance, please open an issue on GitHub or join our community!
