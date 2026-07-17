# XStack Secrets Management - Professional Edition

## Comprehensive Secret Management System

XStack now features a professional, enterprise-grade secret management system with full support for categories, filtering, search, groups, and project isolation.

## Features Overview

### 1. Categories & Organization
- 7 Built-in Categories: API Keys, Database, Authentication, Encryption, Third Party, Internal, Custom
- Custom Categories: Create your own categories as needed
- Professional Tagging: Add multiple tags to secrets for easy filtering

### 2. Advanced Filtering & Search
- Filter by Category, Project, Group, Tags
- Search across name, description, and tags
- Multiple tag filtering simultaneously
- Global vs Project Secrets control

### 3. Project Isolation
- Create Projects: Organize secrets by project/team
- Project-Specific Secrets: Secrets that only belong to specific projects
- Global Secrets: Secrets accessible across all projects
- Project Groups: Organize secrets within projects using groups

### 4. Secret Groups
- Create Groups: Group related secrets together
- Group by Project: Groups can be associated with specific projects
- Add/Remove Secrets: Dynamically manage group membership
- Nested Organization: Groups within projects for hierarchical structure

### 5. Access Control
- Project-Level Access: Users can only access secrets for their projects
- Global Access: Admin users can access all secrets
- Group-Level Access: Fine-grained control over secret visibility
- Write Protection: Separate read and write permissions

### 6. Professional API
- RESTful Endpoints: Full CRUD operations for all entities
- Comprehensive Filtering: Advanced query parameters
- Search API: Full-text search across all secrets
- Organized Responses: Secrets returned in structured format

## Quick Start

### Create Your First Project
curl -X POST http://localhost:3000/api/v1/secrets/projects -H Content-Type: application/json -d '{"name": "My AI Project", "description": "Production AI system"}'

### Create a Secret Group
curl -X POST http://localhost:3000/api/v1/secrets/groups -H Content-Type: application/json -d '{"name": "API Credentials", "description": "All API keys and tokens", "projectId": "project_1"}'

### Create a Secret with Full Metadata
curl -X POST http://localhost:3000/api/v1/secrets -H Content-Type: application/json -d '{"name": "OpenAI API Key", "value": "sk-...", "category": "api_keys", "description": "Production OpenAI API key", "tags": ["openai", "production", "critical"], "projectId": "project_1", "groupId": "group_1", "isGlobal": false, "metadata": {"environment": "production", "rotationSchedule": "monthly", "owner": "devops-team"}}'

### List Secrets with Filtering
# All secrets
curl http://localhost:3000/api/v1/secrets

# By category
curl "http://localhost:3000/api/v1/secrets?category=api_keys"

# By project
curl "http://localhost:3000/api/v1/secrets?projectId=project_1"

# By group
curl "http://localhost:3000/api/v1/secrets?groupId=group_1"

# Search
curl "http://localhost:3000/api/v1/secrets?search=api"

# Multiple filters
curl "http://localhost:3000/api/v1/secrets?category=api_keys&projectId=project_1&search=openai"

### Advanced Search
curl -X POST http://localhost:3000/api/v1/secrets/search -H Content-Type: application/json -d '{"query": "production api", "includeGlobal": true}'

## API Endpoints

### Secrets
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/secrets | List secrets with filtering |
| GET | /api/v1/secrets/:id | Get secret (metadata or full) |
| POST | /api/v1/secrets | Create new secret |
| PUT | /api/v1/secrets/:id | Update secret |
| DELETE | /api/v1/secrets/:id | Delete secret |
| GET | /api/v1/secrets/categories | List all categories |
| POST | /api/v1/secrets/search | Advanced search |
| GET | /api/v1/secrets/project/:projectId | Get secrets by project |

### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/secrets/groups | List all groups |
| GET | /api/v1/secrets/groups/:id | Get group details |
| POST | /api/v1/secrets/groups | Create group |
| PUT | /api/v1/secrets/groups/:id | Update group |
| DELETE | /api/v1/secrets/groups/:id | Delete group |
| POST | /api/v1/secrets/groups/:groupId/secrets/:secretId | Add secret to group |
| DELETE | /api/v1/secrets/groups/:groupId/secrets/:secretId | Remove secret from group |

