# XStack Open-Connect - End-to-End Deployment Guide

## Complete Deployment Setup

This guide provides comprehensive instructions for deploying XStack as a complete AI Resource Manager for Open-Connect, including credential management across GitHub Actions, Railway, and Supabase Vault.

## Prerequisites

- Node.js 18+ (LTS recommended)
- npm or yarn
- Docker (for containerized deployment)
- Railway CLI (for Railway deployment)
- Git
- GitHub Account
- Railway Account
- Supabase Account (optional, for vault)

## Repository Setup

git clone https://github.com/OrgHide/open-connect.git
cd open-connect

## Local Development

cd xstack
npm install
cp ../.env.example .env
nano .env
npm run dev

## Railway Deployment

### Method 1: Using Railway CLI
npm install -g @railway/cli
railway login
railway init
railway up --detach

### Method 2: Using GitHub Integration
- Go to Railway Dashboard
- Click New Project -> Deploy from GitHub repo
- Select OrgHide/open-connect
- Configure environment variables

### Railway Configuration
Railway automatically provisions PostgreSQL and Redis. Configure these environment variables:
- NODE_ENV=production
- PORT=3000
- BASE_URL=https://your-app.up.railway.app
- JWT_SECRET=generate_secure_value
- SESSION_SECRET=generate_secure_value
- MCP_GATEWAY=mcp://gateway

## Credential Management

### GitHub Actions Secrets
Go to GitHub repository Settings -> Secrets -> Actions and add:
- RAILWAY_API_KEY
- RAILWAY_PROJECT_ID
- SUPABASE_URL
- SUPABASE_KEY
- JWT_SECRET
- SESSION_SECRET

### Railway Environment Variables
Configure in Railway Dashboard -> Project -> Variables:
- DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD (from Railway PostgreSQL)
- REDIS_HOST, REDIS_PORT, REDIS_PASSWORD (from Railway Redis)

### Supabase Vault Integration
Create Supabase project and configure storage bucket xstack-secrets for secure credential storage.

## Chat Commands Configuration

### Available Commands
- /open_xstack -> /xstack
- /open_resources -> /xstack/resources
- /open_connections -> /xstack/connections
- /open_marketplace -> /xstack/marketplace
- /open_secrets -> /xstack/secrets

### Aliases
- /xstack
- /resources
- /connections
- /marketplace
- /secrets

## Build and Deployment Commands

### Using Makefile
- make help - Show all commands
- make install - Install dependencies
- make dev - Start development server
- make build - Build production bundle
- make docker - Build Docker image
- make docker-railway - Build Railway Docker image
- make deploy-railway - Deploy to Railway
- make clean - Clean build artifacts

## Next Steps

1. Clone the repository
2. Install dependencies
3. Configure environment variables
4. Deploy to Railway
5. Set up GitHub Actions
6. Configure Supabase Vault (optional)
7. Test chat commands
8. Verify health endpoints

*Last updated: July 17, 2026*
