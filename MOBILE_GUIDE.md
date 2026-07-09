# Open Connect - Mobile Installation & API Guide

## Mobile App Installation (Android & iOS)

Open Connect uses **Progressive Web App (PWA)** technology, which means it works like a native app on mobile devices without requiring an APK download.

### Installing on Android

1. **Open in Chrome/Edge/Brave**
   - Navigate to: https://open-connect-production.up.railway.app
   - Use Chrome for best experience

2. **Add to Home Screen**
   - Tap the **3-dot menu** (⋮) in the top-right corner
   - Select **"Add to Home Screen"** or **"Install app"**
   - Tap **"Add"** or **"Install"**

3. **App Installed!**
   - Open Connect will appear as an app icon on your home screen
   - It works offline (chat history cached locally)
   - Push notifications supported (when enabled)

### Installing on iPhone/iPad

1. **Open in Safari**
   - Navigate to: https://open-connect-production.up.railway.app
   - **Important**: Use Safari (PWA install requires Safari)

2. **Add to Home Screen**
   - Tap the **Share button** (square with arrow ↑)
   - Scroll down and tap **"Add to Home Screen"**
   - Name the app and tap **"Add"**

3. **App Installed!**
   - The app will appear on your home screen
   - Works like a native app

### Features Available on Mobile

| Feature | Status |
|---------|--------|
| Chat Interface | ✅ Full support |
| Model Selection | ✅ Full support |
| File Uploads | ✅ Full support |
| Voice Input | ✅ Full support |
| Knowledge Base | ✅ Full support |
| Settings | ✅ Full support |
| Offline Mode | ⚠️ Limited (cached data) |

---

## API Authentication Setup

### Getting Your API Key

1. **Log in** to Open Connect at https://open-connect-production.up.railway.app
2. Go to **Settings** (gear icon in top-right)
3. Click **"Account"** or **"API Keys"** in the sidebar
4. Click **"Create API Key"** or **"Generate New Key"**
5. Copy your API key (starts with `sk-`)

### Using the API

#### Authentication Header
Include your API key in the `Authorization` header:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://open-connect-production.up.railway.app/api/v1/models
```

#### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/models` | GET | List all available models |
| `/api/v1/chats` | GET | List all chats |
| `/api/v1/chats` | POST | Create a new chat |
| `/api/v1/chat/{id}/messages` | GET | Get chat messages |
| `/api/v1/chat/{id}/messages` | POST | Send a message |
| `/api/v1/configs` | GET | Get system configuration |

#### Example: Chat Completion

```bash
curl -X POST https://open-connect-production.up.railway.app/api/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-3-4b-it",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

#### Example: List Models

```bash
curl https://open-connect-production.up.railway.app/api/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Fixing "Missing Authentication Header" Error

If you see "Missing Authentication header" error:

### Cause
The API request doesn't include the `Authorization: Bearer` header.

### Solution

1. **Get your API key** from Settings > Account > API Keys
2. **Include in every request**:
   ```bash
   -H "Authorization: Bearer YOUR_API_KEY"
   ```
3. **Check the key is valid** - keys expire or can be revoked

### Troubleshooting

| Error | Solution |
|-------|----------|
| "Missing Authentication header" | Add `Authorization: Bearer sk-xxx` header |
| "Invalid API key" | Generate a new key from Settings |
| "Key expired" | Generate a new key |
| "Rate limited" | Wait and retry, or use a slower rate |

---

## OpenRouter Models (Free Tier)

Open Connect is configured with these free OpenRouter models:

| Model | Description | Best For |
|-------|-------------|----------|
| `google/gemma-3-4b-it` | Fast, efficient responses | General chat |
| `qwen/qwen-2.5-7b-instruct` | Good quality, fast | Coding, analysis |
| `microsoft/phi-4` | Reasoning capabilities | Complex tasks |
| `deepseek/deepseek-r1` | Deep reasoning | Math, logic |
| `anthropic/claude-3.5-haiku` | Fast Claude | Quick tasks |
| `meta/llama-3.1-8b-instruct` | Open-source favorite | General use |

### Using Different Models

In the chat interface:
1. Click the **model selector** (top-left or dropdown)
2. Select your preferred model
3. Start chatting!

---

## Backup & Restore

### Manual Backup

```bash
cd scripts/backup
./backup.sh
```

### Auto-Backup Setup (Railway)

1. Go to Railway dashboard
2. Select your project > open-connect service
3. Go to **Settings** > **Cron Jobs**
4. Add a new cron job:
   - **Command**: `/bin/bash /app/scripts/backup/railway-backup.sh`
   - **Schedule**: `0 2 * * *` (daily at 2 AM)
   - **Timeout**: 300 seconds

### Restore from Backup

```bash
cd scripts/backup
./restore.sh backups/open-connect_backup_20240101_120000.tar.gz
```

---

## Security Best Practices

1. **Change default password** - Admin password `openpassword` should be changed immediately
2. **Keep API keys secure** - Don't share or commit to version control
3. **Enable HTTPS** - Railway provides this automatically
4. **Regular backups** - Set up automated backups
5. **Monitor usage** - Check for unauthorized API access

---

## Support

- **GitHub Issues**: https://github.com/OrgHide/open-connect/issues
- **Documentation**: See SETUP_GUIDE.md for detailed setup instructions
