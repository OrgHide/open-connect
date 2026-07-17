# Railway Deployment with Open WebUI Computer & Open Terminal

This guide explains how to deploy Open Connect to Railway with Open WebUI Computer and Open Terminal automatically loaded on new deployments.

## Overview

This deployment configuration includes four services:

1. **Open Connect** (Main Application) - Port 8080
2. **Open WebUI Computer** (cptr) - Port 8001
3. **Open Terminal** - Port 8002
4. **Ollama** - Port 11434 - Local LLM inference server

## Quick Start

### 1. Deploy to Railway
1. Push your code to GitHub
2. Import the repository to Railway at https://railway.app
3. Railway will automatically detect docker-compose.railway.yaml and deploy all services

### 2. Access Your Services
- Open Connect: https://your-app.up.railway.app
- Open WebUI Computer: https://your-app.up.railway.app:8001
- Open Terminal: https://your-app.up.railway.app:8002
- Ollama API: https://your-app.up.railway.app:11434

## Ollama Integration

Local LLM inference server for running models on your own hardware.

**Docker Image**: ollama/ollama:latest
**Port**: 11434

### Usage
- Pull models: curl -X POST http://localhost:11434/api/pull -d '{"name": "llama3"}'
- List models: curl http://localhost:11434/api/tags
- Generate: curl -X POST http://localhost:11434/api/generate -d '{"model": "llama3", "prompt": "Hello"}'

### Integration with Open Connect
Open Connect automatically connects to Ollama at http://ollama:11434 via internal Docker networking.

## Configuration Files
- docker-compose.railway.yaml: Defines all 4 services
- railway.toml: Railway-specific configuration
- railway-start.sh: Startup script with health checks

## Service Details
All services include persistent volumes, health checks, and internal networking.

## Troubleshooting
Check logs with: docker compose -f docker-compose.railway.yaml logs
