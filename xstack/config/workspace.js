/**
 * XStack Workspace Configuration
 * Manages workspace settings and environment configurations
 */

export const WORKSPACE_CONFIG = {
  name: 'XStack Open-Connect',
  environment: process.env.NODE_ENV || 'development',
  server: {
    host: process.env.HOST || '0.0.0.0',
    port: parseInt(process.env.PORT || '3000'),
    baseUrl: process.env.BASE_URL || 'http://localhost:3000',
    cors: {
      origin: process.env.CORS_ORIGIN || '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization']
    },
    rateLimit: {
      windowMs: 15 * 60 * 1000,
      max: 100
    }
  },
  database: {
    postgres: {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'xstack',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || '',
      ssl: process.env.DB_SSL === 'true'
    },
    redis: {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || '',
      db: parseInt(process.env.REDIS_DB || '0')
    }
  },
  externalServices: {
    mcpGateway: process.env.MCP_GATEWAY || 'mcp://gateway',
    connections: {
      openclaw: { mcp: 'mcp://openclaw', api: 'https://openclaw.ai/api', web: 'https://openclaw.ai/' },
      swarmclaw: { mcp: 'mcp://swarmclaw', api: 'https://www.swarmclaw.ai/api', web: 'https://www.swarmclaw.ai/' },
      swarmdock: { mcp: 'mcp://swarmdock', api: 'https://www.swarmdock.ai/api', web: 'https://www.swarmdock.ai/' },
      skillsllm: { mcp: 'mcp://skillsllm', api: 'https://skillsllm.com/api', web: 'https://skillsllm.com/' },
      multion: { mcp: 'mcp://multion', api: 'https://docs.multion.ai/api', web: 'https://docs.multion.ai/welcome' },
      omni: { mcp: 'mcp://omni', api: 'https://docs.omni.co/api', web: 'https://docs.omni.co/developers/agent-skills' },
      openagent: { mcp: 'mcp://openagent', api: 'https://app.open-agent.io/api', web: 'https://app.open-agent.io/onboarding' },
      agentfield: { mcp: 'mcp://agentfield', api: 'https://agentfield.ai/api', web: 'https://agentfield.ai/' },
      agencyagents: { mcp: 'mcp://agencyagents', api: 'https://agencyagents.dev/api', web: 'https://agencyagents.dev/agents' },
      clawhub: { mcp: 'mcp://clawhub', api: 'https://clawhub.ai/api', web: 'https://clawhub.ai/plugins' }
    }
  },
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
    enableProjects: process.env.SECRETS_ENABLE_PROJECTS !== 'false',
    enableGroups: process.env.SECRETS_ENABLE_GROUPS !== 'false',
    enableGlobal: process.env.SECRETS_ENABLE_GLOBAL !== 'false',
    storage: process.env.SECRET_STORAGE || 'memory',
    maxSecretsPerProject: parseInt(process.env.SECRETS_MAX_PER_PROJECT || '1000'),
    enableSearch: process.env.SECRETS_ENABLE_SEARCH !== 'false'
  },
  security: {
    jwt: {
      secret: process.env.JWT_SECRET || 'xstack-secret-key',
      expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    },
    apiKeys: {
      enabled: process.env.API_KEYS_ENABLED === 'true',
      header: 'X-API-Key'
    },
    session: {
      secret: process.env.SESSION_SECRET || 'xstack-session-secret',
      maxAge: 24 * 60 * 60 * 1000
    }
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.LOG_FORMAT || 'json',
    output: process.env.LOG_OUTPUT || 'console'
  },
  cache: {
    enabled: process.env.CACHE_ENABLED !== 'false',
    ttl: parseInt(process.env.CACHE_TTL || '300')
  },
  features: {
    analytics: process.env.FEATURE_ANALYTICS !== 'false',
    auditLogs: process.env.FEATURE_AUDIT_LOGS !== 'false',
    rateLimiting: process.env.FEATURE_RATE_LIMITING !== 'false'
  }
};

export function getWorkspaceConfig() {
  return WORKSPACE_CONFIG;
}

export function getConfig(section) {
  return WORKSPACE_CONFIG[section] || {};
}

export function validateConfig() {
  const errors = [];
  if (WORKSPACE_CONFIG.environment === 'production') {
    if (!process.env.DB_HOST) errors.push('DB_HOST is required in production');
    if (!process.env.DB_PASSWORD) errors.push('DB_PASSWORD is required in production');
  }
  return { valid: errors.length === 0, errors };
}

export default WORKSPACE_CONFIG;
