/**
 * XStack External Connection Mappings
 */

export const EXTERNAL_CONNECTIONS = {
  openclaw: {
    id: 'openclaw',
    name: 'OpenClaw',
    description: 'OpenClaw AI platform for agents and workflows',
    type: 'platform',
    category: 'ai_platforms',
    endpoint: 'https://openclaw.ai/',
    apiEndpoint: 'https://api.openclaw.ai/',
    documentation: 'https://docs.openclaw.ai/',
    config: {
      baseUrl: 'https://api.openclaw.ai',
      apiVersion: 'v1',
      authentication: 'api_key'
    },
    provides: ['agents', 'workflows', 'skills'],
    status: 'available',
    integration: { type: 'mcp', mcpEndpoint: 'mcp://openclaw' },
    tags: ['ai', 'agents', 'workflows', 'automation']
  },
  swarmclaw: {
    id: 'swarmclaw',
    name: 'SwarmClaw',
    description: 'SwarmClaw - AI agent orchestration platform',
    type: 'platform',
    category: 'ai_platforms',
    endpoint: 'https://www.swarmclaw.ai/',
    apiEndpoint: 'https://api.swarmclaw.ai/',
    documentation: 'https://docs.swarmclaw.ai/',
    config: {
      baseUrl: 'https://api.swarmclaw.ai',
      apiVersion: 'v1',
      authentication: 'api_key'
    },
    provides: ['agents', 'swarms', 'tasks'],
    status: 'available',
    integration: { type: 'mcp', mcpEndpoint: 'mcp://swarmclaw' },
    tags: ['ai', 'agents', 'swarm-intelligence', 'orchestration']
  },
  swarmdock: {
    id: 'swarmdock',
    name: 'SwarmDock',
    description: 'SwarmDock - Containerized AI agent deployment',
    type: 'platform',
    category: 'ai_platforms',
    endpoint: 'https://www.swarmdock.ai/',
    apiEndpoint: 'https://api.swarmdock.ai/',
    documentation: 'https://docs.swarmdock.ai/',
    config: {
      baseUrl: 'https://api.swarmdock.ai',
      apiVersion: 'v1',
      authentication: 'api_key'
    },
    provides: ['deployments', 'containers', 'agents'],
    status: 'available',
    integration: { type: 'docker', mcpEndpoint: 'mcp://swarmdock' },
    tags: ['ai', 'docker', 'containers', 'deployment']
  }
};

export function getConnection(connectionId) {
  return EXTERNAL_CONNECTIONS[connectionId.toLowerCase()] || null;
}

export function listConnections(filter = {}) {
  const connections = Object.values(EXTERNAL_CONNECTIONS);
  if (filter.category) {
    return connections.filter(conn => conn.category === filter.category);
  }
  return connections;
}