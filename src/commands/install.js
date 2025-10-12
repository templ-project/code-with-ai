import { input, select } from '@inquirer/prompts';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'node:path';
import os from 'node:os';
import { execa } from 'execa';
import { getAbsolutePath } from '../utils/helpers.js';
import { logError, logInfo, logSuccess, logWarn } from '../utils/logger.js';

const LOGO = `
   _____                _____
  / ____|           _  |_   _|
 | |     __      _ / \\   | |
 | |     \\ \\ /\\ / / / \\  | |
 | |____  \\ V  V / ____\\_| |_
  \\_____|  \\_/\\_/_/    \\_____/

            C w A I
          Code with AI
`;

const REPO_URL = 'https://github.com/templ-project/code-with-ai.git';

export async function installCommand() {
  console.log(chalk.blue(LOGO));
  
  logInfo(`Bash version check skipped (Node.js ${process.version})`);

  // Clone repo to temp directory
  const tempDir = path.join(os.tmpdir(), `cwai-install-${Date.now()}`);
  let cwaiSourceDir;
  
  try {
    logInfo('Cloning code-with-ai repository...');
    await execa('git', ['clone', '--depth', '1', REPO_URL, tempDir]);
    logInfo(`Repository cloned to ${tempDir}`);
    
    cwaiSourceDir = path.join(tempDir, '.cwai');
    
    if (!(await fs.pathExists(cwaiSourceDir))) {
      logError(`Source .cwai directory not found in cloned repo: ${cwaiSourceDir}`);
    }
  } catch (error) {
    logError(`Failed to clone repository: ${error.message}`);
  }

  // Select AI Client
  const selectedAiClient = await select({
    message: 'What AI Client do you want to install CwAI for?',
    choices: [
      { name: 'VSCode Copilot', value: 'vscode' },
      { name: 'Claude', value: 'claude' },
      { name: 'Gemini', value: 'gemini' }
    ]
  });

  logInfo(`Selected AI Client: ${getClientDisplayName(selectedAiClient)}`);

  // Select install type
  const installType = await select({
    message: 'How do you want to install CwAI?',
    choices: [
      { name: 'Locally (in project)', value: 'local' },
      { name: 'Globally', value: 'global' }
    ]
  });

  // Get target path
  let targetPath;
  if (installType === 'local') {
    const projectPath = await input({
      message: 'Please provide the path to the project:',
      validate: async (value) => {
        if (!value) return 'Path cannot be empty';
        const absPath = getAbsolutePath(value);
        if (!(await fs.pathExists(absPath))) {
          return 'Path does not exist';
        }
        const stat = await fs.stat(absPath);
        if (!stat.isDirectory()) {
          return 'Path is not a directory';
        }
        return true;
      }
    });
    targetPath = getAbsolutePath(projectPath);
  } else {
    targetPath = getGlobalInstallPath(selectedAiClient);
  }

  logInfo(`Target path: ${targetPath}`);

  // Check existing installation
  await checkExistingInstallation(targetPath, selectedAiClient);

  // Install prompts
  await installPrompts(cwaiSourceDir, targetPath, selectedAiClient);

  // Install .cwai folder
  await installCwaiFolder(cwaiSourceDir, targetPath);

  // Cleanup temporary directory
  try {
    logInfo('Cleaning up temporary files...');
    await fs.remove(tempDir);
    logInfo('Temporary files removed');
  } catch (error) {
    logWarn(`Failed to remove temporary directory: ${error.message}`);
  }

  // Success message
  console.log('');
  logSuccess('CwAI installation completed successfully!');
  console.log('\nInstallation Summary:');
  console.log(`  AI Client: ${getClientDisplayName(selectedAiClient)}`);
  console.log(`  Install Type: ${installType}`);
  console.log(`  Target Path: ${targetPath}`);
  console.log(`  CwAI Assets: ${path.join(targetPath, '.cwai')}`);

  // Show client-specific paths
  if (selectedAiClient === 'vscode') {
    console.log(`  Prompts: ${path.join(targetPath, '.github/prompts/*.prompt.md')}`);
  } else if (selectedAiClient === 'claude') {
    console.log(`  Prompts: ${path.join(targetPath, 'prompts/*.md')}`);
  } else if (selectedAiClient === 'gemini') {
    console.log(`  Templates: ${path.join(targetPath, 'templates/*.md')}`);
  }

  console.log(`\nYou can now start using CwAI with your ${getClientDisplayName(selectedAiClient)}!`);
}

function getClientDisplayName(client) {
  const map = {
    vscode: 'VSCode Copilot',
    claude: 'Claude',
    gemini: 'Gemini'
  };
  return map[client] || client;
}