### Projects
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/secrets/projects | List all projects |
| GET | /api/v1/secrets/projects/:id | Get project details |
| POST | /api/v1/secrets/projects | Create project |
| PUT | /api/v1/secrets/projects/:id | Update project |
| DELETE | /api/v1/secrets/projects/:id | Delete project |
| POST | /api/v1/secrets/projects/:projectId/groups/:groupId | Add group to project |
| POST | /api/v1/secrets/projects/:projectId/secrets/:secretId | Add secret to project |

## Use Cases

### 1. Multi-Project Organization
Project: AI Chatbot
- Group: API Keys
  - Secret: OpenAI API Key (api_keys)
  - Secret: Anthropic API Key (api_keys)
  - Secret: Google AI API Key (api_keys)
- Group: Database
  - Secret: PostgreSQL Connection (database)
  - Secret: Redis Connection (database)
- Group: Authentication
  - Secret: JWT Secret (authentication)

Project: Data Pipeline
- Group: Cloud Services
  - Secret: AWS Credentials (third_party)
  - Secret: GCP Service Account (third_party)
- Group: Database
  - Secret: MongoDB Connection (database)

Global Secrets:
- Secret: System Admin Password (authentication, isGlobal: true)
- Secret: Encryption Master Key (encryption, isGlobal: true)

### 2. Team-Based Access Control
- Dev Team: Access to AI Chatbot project secrets
- Data Team: Access to Data Pipeline project secrets
- DevOps Team: Access to all projects + global secrets
- Admin: Full access to all secrets

### 3. Environment Management
Project: Production System
- Group: Production
  - Secret: Prod Database URL (tags: [production, critical])
  - Secret: Prod API Key (tags: [production, critical])
  - Secret: Prod Encryption Key (tags: [production, critical])
- Group: Staging
  - Secret: Staging Database URL (tags: [staging, test])
  - Secret: Staging API Key (tags: [staging, test])

## Category Definitions

| Category ID | Name | Description | Use Case |
|-------------|------|-------------|----------|
| api_keys | API Keys | External API keys and tokens | OpenAI, Stripe, SendGrid |
| database | Database | Database connection credentials | PostgreSQL, MySQL, MongoDB |
| authentication | Authentication | Authentication tokens and session secrets | JWT secrets, OAuth tokens |
| encryption | Encryption | Encryption keys and certificates | SSL certificates, AES keys |
| third_party | Third Party | Third-party service credentials | AWS, GCP, Azure |
| internal | Internal | Internal system secrets | Internal API keys, service accounts |
| custom | Custom | User-defined categories | Any custom categorization |

## Configuration

### Environment Variables
SECRETS_ENABLE_PROJECTS=true
SECRETS_ENABLE_GROUPS=true
SECRETS_ENABLE_GLOBAL=true
SECRETS_ENABLE_SEARCH=true
SECRETS_MAX_PER_PROJECT=1000
SECRET_STORAGE=memory

### Workspace Configuration
secrets: {
  categories: {
    API_KEYS: 'api_keys',
    DATABASE: 'database',
    AUTHENTICATION: 'authentication',
    ENCRYPTION: 'encryption',
    THIRD_PARTY: 'third_party',
    INTERNAL: 'internal',
    CUSTOM: 'custom'
  },
  enableProjects: true,
  enableGroups: true,
  enableGlobal: true,
  storage: 'memory',
  maxSecretsPerProject: 1000,
  enableSearch: true
}

## Best Practices

### Secret Organization
- Use categories to classify secrets by type
- Use groups to organize related secrets
- Use projects to isolate secrets by application/team
- Use tags for cross-cutting concerns (environment, team, etc.)
- Use global secrets for system-wide credentials

### Access Control
- Grant minimal necessary access
- Use project isolation for team-based access
- Mark sensitive secrets as non-global
- Regularly audit secret access

### Secret Management
- Rotate secrets regularly
- Use descriptive names and metadata
- Document secret purpose and usage
- Monitor secret usage and access patterns

### Security
- Never commit secrets to version control
- Use environment variables for sensitive data
- Enable encryption for secrets at rest
- Implement audit logging for secret access

## Migration Guide

### From Simple to Professional Secrets
Before (Simple): { id: secret_1, name: API Key, value: xxx, category: api }

