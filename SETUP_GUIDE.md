# Open Connect v1.0.0 - Complete Setup Guide

## Overview

Open Connect is a self-hosted AI interface that supports multiple AI providers including OpenRouter, Hugging Face, Groq, and more.

**🌐 Live Deployment**: https://open-connect-production.up.railway.app

---

## 📱 Quick Start - Mobile Installation

Open Connect works as a Progressive Web App (PWA) on mobile devices:

### Android
1. Open https://open-connect-production.up.railway.app in Chrome
2. Tap the 3-dot menu → "Add to Home Screen"
3. Tap "Add" to install

### iPhone/iPad
1. Open https://open-connect-production.up.railway.app in Safari
2. Tap the Share button → "Add to Home Screen"
3. Name it and tap "Add"

See **MOBILE_GUIDE.md** for detailed instructions.

---

## 🔑 Authentication

### Admin Account
- **Name**: Charles Tanauan
- **Email**: tanauancharles1@gmail.com
- **Password**: `openpassword`

⚠️ **Change the admin password immediately after first login!**

### API Authentication

1. Go to **Settings** → **Account** → **API Keys**
2. Click **"Create API Key"**
3. Copy your API key

**Usage:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://open-connect-production.up.railway.app/api/v1/models
```

---

## 🤖 AI Models (Free Tier)

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

## ⚙️ Environment Variables

| Variable | Description | Status |
|----------|-------------|--------|
| `OPENAI_API_KEY` | OpenRouter API key | ✅ Configured |
| `OPENAI_API_BASE_URL` | OpenRouter endpoint | ✅ Configured |
| `HUGGINGFACE_TOKEN` | Hugging Face token | ✅ Configured |
| `GROQ_API_KEY` | Groq API key | ✅ Configured |
| `WEBUI_SECRET_KEY` | Session encryption | ✅ Configured |
| `DEFAULT_MODELS` | Pre-selected models | ✅ Configured |
| `ENV` | Environment | ✅ Set to prod |
| `PORT` | Application port | ✅ Set to 8080 |
| `DOCKER` | Docker mode | ✅ Enabled |

---

## 💾 Backup & Migration

### Manual Backup
```bash
cd scripts/backup
./backup.sh
```

### Auto-Backup (Railway Cron)
1. Go to Railway Dashboard → open-connect → Settings → Cron Jobs
2. Add new cron job:
   - Command: `/bin/bash /app/scripts/backup/railway-backup.sh`
   - Schedule: `0 2 * * *` (daily at 2 AM)

### Restore from Backup
```bash
cd scripts/backup
./restore.sh backups/open-connect_backup_TIMESTAMP.tar.gz
```

### Backup Contents
- Database (`webui.db`)
- User uploads
- Knowledge base
- Chat history
- Secret key
- Configuration

---

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/models` | GET | List models |
| `/api/v1/chats` | GET/POST | Chat operations |
| `/api/v1/configs` | GET | System config |
| `/api/chat/completions` | POST | Chat completions |

---

## 🚀 Railway Deployment

### Health Check
- **Path**: `/health`
- **Timeout**: 300 seconds (5 minutes)
- **Status**: ✅ Working

### Redeploy
```bash
# Via Railway GraphQL API
mutation {
  serviceInstanceRedeploy(
    serviceId: "bb211eb9-3ebf-4e4d-84fc-f1e0e4ca5609",
    environmentId: "266408c3-17b9-4706-907a-3abc4acf1382"
  )
}
```

---

## 🔧 Troubleshooting

### "Missing Authentication Header"
**Solution**: Add `Authorization: Bearer YOUR_API_KEY` to your API requests.

### 502 Bad Gateway
**Causes**:
1. App still starting up (wait 2-5 minutes)
2. Health check path incorrect
3. Missing environment variables

### Database Connection Errors
**Solution**: Remove DATABASE_URL to use SQLite (default).

### API Key Issues
1. Generate new key from Settings
2. Check key hasn't expired
3. Ensure header format is correct

---

## 📁 Project Structure

```
open-connect/
├── backend/
│   ├── open_webui/       # Main application
│   │   ├── data/         # SQLite database
│   │   └── static/       # Frontend assets
│   ├── requirements.txt  # Python dependencies
│   └── .webui_secret_key # Session secret
├── scripts/
│   └── backup/          # Backup scripts
│       ├── backup.sh     # Manual backup
│       ├── restore.sh    # Restore from backup
│       ├── auto-backup.sh # Auto-backup with retention
│       └── railway-backup.sh # Railway-specific backup
├── Dockerfile
├── SETUP_GUIDE.md       # This file
├── MOBILE_GUIDE.md       # Mobile installation guide
└── .github/workflows/    # CI/CD
```

---

## 🔒 Security Best Practices

1. **Change default admin password** immediately
2. **Keep API keys secure** - never commit to version control
3. **Regular backups** - set up automated daily backups
4. **Monitor logs** - check for unauthorized access
5. **HTTPS** - Railway provides automatically

---

## 📚 Additional Resources

- **Mobile Installation**: See `MOBILE_GUIDE.md`
- **GitHub Repository**: https://github.com/OrgHide/open-connect
- **Open WebUI Docs**: https://docs.openwebui.com/

---

## ✅ Version History

- **v1.0.0** (Current)
  - Initial deployment
  - OpenRouter, Hugging Face, Groq integration
  - Mobile PWA support
  - Auto-backup scripts
  - Comprehensive documentation
