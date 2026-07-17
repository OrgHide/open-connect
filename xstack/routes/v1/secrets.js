/**
 * XStack Secrets API Routes
 * Professional secret management with categories, groups, and projects
 */

import { SecretBroker, SECRET_CATEGORIES, DEFAULT_CATEGORIES } from '../../services/secrets/index.js';

export function setupSecretsRoutes(app) {
  const secretBroker = new SecretBroker();

  // GET /api/v1/secrets - List all secrets with filtering and search
  app.get('/api/v1/secrets', async (req, res) => {
    try {
      const {
        category,
        projectId,
        groupId,
        search,
        tags,
        includeGlobal = true,
        includeValues = false
      } = req.query;

      const tagArray = tags ? tags.split(',').map(t => t.trim()) : [];

      const secrets = await secretBroker.listSecrets({
        category,
        projectId,
        groupId,
        search,
        tags: tagArray,
        includeGlobal: includeGlobal === 'true',
        includeValues: includeValues === 'true'
      }, req.context || {});

      res.json({
        success: true,
        data: secrets,
        count: secrets.length,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // GET /api/v1/secrets/:id - Get secret metadata or full secret
  app.get('/api/v1/secrets/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const { includeValue = 'false' } = req.query;

      const secret = includeValue === 'true' 
        ? await secretBroker.getSecret(id, req.context || {})
        : await secretBroker.getSecretMetadata(id, req.context || {});

      if (!secret) {
        return res.status(404).json({
          success: false,
          error: 'Secret not found',
          timestamp: new Date().toISOString()
        });
      }

      res.json({
        success: true,
        data: secret,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('Access denied') ? 403 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // POST /api/v1/secrets - Create new secret
  app.post('/api/v1/secrets', async (req, res) => {
    try {
      const {
        name,
        value,
        category = SECRET_CATEGORIES.CUSTOM,
        description = '',
        tags = [],
        groupId,
        projectId,
        isGlobal = false,
        metadata = {}
      } = req.body;

      if (!name || !value) {
        return res.status(400).json({
          success: false,
          error: 'Name and value are required',
          timestamp: new Date().toISOString()
        });
      }

      const secret = await secretBroker.createSecret({
        name,
        value,
        category,
        description,
        tags,
        groupId,
        projectId,
        isGlobal,
        metadata
      });

      res.status(201).json({
        success: true,
        data: secret,
        message: 'Secret created successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // PUT /api/v1/secrets/:id - Update secret
  app.put('/api/v1/secrets/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const updates = req.body;

      const secret = await secretBroker.updateSecret(id, updates, req.context || {});

      if (!secret) {
        return res.status(404).json({
          success: false,
          error: 'Secret not found',
          timestamp: new Date().toISOString()
        });
      }

      res.json({
        success: true,
        data: secret,
        message: 'Secret updated successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('Access denied') ? 403 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // DELETE /api/v1/secrets/:id - Remove secret
  app.delete('/api/v1/secrets/:id', async (req, res) => {
    try {
      const { id } = req.params;

      await secretBroker.deleteSecret(id, req.context || {});

      res.json({
        success: true,
        message: 'Secret removed successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('Access denied') ? 403 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // GET /api/v1/secrets/categories - List all categories
  app.get('/api/v1/secrets/categories', async (req, res) => {
    try {
      const categories = await secretBroker.listCategories();

      res.json({
        success: true,
        data: categories,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // POST /api/v1/secrets/search - Advanced search across all secrets
  app.post('/api/v1/secrets/search', async (req, res) => {
    try {
      const { query, projectId, includeGlobal = true } = req.body;

      if (!query) {
        return res.status(400).json({
          success: false,
          error: 'Search query is required',
          timestamp: new Date().toISOString()
        });
      }

      const results = await secretBroker.searchSecrets(
        { query, projectId, includeGlobal },
        req.context || {}
      );

      res.json({
        success: true,
        data: results,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // GET /api/v1/secrets/project/:projectId - Get secrets organized by project
  app.get('/api/v1/secrets/project/:projectId', async (req, res) => {
    try {
      const { projectId } = req.params;

      const organized = await secretBroker.getSecretsByProject(projectId, req.context || {});

      res.json({
        success: true,
        data: organized,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('not found') ? 404 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // GROUP ENDPOINTS

  app.get('/api/v1/secrets/groups', async (req, res) => {
    try {
      const { projectId } = req.query;
      const groups = await secretBroker.listGroups(projectId);

      res.json({
        success: true,
        data: groups,
        count: groups.length,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.get('/api/v1/secrets/groups/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const group = await secretBroker.getGroup(id);

      if (!group) {
        return res.status(404).json({
          success: false,
          error: 'Group not found',
          timestamp: new Date().toISOString()
        });
      }

      const secrets = await secretBroker.listSecrets({ groupId: id, includeValues: false });

      res.json({
        success: true,
        data: {
          ...group,
          secrets,
          secretCount: secrets.length
        },
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.post('/api/v1/secrets/groups', async (req, res) => {
    try {
      const { name, description = '', projectId } = req.body;

      if (!name) {
        return res.status(400).json({
          success: false,
          error: 'Group name is required',
          timestamp: new Date().toISOString()
        });
      }

      const group = await secretBroker.createGroup({ name, description, projectId });

      res.status(201).json({
        success: true,
        data: group,
        message: 'Group created successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.put('/api/v1/secrets/groups/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const { name, description } = req.body;

      const group = await secretBroker.getGroup(id);
      if (!group) {
        return res.status(404).json({
          success: false,
          error: 'Group not found',
          timestamp: new Date().toISOString()
        });
      }

      if (name) group.name = name;
      if (description !== undefined) group.description = description;
      group.updatedAt = new Date().toISOString();

      res.json({
        success: true,
        data: group,
        message: 'Group updated successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.delete('/api/v1/secrets/groups/:id', async (req, res) => {
    try {
      const { id } = req.params;
      await secretBroker.deleteGroup(id);

      res.json({
        success: true,
        message: 'Group removed successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.post('/api/v1/secrets/groups/:groupId/secrets/:secretId', async (req, res) => {
    try {
      const { groupId, secretId } = req.params;
      const group = await secretBroker.addSecretToGroup(groupId, secretId);

      res.json({
        success: true,
        data: group,
        message: 'Secret added to group successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('not found') ? 404 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.delete('/api/v1/secrets/groups/:groupId/secrets/:secretId', async (req, res) => {
    try {
      const { groupId, secretId } = req.params;
      const group = await secretBroker.removeSecretFromGroup(groupId, secretId);

      res.json({
        success: true,
        data: group,
        message: 'Secret removed from group successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('not found') ? 404 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  // PROJECT ENDPOINTS

  app.get('/api/v1/secrets/projects', async (req, res) => {
    try {
      const projects = await secretBroker.listProjects();

      res.json({
        success: true,
        data: projects,
        count: projects.length,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.get('/api/v1/secrets/projects/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const project = await secretBroker.getProject(id);

      if (!project) {
        return res.status(404).json({
          success: false,
          error: 'Project not found',
          timestamp: new Date().toISOString()
        });
      }

      const groups = await secretBroker.listGroups(id);
      const secrets = await secretBroker.listSecrets({ projectId: id, includeValues: false });

      res.json({
        success: true,
        data: {
          ...project,
          groups,
          secrets,
          groupCount: groups.length,
          secretCount: secrets.length
        },
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.post('/api/v1/secrets/projects', async (req, res) => {
    try {
      const { name, description = '', groupIds = [] } = req.body;

      if (!name) {
        return res.status(400).json({
          success: false,
          error: 'Project name is required',
          timestamp: new Date().toISOString()
        });
      }

      const project = await secretBroker.createProject({ name, description, groupIds });

      res.status(201).json({
        success: true,
        data: project,
        message: 'Project created successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.put('/api/v1/secrets/projects/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const { name, description } = req.body;

      const project = await secretBroker.getProject(id);
      if (!project) {
        return res.status(404).json({
          success: false,
          error: 'Project not found',
          timestamp: new Date().toISOString()
        });
      }

      if (name) project.name = name;
      if (description !== undefined) project.description = description;
      project.updatedAt = new Date().toISOString();

      res.json({
        success: true,
        data: project,
        message: 'Project updated successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.delete('/api/v1/secrets/projects/:id', async (req, res) => {
    try {
      const { id } = req.params;
      await secretBroker.deleteProject(id);

      res.json({
        success: true,
        message: 'Project removed successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.post('/api/v1/secrets/projects/:projectId/groups/:groupId', async (req, res) => {
    try {
      const { projectId, groupId } = req.params;
      const project = await secretBroker.getProject(projectId);

      if (!project) {
        return res.status(404).json({
          success: false,
          error: 'Project not found',
          timestamp: new Date().toISOString()
        });
      }

      if (!project.groupIds.includes(groupId)) {
        project.groupIds.push(groupId);
        project.updatedAt = new Date().toISOString();
      }

      res.json({
        success: true,
        data: project,
        message: 'Group added to project successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });

  app.post('/api/v1/secrets/projects/:projectId/secrets/:secretId', async (req, res) => {
    try {
      const { projectId, secretId } = req.params;
      const project = await secretBroker.addSecretToProject(projectId, secretId);

      res.json({
        success: true,
        data: project,
        message: 'Secret added to project successfully',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(error.message.includes('not found') ? 404 : 500).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });
}