After (Professional): {
  id: secret_1,
  name: Production OpenAI API Key,
  value: sk-xxx,
  category: api_keys,
  description: Production API key for OpenAI GPT-4,
  tags: [openai, production, critical, gpt4],
  projectId: project_1,
  groupId: group_api_keys,
  isGlobal: false,
  metadata: { environment: production, rotationSchedule: monthly, owner: ai-team, costCenter: ai-services },
  createdAt: 2024-01-15T10:30:00Z,
  updatedAt: 2024-01-15T10:30:00Z,
  version: 1
}

## Query Examples

### Find All Production API Keys
curl "http://localhost:3000/api/v1/secrets?category=api_keys&tags=production"

### Find All Critical Secrets
curl "http://localhost:3000/api/v1/secrets?tags=critical"

### Find Secrets for Specific Project and Group
curl "http://localhost:3000/api/v1/secrets?projectId=project_1&groupId=group_1"

### Search Across All Projects
curl -X POST http://localhost:3000/api/v1/secrets/search -H Content-Type: application/json -d '{"query": "database password"}'

### Get Project Secrets Organized
curl http://localhost:3000/api/v1/secrets/project/project_1

## Advanced Usage

### Bulk Operations
const secrets = [
  { name: DB Host, value: localhost, category: database, projectId: project_1, tags: [prod] },
  { name: DB Port, value: 5432, category: database, projectId: project_1, tags: [prod] },
  { name: DB User, value: admin, category: database, projectId: project_1, tags: [prod] },
  { name: DB Password, value: secret123, category: database, projectId: project_1, tags: [prod, sensitive] }
];

const group = await secretBroker.createGroup({ name: Database, projectId: project_1 });
for (const secret of secrets) {
  await secretBroker.createSecret({ ...secret, groupId: group.id });
}

### Access Control Example
const userContext = { userId: user_123, projectId: project_1, groupIds: [group_1, group_2], isAdmin: false };
const adminContext = { userId: admin_1, isAdmin: true };

const userSecrets = await secretBroker.listSecrets({}, userContext);
const adminSecrets = await secretBroker.listSecrets({}, adminContext);

## API Response Examples

### List Secrets Response
{
  success: true,
  data: [{
    id: secret_1,
    name: OpenAI API Key,
    category: api_keys,
    description: Production API key,
    tags: [openai, production],
    projectId: project_1,
    groupId: group_1,
    isGlobal: false,
    metadata: {},
    createdAt: 2024-01-15T10:30:00Z,
    updatedAt: 2024-01-15T10:30:00Z,
    version: 1
  }],
  count: 1,
  timestamp: 2024-01-15T10:30:00Z
}

### Get Project Secrets (Organized)
{
  success: true,
  data: {
    project: { id: project_1, name: AI Chatbot, description: Production AI system },
    global: [],
    groups: {
      group_1: {
        group: { id: group_1, name: API Keys, description: All API keys },
        secrets: [{ id: secret_1, name: OpenAI API Key, category: api_keys }]
      }
    },
    ungrouped: []
  },
  timestamp: 2024-01-15T10:30:00Z
}

## Integration with External Systems

### Supabase Vault Integration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-key
SECRET_STORAGE=supabase

### Railway Deployment
plugins: { postgresql: { enabled: true }, redis: { enabled: true } }
variables: { SECRETS_ENABLE_PROJECTS: true, SECRETS_ENABLE_GROUPS: true, SECRET_STORAGE: memory }

## Security Considerations

1. Never expose secret values in logs
2. Use HTTPS for all API calls
3. Implement rate limiting
4. Enable audit logging
5. Regularly rotate secrets
6. Monitor for unusual access patterns
7. Use principle of least privilege

## Support

- Documentation: SECRETS_MANAGEMENT.md
- API Reference: See API Endpoints section
- Configuration: See Configuration section
- Issues: https://github.com/OrgHide/open-connect/issues

## Summary

XStack professional secrets management provides:
- Enterprise-grade organization with categories, groups, and projects
- Advanced filtering and search capabilities
- Fine-grained access control for security
- Flexible metadata for custom use cases
- RESTful API for easy integration
- Production-ready for Railway and other platforms

Perfect for teams managing multiple projects, environments, and services with complex credential requirements.

*Last updated: July 17, 2026*
*Version: 2.0.0*
