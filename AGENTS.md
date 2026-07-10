# Open Connect - AI Agent Knowledge Base

## Project Overview

**Open Connect** is a rebranded version of Open WebUI, a comprehensive AI interface platform that provides:
- Chat interface for AI models
- Knowledge base management
- Function calling and tools
- Model management with multiple provider support
- Multi-user support with authentication
- RAG (Retrieval-Augmented Generation) capabilities
- Voice and audio support

## System Architecture

### Technology Stack
- **Backend**: Python 3.11, FastAPI, SQLAlchemy, Alembic
- **Frontend**: Svelte, Vite, TypeScript, TailwindCSS
- **Database**: SQLite (default), PostgreSQL (Supabase), Redis (sessions)
- **Deployment**: Railway (primary), Docker, HuggingFace Spaces
- **AI Providers**: OpenRouter, Ollama, OpenAI, Anthropic, Google, Groq, and more

### Directory Structure
```
open-connect/
├── backend/
│   ├── open_webui/
│   │   ├── main.py           # FastAPI application entry point
│   │   ├── config.py         # Configuration management
│   │   ├── env.py            # Environment variable handling
│   │   ├── models/           # Database models
│   │   ├── routers/          # API routes
│   │   ├── utils/            # Utility functions
│   │   ├── tasks.py          # Background tasks
│   │   └── socket/           # WebSocket handling
│   ├── data/                 # Persistent data directory
│   ├── start.sh              # Container startup script
│   └── requirements.txt
├── src/                      # Frontend source
├── scripts/
│   └── backup/               # Backup scripts
├── .github/workflows/        # CI/CD pipelines
├── Dockerfile
├── docker-compose.yaml
└── railway.toml
```

## Deployment Configuration

### Railway Deployment
- **Project ID**: `b5eaa696-e7d5-4403-be0a-79a485e54537`
- **Environment ID**: `266408c3-17b9-4706-907a-3abc4acf1382`
- **Service ID**: `bb211eb9-3ebf-4e4d-84fc-f1e0e4ca5609`
- **Health Check**: `/health` endpoint with 30s interval
- **Restart Policy**: ON_FAILURE with 10 max retries

### Environment Variables
| Variable | Description | Required |
|----------|-------------|----------|
| `ENV` | Environment (prod/dev) | Yes |
| `DOCKER` | Docker mode flag | Yes |
| `PORT` | Server port | Yes |
| `WEBUI_SECRET_KEY` | JWT secret key | Yes |
| `DATABASE_URL` | PostgreSQL connection string | No |
| `SUPABASE_URL` | Supabase project URL | No |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | No |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | No |
| `OPENAI_API_KEY` | OpenRouter/API key | No |
| `OPENAI_API_BASE_URL` | API base URL | No |
| `OLLAMA_BASE_URL` | Ollama server URL | No |
| `WEBUI_NAME` | Application name | No |
| `WEBUI_URL` | Application URL | No |
| `ENABLE_SIGNUP` | Allow user registration | No |
| `DEFAULT_MODELS` | Default AI models | No |
| `WEB_SEARCH` | Enable web search | No |
| `RAG_EMBEDDING_MODEL` | Embedding model | No |

### Data Persistence
- **Volume Mount**: `/app/backend/data` on Railway
- **Backup Location**: Supabase Storage bucket `open-connect-backups`
- **Backup Schedule**: Every 6 hours via GitHub Actions

## CI/CD Pipeline

### Workflows
1. **CI** (`.github/workflows/ci.yml`)
   - Linting (ESLint, Ruff)
   - Type checking
   - Frontend build
   - Backend tests
   - Docker build
   - Security scanning (Trivy)

2. **Deploy** (`.github/workflows/deploy.yml`)
   - Pre-deployment backup
   - Docker image build & push
   - Railway deployment
   - Health check verification
   - Post-deployment smoke tests

3. **Backup** (`.github/workflows/backup.yml`)
   - Scheduled every 6 hours
   - Manual trigger available
   - Supabase Storage upload
   - Retention management (14 days)

4. **Release** (`.github/workflows/release.yml`)
   - Tag-based releases
   - Docker image tagging
   - GitHub release creation
   - Helm chart updates

### Docker Variants
- `main`: Standard build
- `cuda`: NVIDIA GPU support
- `cuda126`: CUDA 12.6 support
- `ollama`: Bundled Ollama
- `slim`: Minimal build

## Database Schema

### Core Tables
- `users` - User accounts and preferences
- `chats` - Chat sessions
- `messages` - Chat messages
- `files` - Uploaded files
- `knowledge` - Knowledge bases
- `functions` - Custom functions
- `tools` - Available tools
- `models` - Model configurations
- `config` - Application configuration
- `auths` - Authentication records

### Database Migrations
- Managed via Alembic
- Auto-run on startup if `ENABLE_DB_MIGRATIONS=true`
- Migration directory: `backend/open_webui/migrations/`

## API Endpoints

### Authentication
- `POST /api/v1/auths/signup` - User registration
- `POST /api/v1/auths/login` - User login
- `POST /api/v1/auths/logout` - User logout
- `GET /api/v1/auths/session` - Get session info

