/**
 * Registry Index Service
 */

import { v4 as uuidv4 } from 'uuid';

class RegistryIndex {
  constructor() {
    this.resources = new Map();
    this.categories = new Map();
    this.tags = new Map();
    this.providers = new Map();
    this.searchIndex = new Map();
  }

  async initialize() {
    console.log('🚀 Initializing Registry Index...');
    await this.loadDefaultResources();
    this.buildSearchIndex();
    console.log('✅ Registry Index initialized');
  }

  async loadDefaultResources() {
    const defaultResources = [
      {
        id: 'openclaw',
        type: 'external_connection',
        name: 'OpenClaw',
        description: 'OpenClaw AI platform for agents and workflows',
        provider: 'openclaw',
        version: '1.0.0',
        category: 'ai_platforms',
        tags: ['ai', 'agents', 'workflows', 'automation', 'external'],
        connection: { type: 'mcp', endpoint: 'mcp://openclaw' },
        permissions: ['read', 'connect'],
        requires: [],
        status: 'available',
        metadata: { external: true, source: 'https://openclaw.ai/', documentation: 'https://docs.openclaw.ai/' }
      },
      {
        id: 'swarmclaw',
        type: 'external_connection',
        name: 'SwarmClaw',
        description: 'SwarmClaw - AI agent orchestration platform',
        provider: 'swarmclaw',
        version: '1.0.0',
        category: 'ai_platforms',
        tags: ['ai', 'agents', 'swarm-intelligence', 'orchestration', 'external'],
        connection: { type: 'mcp', endpoint: 'mcp://swarmclaw' },
        permissions: ['read', 'connect'],
        requires: [],
        status: 'available',
        metadata: { external: true, source: 'https://www.swarmclaw.ai/', documentation: 'https://docs.swarmclaw.ai/' }
      },
      {
        id: 'swarmdock',
        type: 'external_connection',
        name: 'SwarmDock',
        description: 'SwarmDock - Containerized AI agent deployment',
        provider: 'swarmdock',
        version: '1.0.0',
        category: 'ai_platforms',
        tags: ['ai', 'docker', 'containers', 'deployment', 'external'],
        connection: { type: 'docker', endpoint: 'mcp://swarmdock' },
        permissions: ['read', 'connect'],
        requires: [],
        status: 'available',
        metadata: { external: true, source: 'https://www.swarmdock.ai/', documentation: 'https://docs.swarmdock.ai/' }
      }
    ];

    for (const resource of defaultResources) {
      await this.registerResource(resource);
    }
    console.log(`✅ Loaded ${defaultResources.length} default resources`);
  }

  async registerResource(resource) {
    const resourceId = resource.id || uuidv4();
    const resourceObj = {
      id: resourceId,
      type: resource.type,
      name: resource.name,
      description: resource.description || '',
      provider: resource.provider || 'unknown',
      version: resource.version || '1.0.0',
      category: resource.category || 'other',
      tags: resource.tags || [],
      connection: resource.connection || {},
      permissions: resource.permissions || [],
      requires: resource.requires || [],
      status: resource.status || 'available',
      metadata: resource.metadata || {},
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      usageCount: 0,
      lastUsed: null
    };

    this.resources.set(resourceId, resourceObj);
    this.indexResource(resourceObj);
    return { success: true, resourceId, resource: resourceObj };
  }

  indexResource(resource) {
    if (!this.categories.has(resource.category)) {
      this.categories.set(resource.category, new Set());
    }
    this.categories.get(resource.category).add(resource.id);

    if (!this.providers.has(resource.provider)) {
      this.providers.set(resource.provider, new Set());
    }
    this.providers.get(resource.provider).add(resource.id);

    resource.tags.forEach(tag => {
      if (!this.tags.has(tag)) {
        this.tags.set(tag, new Set());
      }
      this.tags.get(tag).add(resource.id);
    });

    this.addToSearchIndex(resource);
  }

  addToSearchIndex(resource) {
    const searchTerms = [resource.id, resource.name, resource.description, resource.provider, ...resource.tags, ...resource.type.split('/')];
    searchTerms.forEach(term => {
      const normalizedTerm = term.toLowerCase().trim();
      if (normalizedTerm) {
        if (!this.searchIndex.has(normalizedTerm)) {
          this.searchIndex.set(normalizedTerm, new Set());
        }
        this.searchIndex.get(normalizedTerm).add(resource.id);
      }
    });
  }

  buildSearchIndex() {
    this.searchIndex.clear();
    for (const resource of this.resources.values()) {
      this.addToSearchIndex(resource);
    }
  }

  search(query, options = {}) {
    const { type, category, provider, tags, status, limit = 50, offset = 0 } = options;
    let resourceIds = new Set();

    if (query) {
      const searchTerms = query.toLowerCase().split(/\s+/);
      searchTerms.forEach(term => {
        if (this.searchIndex.has(term)) {
          this.searchIndex.get(term).forEach(id => resourceIds.add(id));
        }
      });
    }

    let filteredResources = Array.from(resourceIds.values())
      .map(id => this.resources.get(id))
      .filter(Boolean);

    if (type) filteredResources = filteredResources.filter(r => r.type === type);
    if (category) filteredResources = filteredResources.filter(r => r.category === category);
    if (provider) filteredResources = filteredResources.filter(r => r.provider === provider);
    if (tags && tags.length > 0) filteredResources = filteredResources.filter(r => tags.some(tag => r.tags.includes(tag)));
    if (status) filteredResources = filteredResources.filter(r => r.status === status);

    const finalResourceIds = new Set(filteredResources.map(r => r.id));
    const results = Array.from(finalResourceIds.values())
      .slice(offset, offset + limit)
      .map(id => this.resources.get(id))
      .filter(Boolean);

    return { success: true, query, results, total: finalResourceIds.size, limit, offset };
  }

  getResource(resourceId) {
    const resource = this.resources.get(resourceId);
    if (!resource) throw new Error(`Resource ${resourceId} not found`);
    return { success: true, resource };
  }

  updateResource(resourceId, updates) {
    const resource = this.resources.get(resourceId);
    if (!resource) throw new Error(`Resource ${resourceId} not found`);
    Object.assign(resource, updates, { updatedAt: new Date().toISOString() });
    if (updates.tags || updates.category || updates.provider) this.rebuildIndexes();
    return { success: true, resource };
  }

  removeResource(resourceId) {
    const resource = this.resources.get(resourceId);
    if (!resource) throw new Error(`Resource ${resourceId} not found`);
    this.resources.delete(resourceId);
    this.rebuildIndexes();
    return { success: true, message: `Resource ${resourceId} removed` };
  }

  rebuildIndexes() {
    this.categories.clear();
    this.tags.clear();
    this.providers.clear();
    for (const resource of this.resources.values()) {
      this.indexResource(resource);
    }
    this.buildSearchIndex();
  }

  getStats() {
    return {
      success: true,
      totalResources: this.resources.size,
      categories: Object.fromEntries(Array.from(this.categories.entries()).map(([category, ids]) => [category, ids.size])),
      providers: Object.fromEntries(Array.from(this.providers.entries()).map(([provider, ids]) => [provider, ids.size])),
      tags: Object.fromEntries(Array.from(this.tags.entries()).map(([tag, ids]) => [tag, ids.size]))
    };
  }
}

const registryIndex = new RegistryIndex();

export const initializeRegistry = async (app) => {
  await registryIndex.initialize();
  app.set('registry', registryIndex);
  return registryIndex;
};

export default registryIndex;