/**
 * XStack Secret Broker Service
 * Professional secret management with categories, groups, and project isolation
 */

/**
 * Secret Category Definitions
 */
export const SECRET_CATEGORIES = {
  API_KEYS: 'api_keys',
  DATABASE: 'database',
  AUTHENTICATION: 'authentication',
  ENCRYPTION: 'encryption',
  THIRD_PARTY: 'third_party',
  INTERNAL: 'internal',
  CUSTOM: 'custom'
};

/**
 * Default secret categories with descriptions
 */
export const DEFAULT_CATEGORIES = [
  { id: SECRET_CATEGORIES.API_KEYS, name: 'API Keys', description: 'External API keys and tokens' },
  { id: SECRET_CATEGORIES.DATABASE, name: 'Database', description: 'Database connection credentials' },
  { id: SECRET_CATEGORIES.AUTHENTICATION, name: 'Authentication', description: 'Authentication tokens and session secrets' },
  { id: SECRET_CATEGORIES.ENCRYPTION, name: 'Encryption', description: 'Encryption keys and certificates' },
  { id: SECRET_CATEGORIES.THIRD_PARTY, name: 'Third Party', description: 'Third-party service credentials' },
  { id: SECRET_CATEGORIES.INTERNAL, name: 'Internal', description: 'Internal system secrets' },
  { id: SECRET_CATEGORIES.CUSTOM, name: 'Custom', description: 'User-defined categories' }
];

export class SecretBroker {
  constructor() {
    this.secrets = new Map();
    this.groups = new Map();
    this.projects = new Map();
    this.nextId = 1;
  }

  async createSecret(options) {
    const {
      name,
      value,
      category = SECRET_CATEGORIES.CUSTOM,
      description = '',
      tags = [],
      groupId = null,
      projectId = null,
      isGlobal = false,
      metadata = {}
    } = options;

    if (!name || !value) {
      throw new Error('Name and value are required');
    }

    const id = `secret_${this.nextId++}`;
    const secret = {
      id,
      name,
      value,
      category,
      description,
      tags: Array.isArray(tags) ? tags : [tags].filter(Boolean),
      groupId,
      projectId,
      isGlobal,
      metadata: metadata || {},
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      version: 1
    };

    this.secrets.set(id, secret);

    if (groupId) {
      await this.addSecretToGroup(groupId, id);
    }

    if (projectId) {
      await this.addSecretToProject(projectId, id);
    }

    return secret;
  }

  async getSecret(id, context = {}) {
    const secret = this.secrets.get(id);
    if (!secret) return null;

    if (!this.hasAccess(secret, context)) {
      throw new Error('Access denied to secret');
    }

    return { ...secret, value: secret.value };
  }

  async getSecretMetadata(id, context = {}) {
    const secret = this.secrets.get(id);
    if (!secret) return null;

    if (!this.hasAccess(secret, context)) {
      throw new Error('Access denied to secret');
    }

    const { value, ...metadata } = secret;
    return metadata;
  }

  async updateSecret(id, updates, context = {}) {
    const secret = this.secrets.get(id);
    if (!secret) {
      throw new Error('Secret not found');
    }

    if (!this.hasAccess(secret, context)) {
      throw new Error('Access denied to secret');
    }

    const updated = {
      ...secret,
      ...updates,
      updatedAt: new Date().toISOString(),
      version: secret.version + 1
    };

    this.secrets.set(id, updated);
    return updated;
  }

  async deleteSecret(id, context = {}) {
    const secret = this.secrets.get(id);
    if (!secret) {
      throw new Error('Secret not found');
    }

    if (!this.hasAccess(secret, context, true)) {
      throw new Error('Access denied to delete secret');
    }

    this.secrets.delete(id);

    if (secret.groupId) {
      await this.removeSecretFromGroup(secret.groupId, id);
    }
    if (secret.projectId) {
      await this.removeSecretFromProject(secret.projectId, id);
    }

    return true;
  }

  async listSecrets(options = {}, context = {}) {
    const {
      category,
      projectId,
      groupId,
      search,
      tags = [],
      includeGlobal = true,
      includeValues = false
    } = options;

    const secrets = Array.from(this.secrets.values());

    const accessibleSecrets = secrets.filter(secret =>
      this.hasAccess(secret, context)
    );

    let filtered = accessibleSecrets;

    if (category) {
      filtered = filtered.filter(s => s.category === category);
    }

    if (projectId) {
      filtered = filtered.filter(s => s.projectId === projectId || (s.isGlobal && includeGlobal));
    }

    if (groupId) {
      filtered = filtered.filter(s => s.groupId === groupId || (s.isGlobal && includeGlobal));
    }

    if (search) {
      const searchLower = search.toLowerCase();
      filtered = filtered.filter(s => 
        s.name.toLowerCase().includes(searchLower) ||
        s.description.toLowerCase().includes(searchLower) ||
        s.tags.some(tag => tag.toLowerCase().includes(searchLower))
      );
    }

    if (tags.length > 0) {
      filtered = filtered.filter(s => 
        tags.some(tag => s.tags.includes(tag))
      );
    }

    return filtered.map(secret => {
      const { value, ...rest } = secret;
      return includeValues ? secret : rest;
    });
  }

