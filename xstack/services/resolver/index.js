/**
 * Resource Resolver Service
 * Core service that routes resource requests to their actual locations
 */

import { v4 as uuidv4 } from 'uuid';

class ResourceResolver {
  constructor() {
    this.resourceMap = new Map();
    this.connectionPool = new Map();
    this.metrics = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      averageResponseTime: 0
    };
  }

  async initialize() {
    console.log('🚀 Initializing Resource Resolver...');
    await this.loadResourceMappings();
    setInterval(() => this.cleanupConnections(), 300000);
    console.log('✅ Resource Resolver initialized');
  }

  async loadResourceMappings() {
    console.log('📚 Loading resource mappings...');
  }

  async registerResource(resourceId, resourceType, location, connectionDetails) {
    const resourceKey = `${resourceType}:${resourceId}`;
    this.resourceMap.set(resourceKey, {
      id: resourceId,
      type: resourceType,
      location,
      connectionDetails,
      registeredAt: new Date().toISOString(),
      lastUsed: null,
      usageCount: 0
    });
    return { success: true, resourceKey };
  }

  async resolve(resourceIdentifier, options = {}) {
    const startTime = Date.now();
    const requestId = uuidv4();
    this.metrics.totalRequests++;

    try {
      const { resourceType, resourceId } = this.parseResourceIdentifier(resourceIdentifier);
      const resourceKey = `${resourceType}:${resourceId}`;
      const resource = this.resourceMap.get(resourceKey);

      if (!resource) {
        throw new Error(`Resource ${resourceIdentifier} not found`);
      }

      const result = await this.invokeResource(resource, options);
      const responseTime = Date.now() - startTime;
      this.metrics.successfulRequests++;
      resource.lastUsed = new Date().toISOString();
      resource.usageCount++;

      return { success: true, resource: resourceIdentifier, result, responseTime, requestId };
    } catch (error) {
      this.metrics.failedRequests++;
      throw new Error(`Failed to resolve resource: ${error.message}`);
    }
  }

  parseResourceIdentifier(identifier) {
    const parts = identifier.split('/');
    if (identifier.includes(':')) {
      const [provider, rest] = identifier.split(':');
      const repoParts = rest.split('/');
      return { resourceType: 'external', resourceId: repoParts.pop(), provider };
    }
    if (parts.length >= 3 && parts[0] === 'xstack') {
      return { resourceType: parts[1], resourceId: parts[2], version: null };
    }
    return { resourceType: 'skill', resourceId: identifier, version: null };
  }

  async invokeResource(resource, options) {
    return { data: `Response from ${resource.id}`, source: resource.location };
  }

  cleanupConnections() {
    const now = Date.now();
    for (const [key, connection] of this.connectionPool.entries()) {
      if (connection.lastUsed && (now - connection.lastUsed) > 300000) {
        this.connectionPool.delete(key);
      }
    }
  }

  getMetrics() {
    return { ...this.metrics, registeredResources: this.resourceMap.size };
  }
}

const resourceResolver = new ResourceResolver();

export const initializeResourceResolver = async (app) => {
  await resourceResolver.initialize();
  app.set('resourceResolver', resourceResolver);
  return resourceResolver;
};

export default resourceResolver;