/**
 * Health Routes
 */

import { Router } from 'express';
const router = Router();

router.get('/', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'XStack Gateway'
  });
});

router.get('/readiness', (req, res) => {
  const app = req.app;
  const allReady = app.get('resourceResolver') && app.get('registry') && app.get('connectionManager') && app.get('secretBroker');
  res.json({
    success: true,
    status: allReady ? 'ready' : 'not_ready',
    timestamp: new Date().toISOString()
  });
});

router.get('/liveness', (req, res) => {
  res.json({
    success: true,
    status: 'alive',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

export default router;