### Chat
- `POST /api/v1/chat/completions` - Chat completion
- `GET /api/v1/chats` - List chats
- `GET /api/v1/chats/{id}` - Get chat
- `DELETE /api/v1/chats/{id}` - Delete chat

### Models
- `GET /api/v1/models` - List available models
- `POST /api/v1/models` - Add model
- `DELETE /api/v1/models/{id}` - Remove model

### Files & Knowledge
- `POST /api/v1/files/upload` - Upload file
- `GET /api/v1/files/{id}` - Get file
- `POST /api/v1/knowledge` - Create knowledge base
- `GET /api/v1/knowledge/{id}` - Get knowledge base

### Functions & Tools
- `GET /api/v1/functions` - List functions
- `POST /api/v1/functions` - Register function
- `GET /api/v1/tools` - List tools
- `POST /api/v1/tools` - Register tool

### Health & Status
- `GET /health` - Basic health check
- `GET /ready` - Readiness check (includes DB)
- `GET /health/db` - Database health check

## Free AI Models

### Recommended Free Models
```python
DEFAULT_MODELS = [
    "google/gemma-3-4b-it",      # Google Gemma 3 4B
    "qwen/qwen-2.5-7b-instruct", # Qwen 2.5 7B
    "microsoft/phi-4",          # Microsoft Phi-4
    "deepseek/deepseek-r1",      # DeepSeek R1
    "anthropic/claude-3.5-haiku", # Claude 3.5 Haiku
    "meta/llama-3.1-8b-instruct" # Llama 3.1 8B
]
```

### Model Providers
1. **OpenRouter** (Recommended for free tier)
   - Base URL: `https://openrouter.ai/api/v1`
   - Supports many free models
   - Rate limiting applies

2. **Ollama** (Local)
   - Default URL: `http://localhost:11434`
   - No API key required
   - Runs models locally

3. **Groq**
   - Free tier available
   - Fast inference
   - API key required

## Backup & Restore

### Automatic Backup (GitHub Actions)
```bash
# Runs every 6 hours
# Retains last 14 days of backups
# Stores in Supabase Storage
```

### Manual Backup
```bash
# Local backup
./scripts/backup/backup.sh

# Environment variables
BACKUP_DIR=/path/to/backups
DATA_DIR=/app/backend/data
RETENTION_DAYS=14
```

### Restore from Backup
```bash
# Download backup from Supabase
# Extract archive
tar -xzf open-connect_backup_YYYYMMDD_HHMMSS.tar.gz

# Restore files
cp database/webui.db backend/data/webui.db
cp -r uploads backend/data/
cp -r knowledge backend/data/

# Restart application
```

### Startup Restore
```bash
# Enable automatic restore on startup
ENABLE_BACKUP_RESTORE_ON_STARTUP=true

# Place backup in /tmp/restore/latest.sqlite
```

## Troubleshooting

### Common Issues

1. **Container Crash on Startup**
   - Check logs: `railway logs`
   - Verify environment variables
   - Check health endpoint: `/health`
   - Verify database connectivity

2. **Database Migration Failed**
   - Check Alembic migrations: `backend/open_webui/migrations/`
   - Verify database permissions
   - Check migration logs

3. **Memory Issues**
   - Reduce UVICORN_WORKERS
   - Increase container memory
   - Enable swap

4. **Backup Failures**
   - Verify Supabase credentials
   - Check disk space
   - Verify backup directory permissions

### Health Check Failures
```bash
# Manual health check
curl -f http://localhost:8080/health

# Readiness check (includes DB)
curl -f http://localhost:8080/ready

# Database check
curl -f http://localhost:8080/health/db
```

## Development

### Local Development Setup
```bash
# Clone repository
git clone https://github.com/your-org/open-connect.git
cd open-connect

# Install dependencies
npm install
cd backend && pip install -r requirements.txt

# Run development server
npm run dev
# or
docker-compose up
```

### Testing
```bash
# Backend tests
cd backend
pytest tests/ -v

# Frontend tests
npm run test

# E2E tests
docker-compose -f docker-compose.playwright.yaml up
```

### Building
```bash
# Build frontend
npm run build

# Build Docker image
docker build -t open-connect .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t open-connect .
```

## Security

### Environment Variables
- Never commit `.env` files
- Use Railway/Secret manager for sensitive values
- Rotate API keys regularly

### Database
- Use PostgreSQL for production
- Enable SSL for connections
- Regular backups required

### Authentication
- JWT-based authentication
- Session expiry: 4 weeks (configurable)
- API key support for programmatic access

### CORS
- Default: `*` (all origins)
- Configure for production: specific domains

## Monitoring & Alerts

### Health Metrics
- Response time
- Error rate
- Database connections
- Memory usage

### Alert Triggers
- Health check failures
- High memory usage (>80%)
- Failed backup attempts
- Database connection errors

## Versioning

### Semantic Versioning
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

### Release Process
1. Update version in `package.json`
2. Create git tag: `vX.Y.Z`
3. Push tag to trigger release workflow
4. GitHub Actions creates release
5. Docker images published

## Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: Project Wiki
- **Email**: support@open-connect.dev
