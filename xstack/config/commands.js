/**
 * XStack Chat Command Configuration
 */

export const CHAT_COMMANDS = {
  '/open_xstack': {
    name: 'Open XStack Dashboard',
    description: 'Open the main XStack control plane dashboard',
    action: 'open_page',
    target: '/xstack',
    category: 'navigation'
  },
  '/open_resources': {
    name: 'Open Resources',
    description: 'Open the Resources inventory page',
    action: 'open_page',
    target: '/xstack/resources',
    category: 'resources'
  },
  '/open_connections': {
    name: 'Open Connections',
    description: 'Open the Connections management page',
    action: 'open_page',
    target: '/xstack/connections',
    category: 'connections'
  },
  '/open_marketplace': {
    name: 'Open Marketplace',
    description: 'Open the Marketplace for discovering new resources',
    action: 'open_page',
    target: '/xstack/marketplace',
    category: 'marketplace'
  },
  '/open_secrets': {
    name: 'Open Secrets',
    description: 'Open the Secrets management page',
    action: 'open_page',
    target: '/xstack/secrets',
    category: 'secrets'
  }
};

// Aliases
CHAT_COMMANDS['/xstack'] = CHAT_COMMANDS['/open_xstack'];
CHAT_COMMANDS['/resources'] = CHAT_COMMANDS['/open_resources'];
CHAT_COMMANDS['/connections'] = CHAT_COMMANDS['/open_connections'];
CHAT_COMMANDS['/marketplace'] = CHAT_COMMANDS['/open_marketplace'];
CHAT_COMMANDS['/secrets'] = CHAT_COMMANDS['/open_secrets'];

export function getCommand(commandName) {
  return CHAT_COMMANDS[commandName.toLowerCase()] || null;
}