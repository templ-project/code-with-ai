#!/usr/bin/env node

import { Command } from 'commander';
import { createFeatureCommand } from '../src/commands/create-feature.js';

const program = new Command();

program
  .name('cwai-create-feature')
  .description('Create a new feature or update an existing one')
  .argument('<requirement>', 'Feature requirement description')
  .option('--json', 'Output data as JSON instead of text')
  .option('--title <title>', 'Explicit title for the feature')
  .option('-t, --template <name...>', 'Templates to copy (can be used multiple times)')
  .option('-l, --labels <labels>', 'Labels to add to GitHub issue (comma separated)')
  .action(async (requirement, options) => {
    try {
      await createFeatureCommand(requirement, options);
    } catch (error) {
      console.error('Feature creation failed:', error.message);
      process.exit(1);
    }
  });

program.parse();
