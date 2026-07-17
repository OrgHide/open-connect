/**
 * Gateway Routes
 */

import { Router } from 'express';
const router = Router();

router.get('/status', (req, res) => {
  const app = req.app;
  const resourceResolver = app.get('resourceResolver');
  const registry = app.get('registry');
  const connectionManager = app.get('connectionManager');
  const secretBroker = app.get('secretBroker');

  res.json({
    success: true,
    status: {
      gateway: {
        name: process.env.GATEWAY_NAME || 'XStack Gateway',
        version: process.env.GATEWAY_VERSION || '1.0.0',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
      },
      services: {
        resourceResolver: resourceResolver ? 'healthy' : 'unhealthy',
        registry: registry ? 'healthy' : 'unhealthy',
        connectionManager: connectionManager ? 'healthy' : 'unhealthy',
        secretBroker: secretBroker ? 'healthy' : 'unhealthy'
      }
    }
  });
});

router.get('/config', (req, res) => {
  res.json({
    success: true,
    config: {
      name: process.env.GATEWAY_NAME || 'XStack Gateway',
      version: process.env.GATEWAY_VERSION || '1.0.0',
      environment: process.env.NODE_ENV || 'development'
    }
  });
});

router.get('/stats', (req, res) => {
  const app = req.app;
  const resourceResolver = app.get('resourceResolver');
  const registry = app.get('registry');
  const connectionManager = app.get('connectionManager');
  const secretBroker = app.get('secretBroker');

  res.json({
    success: true,
    stats: {
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      services: {
        resourceResolver: resourceResolver ? resourceResolver.getMetrics() : null,
        registry: registry ? registry.getStats() : null,
        connectionManager: connectionManager ? connectionManager.getStats() : null,
        secretBroker: secretBroker ? secretBroker.getStats() : null
      }
    }
  });
});

export default router;