# Open Connect v1.0.0 - Setup & Migration Guide

## Overview

Open Connect is a self-hosted AI interface that supports multiple AI providers including OpenRouter, Hugging Face, Groq, and more.

**Live Deployment**: https://open-connect-production.up.railway.app

---

## Quick Start

### Prerequisites
- Railway account (for deployment)
- API keys for at least one AI provider

### Required Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenRouter API key (recommended) | Yes |
| `OPENAI_API_BASE_URL` | OpenRouter endpoint: `https://openrouter.ai/api/v1` | Yes |
| `HUGGINGFACE_TOKEN` | Hugging Face API token | Optional |
| `GROQ_API_KEY` | Groq API key | Optional |
| `WEBUI_SECRET_KEY` | Secret key for session encryption | Yes |
| `DATABASE_URL` | PostgreSQL connection string | Optional |
| `ENV` | Environment: `dev`, `test`, `prod` | Yes |
| `PORT` | Application port (default: 8080) | Yes |
| `DOCKER` | Set to `true` for Docker deployment | Yes |

---

## AI Providers Configuration

### OpenRouter (Recommended - Free Tier)

OpenRouter provides access to many free models including:
- **google/gemma-3-4b-it**: Free, fast responses
- **qwen/qwen-2.5-7b-instruct**: Free, good quality
- **microsoft/phi-4**: Free, reasoning
- **deepseek/deepseek-r1**: Free, reasoning
- **anthropic/claude-3.5-haiku**: Free tier available

```bash
OPENAI_API_KEY=sk-oh-xxxxxxxxxxxx
OPENAI_API_BASE_URL=https://openrouter.ai/api/v1
```

### Hugging Face (Free Tier)

Access to open-source models through Hugging Face inference endpoints.

```bash
HUGGINGFACE_TOKEN=hf_xxxxxxxxxxxx
```

### Groq (Free Tier)

Fast inference with free tier limits:
- **llama-3.1-8b-instant**: Free
- **llama-3.2-1b-preview**: Free
- **mixtral-8x7b-32768**: Free

```bash
GROQ_API_KEY=gsk_xxxxxxxxxxxx
```

---

## Database Configuration

### SQLite (Default - No Setup Required)

By default, the application uses SQLite for data storage. This is stored at:
```
./backend/data/webui.db
```

### PostgreSQL (Production - Optional)

For production deployments with multiple instances:

```bash
DATABASE_URL=postgresql://user:password@host:port/database
```

---

## Backup & Migration

### Creating a Backup

```bash
cd scripts/backup
chmod +x backup.sh
./backup.sh
```

This creates a backup at `backups/open-connect_backup_[timestamp].tar.gz` containing:
- Database (`webui.db`)
- User uploads
- Embedding model cache
- Secret key
- Environment template

### Restoring from Backup

```bash
cd scripts/backup
chmod +x restore.sh
./restore.sh backups/open-connect_backup_20240101_120000.tar.gz
```

### Manual Migration

1. **Copy database**:
   ```bash
   cp ./backend/data/webui.db /path/to/new/location/webui.db
   ```

2. **Copy secret key**:
   ```bash
   cp ./backend/.webui_secret_key /path/to/new/location/.webui_secret_key
   ```

3. **Copy uploads** (if any):
   ```bash
   cp -r ./backend/data/uploads /path/to/new/location/uploads/
   ```

4. **Set environment variables** on the new server

5. **Restart the application**

---

## Railway Deployment

### Environment Variables via GraphQL

The following variables are configured for the Railway deployment:

```bash
# AI Providers
OPENAI_API_KEY=sk-oh-xxxxxxxxxxxx
OPENAI_API_BASE_URL=https://openrouter.ai/api/v1
HUGGINGFACE_TOKEN=hf_xxxxxxxxxxxx
GROQ_API_KEY=gsk_xxxxxxxxxxxx

# App Configuration
APP_NAME=Open Connect
ENV=prod
WEBUI_SECRET_KEY=xxxxxxxxxxxx
PORT=8080
DOCKER=true
```

### Health Check

The health check endpoint is configured at `/health` with a 2-minute timeout.

---

## Admin Account

The admin account was created during setup:

- **Name**: Charles Tanauan
- **Email**: tanauancharles1@gmail.com
- **Password**: openpassword

⚠️ **Security Note**: Change the admin password immediately after first login!

---

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `/` | Web UI |
| `/health` | Health check |
| `/api/v1/` | API v1 |
| `/api/v1/models` | List models |
| `/api/v1/chats` | Chat endpoints |

---

## Troubleshooting

### 502 Bad Gateway

This usually means the application failed to start. Check:
1. Health check path is correct (`/health`)
2. All required environment variables are set
3. Application is listening on the correct port (8080)

### Database Connection Errors

If using PostgreSQL:
1. Verify the connection string format
2. Check database credentials
3. Ensure the database is accessible from the deployment

### Missing API Keys

Some features require API keys:
- AI model inference requires at least one provider key
- Embedding models download from Hugging Face
- Web search features require search API keys

---

## Security Best Practices

1. **Change default passwords** immediately
2. **Use environment variables** for secrets, never commit them
3. **Enable HTTPS** in production (Railway provides this automatically)
4. **Regular backups** - automate with cron:
   ```bash
   0 2 * * * /path/to/backup.sh
   ```

---

## Version History

- **v1.0.0** (Current): Initial deployment with OpenRouter, Hugging Face, and Groq support

---

## Support

For issues and feature requests, please open an issue on the GitHub repository.
