# Open Connect Project DNA

## Identity
- **Project Name**: open-connect
- **Vision**: A sophisticated, self-hosted, enterprise-grade AI platform rebranded and enhanced from Open WebUI.
- **Core Value**: Security-first, automated, and architecturally clean.

## Architecture
- **Control Plane**: XStack Gateway (`xstack/`) - manages AI resources, secrets, and policies.
- **Backend**: Python 3.11 / FastAPI / SQLAlchemy.
- **Frontend**: Svelte / Vite / TailwindCSS.
- **Database**: Supabase PostgreSQL (v17) with pg_cron, pg_net, and pgvector.
- **Auth**: Supabase Auth (GitHub OAuth integration).
- **Secrets**: Supabase Vault (`vault.secrets`) replicated to `public.agent_vault`.
- **Deployment**: Railway (Containerized with persistent disks).
- **Observability**: Langfuse Tracing.

## Development Principles
1. **GitHub as Source of Truth**: All tasks and architectural decisions live in `docs/`.
2. **Autonomous Deployment**: Every merge to `main` triggers a fully automated deployment.
3. **Secret Isolation**: Never hardcode credentials; always use the Secret Broker / Vault system.
4. **Clean Hierarchy**: Follow the consolidated XStack architecture for resource management.