  async listCategories() {
    return DEFAULT_CATEGORIES;
  }

  async createGroup(options) {
    const { name, description = '', projectId = null } = options;

    if (!name) {
      throw new Error('Group name is required');
    }

    const id = `group_${this.nextId++}`;
    const group = {
      id,
      name,
      description,
      projectId,
      secretIds: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    this.groups.set(id, group);
    return group;
  }

  async getGroup(id) {
    return this.groups.get(id) || null;
  }

  async listGroups(projectId = null) {
    const groups = Array.from(this.groups.values());
    return projectId ? groups.filter(g => g.projectId === projectId) : groups;
  }

  async addSecretToGroup(groupId, secretId) {
    const group = this.groups.get(groupId);
    if (!group) {
      throw new Error('Group not found');
    }

    if (!group.secretIds.includes(secretId)) {
      group.secretIds.push(secretId);
      group.updatedAt = new Date().toISOString();
    }

    return group;
  }

  async removeSecretFromGroup(groupId, secretId) {
    const group = this.groups.get(groupId);
    if (!group) {
      throw new Error('Group not found');
    }

    group.secretIds = group.secretIds.filter(id => id !== secretId);
    group.updatedAt = new Date().toISOString();

    return group;
  }

  async deleteGroup(id) {
    const group = this.groups.get(id);
    if (!group) {
      throw new Error('Group not found');
    }

    const secrets = Array.from(this.secrets.values());
    secrets.forEach(secret => {
      if (secret.groupId === id) {
        secret.groupId = null;
      }
    });

    this.groups.delete(id);
    return true;
  }

  async createProject(options) {
    const { name, description = '', groupIds = [] } = options;

    if (!name) {
      throw new Error('Project name is required');
    }

    const id = `project_${this.nextId++}`;
    const project = {
      id,
      name,
      description,
      groupIds: Array.isArray(groupIds) ? groupIds : [groupIds].filter(Boolean),
      secretIds: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    this.projects.set(id, project);
    return project;
  }

  async getProject(id) {
    return this.projects.get(id) || null;
  }

  async listProjects() {
    return Array.from(this.projects.values());
  }

  async addSecretToProject(projectId, secretId) {
    const project = this.projects.get(projectId);
    if (!project) {
      throw new Error('Project not found');
    }

    if (!project.secretIds.includes(secretId)) {
      project.secretIds.push(secretId);
      project.updatedAt = new Date().toISOString();
    }

    return project;
  }

  async removeSecretFromProject(projectId, secretId) {
    const project = this.projects.get(projectId);
    if (!project) {
      throw new Error('Project not found');
    }

    project.secretIds = project.secretIds.filter(id => id !== secretId);
    project.updatedAt = new Date().toISOString();

    return project;
  }

  async deleteProject(id) {
    const project = this.projects.get(id);
    if (!project) {
      throw new Error('Project not found');
    }

    const secrets = Array.from(this.secrets.values());
    secrets.forEach(secret => {
      if (secret.projectId === id) {
        secret.projectId = null;
      }
    });

    this.projects.delete(id);
    return true;
  }

  hasAccess(secret, context = {}, forWrite = false) {
    if (secret.isGlobal) {
      return true;
    }

    if (secret.projectId) {
      if (context.projectId && context.projectId === secret.projectId) {
        return true;
      }
      if (context.isAdmin) {
        return true;
      }
      return false;
    }

    if (secret.groupId) {
      if (context.groupIds && context.groupIds.includes(secret.groupId)) {
        return true;
      }
      if (context.isAdmin) {
        return true;
      }
      return false;
    }

    return true;
  }

  async getSecretsByProject(projectId, context = {}) {
    const project = await this.getProject(projectId);
    if (!project) {
      throw new Error('Project not found');
    }

    const secrets = await this.listSecrets({ projectId, includeValues: false }, context);
    const groups = await this.listGroups(projectId);

    const organized = {
      project: {
        id: project.id,
        name: project.name,
        description: project.description
      },
      global: [],
      groups: {},
      ungrouped: []
    };

    secrets.forEach(secret => {
      if (secret.isGlobal) {
        organized.global.push(secret);
      } else if (secret.groupId) {
        if (!organized.groups[secret.groupId]) {
          organized.groups[secret.groupId] = {
            group: groups.find(g => g.id === secret.groupId),
            secrets: []
          };
        }
        organized.groups[secret.groupId].secrets.push(secret);
      } else {
        organized.ungrouped.push(secret);
      }
    });

    return organized;
  }

  async searchSecrets(options, context = {}) {
    const { query } = options;
    const projects = await this.listProjects();

    const results = {
      global: [],
      projects: {}
    };

    const globalSecrets = await this.listSecrets(
      { search: query, isGlobal: true, includeValues: false },
      context
    );
    results.global = globalSecrets;

    for (const project of projects) {
      const projectSecrets = await this.listSecrets(
        { search: query, projectId: project.id, includeValues: false },
        context
      );
      if (projectSecrets.length > 0) {
        results.projects[project.id] = {
          project,
          secrets: projectSecrets
        };
      }
    }

    return results;
  }
}

export default new SecretBroker();
