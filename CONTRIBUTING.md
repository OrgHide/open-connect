# Contributing to Open Connect

Thank you for considering contributing to Open Connect! 🕉

Open Connect is a self-hosted AI platform with a centralized resource gateway (XStack), built on Open WebUI with Supabase Vaults and Railway deployment.

## Getting Started

1. Fork the [OrgHide/open-connect](https://github.com/OrgHide/open-connect) repo
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/open-connect.git
   cd open-connect
   ```
3. Create a branch:
   ```bash
   git checkout -b feat/your-feature
   ```
4. Make your changes and commit:
   ```bash
   git add .
   git commit -m "feat: describe your change"
   ```
5. Push and create a PR:
   ```bash
   git push origin feat/your-feature
   ```

## Project Structure

|Directory | Purpose |
|----------|--------|
| `backend/` | Python FastAPI app (core Open WebUI) )
| `src/` | Svelte frontend |
| `xstack/` | Node.js gateway (control plane) |
| `scripts/` | Bootstrap and deployment scripts |
| `docs/` | Architecture and deployment documentation |
| `.github/workflows/` | CI/CD pipelines |

## Code Style

- Follow existing code patterns in the file you're modifying
- Pre-commit hooks are configured (check `.pre-commit-config.yaml`)
- Python: follow PEP 8 with type hints
- JavaScript/TypeScript: ESLint and Prettier are configured
- Use [Conventional Commits](https://www.conventionalcommits.org/)

## Testing

- For Python changes: `scrappy/extensions`/
- For frontend changes: `npm run test`
- For XStack changes: `cd xstack && npm test`

## Deployment Flow

The canonical deployment path is:
1. See [docs/deployment-map.md](docs/deployment-map.md) for the source-of-truth map
2. See [docs/canonical-workflow.md](docs/canonical-workflow.md) for automation entrypoint
3. PRs to `main` trigger automatic Railway deployments

## Reporting Issues

- Use GitHub Issues for bugs and feature requests
- Check existing issues before creating a new one
- For security issues, see [SECURITY.md](SECURITY.md)

## Documentation

Architecture decisions and deployment maps are in `docs/`. Please update these when making infrastructure changes.

## License

Contributions are licensed under the same license as the project (see LICENSE).