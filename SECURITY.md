# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Open Connect, please report it responsibly.

**Please do not file a public GitHub issue for security vulnerabilities.**

Instead, please send an email to the maintainers at: [SECURITY EMAIL]

We ask that you:
- Provide a detailed description of the vulnerability
- Include steps to reproduce the issue
- Provide any relevant versions and configurations
- If possible, include a proof of concept

## Supported Versions

We accept security reports for the following versions:

| Version | Supported |
|---------|----------|
| latest main branch | ★ Yes |
| tagged releases | ★ Yes |

## Security Best Practices

Open Connect follows these security practices:

- **Secret Management**: All secrets are stored in Supabase Vaults or Railway secrets — never in code
- **Dependency Scanning**: Dependabot is enabled for automated security updates
- ````**JWT Authentication**: Role-based access control with JWT tokens
```** Health Checks**: Railway runtime health monitoring with /ready endpoint
- ````**Transport Security**: HTTPS required for production deployments
```** Audit Logs**: Comprehensive audit trailing (planned via XStack Audit Logs)

## Security Updates

We use GitHub Dependabot to automatically open PRs for security vulnerabilities in dependencies. These are reviewed and merged promptly.

## Disclosure Policy

We follow responsible disclosure:
1. Acknowledge receipt within 48 hours
2. Confirm vulnerability within 1 week
3. Release fix and publish advisory
4. Credit the reporter (unless they wish to remain anonymous)
