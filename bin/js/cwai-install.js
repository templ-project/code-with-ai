#!/usr/bin/env node

import { installCommand } from '../../src/commands/install.js';

installCommand().catch((error) => {
  console.error('Installation failed:', error.message);
  process.exit(1);
});