function getGlobalInstallPath(client) {
  const home = process.env.HOME || process.env.USERPROFILE || '';
  
  if (client === 'vscode') {
    if (process.platform === 'darwin') {
      return path.join(home, 'Library/Application Support/Code/User/globalStorage/github.copilot');
    }
    return path.join(home, '.vscode/extensions/github.copilot');
  } else if (client === 'claude') {
    return path.join(home, '.config/claude');
  } else if (client === 'gemini') {
    return path.join(home, '.config/gemini');
  }
  
  logError(`Unknown AI client: ${client}`);
}

async function checkExistingInstallation(targetPath, selectedAiClient) {
  const existingPaths = [];

  // Check for client-specific paths
  if (selectedAiClient === 'vscode') {
    const githubPromptsPath = path.join(targetPath, '.github/prompts');
    if (await fs.pathExists(githubPromptsPath)) {
      existingPaths.push(githubPromptsPath);
    }
  } else if (selectedAiClient === 'claude') {
    const promptsPath = path.join(targetPath, 'prompts');
    if (await fs.pathExists(promptsPath)) {
      existingPaths.push(promptsPath);
    }
  } else if (selectedAiClient === 'gemini') {
    const templatesPath = path.join(targetPath, 'templates');
    if (await fs.pathExists(templatesPath)) {
      existingPaths.push(templatesPath);
    }
  }

  // Check for .cwai folder
  const cwaiPath = path.join(targetPath, '.cwai');
  if (await fs.pathExists(cwaiPath)) {
    existingPaths.push(cwaiPath);
  }

  if (existingPaths.length > 0) {
    console.log('\nExisting CwAI installation detected at:');
    for (const p of existingPaths) {
      console.log(`  - ${p}`);
    }

    const action = await select({
      message: 'How should we proceed?',
      choices: [
        { name: 'Copy Over Existing', value: 'overwrite' },
        { name: 'Remove folders and copy again', value: 'remove' }
      ]
    });

    if (action === 'remove') {
      logInfo('Removing existing installation...');
      for (const p of existingPaths) {
        await fs.remove(p);
        logInfo(`Removed: ${p}`);
      }
    } else {
      logInfo('Will copy over existing installation');
    }
  }
}

async function installPrompts(cwaiSourceDir, targetPath, selectedAiClient) {
  const srcPromptsDir = path.join(cwaiSourceDir, 'prompts');

  if (!(await fs.pathExists(srcPromptsDir))) {
    logError(`Source prompts directory not found: ${srcPromptsDir}`);
  }

  if (selectedAiClient === 'vscode') {
    await installVscodePrompts(srcPromptsDir, targetPath);
  } else if (selectedAiClient === 'claude') {
    await installClaudePrompts(srcPromptsDir, targetPath);
  } else if (selectedAiClient === 'gemini') {
    await installGeminiPrompts(srcPromptsDir, targetPath);
  }

  logSuccess(`Prompts installed successfully for ${getClientDisplayName(selectedAiClient)}`);
}

async function installVscodePrompts(srcPromptsDir, targetPath) {
  const destDir = path.join(targetPath, '.github/prompts');
  logInfo(`Installing VSCode Copilot prompts to ${destDir}`);

  await fs.ensureDir(destDir);

  const files = await fs.readdir(srcPromptsDir);
  for (const file of files) {
    if (file.endsWith('.md')) {
      const srcFile = path.join(srcPromptsDir, file);
      const baseName = path.basename(file, '.md');
      const destFile = path.join(destDir, `${baseName}.prompt.md`);

      await fs.copy(srcFile, destFile);
      logInfo(`Installed: ${baseName}.prompt.md`);
    }
  }
}

async function installClaudePrompts(srcPromptsDir, targetPath) {
  const destDir = path.join(targetPath, 'prompts');
  logInfo(`Installing Claude prompts to ${destDir}`);

  await fs.ensureDir(destDir);

  const files = await fs.readdir(srcPromptsDir);
  for (const file of files) {
    if (file.endsWith('.md')) {
      const srcFile = path.join(srcPromptsDir, file);
      const destFile = path.join(destDir, file);

      await fs.copy(srcFile, destFile);
      logInfo(`Installed: ${file}`);
    }
  }
}

async function installGeminiPrompts(srcPromptsDir, targetPath) {
  const destDir = path.join(targetPath, 'templates');
  logInfo(`Installing Gemini prompts to ${destDir}`);

  await fs.ensureDir(destDir);

  const files = await fs.readdir(srcPromptsDir);
  for (const file of files) {
    if (file.endsWith('.md')) {
      const srcFile = path.join(srcPromptsDir, file);
      const destFile = path.join(destDir, file);

      await fs.copy(srcFile, destFile);
      logInfo(`Installed: ${file}`);
    }
  }
}

async function installCwaiFolder(cwaiSourceDir, targetPath) {
  const destCwai = path.join(targetPath, '.cwai');

  logInfo(`Installing .cwai folder from ${cwaiSourceDir} to ${destCwai}`);

  await fs.ensureDir(targetPath);
  await fs.copy(cwaiSourceDir, destCwai);

  logSuccess('.cwai folder installed successfully');
}
