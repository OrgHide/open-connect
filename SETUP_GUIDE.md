# Open Connect - Setup Guide

## Overview

Open Connect is a self-hosted AI interface built on Open WebUI, deployed on Railway with the following features:
- **AI Chat Interface**: Access to multiple free AI models
- **Knowledge Base**: RAG (Retrieval-Augmented Generation) support with Qdrant vector database
- **Code Execution**: Run Python code directly in chat
- **Web Search**: Search the web from within the chat interface
- **Mobile PWA**: Install as an app on Android and iOS

---

## Quick Access

**Live URL**: https://open-connect-production.up.railway.app

---

## Authentication

| Setting | Value |
|---------|-------|
| Auth Enabled | Yes |
| Signups | Enabled |
| JWT Expiration | 4 weeks |

### Default Admin User
- **Username**: charles
- **Password**: (as configured)

---

## Features Enabled

| Feature | Status | Description |
|---------|--------|-------------|
| Web Search | Enabled | Search the web from chat |
| Code Execution | Enabled | Run Python code in chat |
| Code Interpreter | Enabled | Advanced code execution with pyodide |
| Memories | Enabled | Persistent user memories |
| Notes | Enabled | Take notes |
| Automations | Enabled | Workflow automations |
| Message Rating | Enabled | Rate AI responses |
| API Keys | Enabled | Generate API keys for external use |
| User Signups | Enabled | Allow new user registrations |
| Hybrid Search | Enabled | Combined vector + keyword search |
| Direct Connections | Enabled | Connect to external model APIs |
| Model Caching | Enabled | Cache model lists |
| Speech-to-Text | Enabled | Whisper for voice input |

---

## AI Models (Free Tier)

Open Connect is pre-configured with these free OpenRouter models:

| Model | Description | Best For |
|-------|-------------|----------|
| `google/gemma-3-4b-it` | Fast, efficient | General chat |
| `qwen/qwen-2.5-7b-instruct` | Good quality | Coding, analysis |
| `microsoft/phi-4` | Reasoning | Complex tasks |
| `deepseek/deepseek-r1` | Deep reasoning | Math, logic |
| `anthropic/claude-3.5-haiku` | Fast Claude | Quick tasks |
| `meta/llama-3.1-8b-instruct` | Open-source | General use |

---

## Environment Variables

| Variable | Description | Status |
|----------|-------------|--------|
| `OPENAI_API_KEY` | OpenRouter API key | Configured |
| `OPENAI_API_BASE_URL` | OpenRouter endpoint | Configured |
| `HUGGINGFACE_TOKEN` | Hugging Face token | Configured |
| `GROQ_API_KEY` | Groq API key | Configured |
| `WEBUI_SECRET_KEY` | Session encryption | Configured |
| `DEFAULT_MODELS` | Pre-selected models | Configured |
| `ENV` | Environment | Set to prod |
| `PORT` | Application port | Set to 8080 |
| `DOCKER` | Docker mode | Enabled |
| `SUPABASE_URL` | Supabase project URL | Configured |
| `SUPABASE_ANON_KEY` | Supabase anon key | Configured |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role | Configured |
| `QDRANT_URL` | Qdrant vector DB URL | Configured |
| `QDRANT_API_KEY` | Qdrant API key | Configured |

### Database & Vector Store

**SQLite** (Default) - Used for:
- User data storage
- Chat history
- Application metadata

**Qdrant Vector Database** - Used for:
- Semantic search embeddings
- Knowledge base vector storage
- Retrieval-augmented generation (RAG)

**Supabase** (Optional) - Can be configured via admin panel:
- External knowledge base sources
- Additional data storage

---

## Backup & Migration

### Automated Backup
Backup scripts are available in `scripts/backup/`:
- `auto-backup.sh` - Universal backup script
- `railway-backup.sh` - Railway-specific backup with environment variable support

### Manual Backup
```bash
# Backup SQLite database
sqlite3 data/webui.db ".backup 'backup.db'"

# Backup uploaded files
tar -czf uploads.tar.gz backend/open_webui/static/uploads/
```

### Restore from Backup
```bash
# Restore database
sqlite3 data/webui.db ".restore 'backup.db'"

# Restore uploads
tar -xzf uploads.tar.gz
```

---

## Mobile Installation

See [MOBILE_GUIDE.md](./MOBILE_GUIDE.md) for detailed installation instructions for Android and iOS.

### Quick Install
1. Open https://open-connect-production.up.railway.app in mobile browser
2. Tap "Add to Home Screen" / "Install App"
3. The app will appear as a native-like application

---

## Troubleshooting

### Health Check Failures
If deployment fails with health check errors:
1. Check health endpoint: `https://open-connect-production.up.railway.app/health`
2. Increase timeout if needed (current: 300s)

### Model Connection Issues
1. Verify API keys are set correctly in Railway dashboard
2. Check OpenRouter quota at https://openrouter.ai/account
3. Review logs in Railway dashboard

### Knowledge Base Not Working
1. Verify Qdrant credentials in Railway dashboard
2. Check Qdrant cloud status
3. Ensure hybrid search is enabled

---

## Support

- **GitHub**: https://github.com/OrgHide/open-connect
- **Documentation**: https://docs.openwebui.com/
