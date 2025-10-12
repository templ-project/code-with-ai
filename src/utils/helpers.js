import { execa, execaSync } from 'execa';
import fs from 'fs-extra';
import path from 'node:path';

/**
 * String manipulation utilities
 */

export function requirementToTitle(requirement) {
  return requirement
    .replace(/\n/g, ' ')
    .replace(/[^A-Za-z0-9_-]/g, ' ')
    .trim()
    .split(/\s+/)
    .slice(0, 5)
    .join(' ');
}

export function titleToSlug(title) {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function paddFeatureId(id) {
  return String(id).padStart(5, '0');
}

export function extractFeatureId(featureName) {
  const match = featureName.match(/^(\d{5})/);
  if (!match) return 0;
  return parseInt(match[1], 10);
}

export function detectFeatureName(requirement) {
  const match = requirement.match(/\d{5}-[a-z0-9][a-z0-9-]*/);
  if (!match) return '';
  return match[0];
}

/**
 * Array utilities
 */

export function joinByComma(arr) {
  return arr.join(',');
}

export function concatenateArrays(array1String, array2String) {
  const removeSet = new Set();
  const seenSet = new Set();
  const outList = [];

  const array1 = array1String ? array1String.split(',') : [];
  const array2 = array2String ? array2String.split(',') : [];

  // Build remove set from array2 (items starting with -)
  for (const item of array2) {
    if (item.startsWith('-') && item.length > 1) {
      removeSet.add(item.substring(1));
    }
  }

  // Add items from array1 that aren't in remove set
  for (const item of array1) {
    if (!item || removeSet.has(item) || seenSet.has(item)) continue;
    seenSet.add(item);
    outList.push(item);
  }

  // Add new items from array2
  for (const item of array2) {
    if (!item || item.startsWith('-') || seenSet.has(item)) continue;
    seenSet.add(item);
    outList.push(item);
  }

  return outList.join(',');
}

/**
 * Path utilities
 */

export function getAbsolutePath(inputPath) {
  // Expand tilde
  let resolvedPath = inputPath;
  if (resolvedPath.startsWith('~')) {
    resolvedPath = path.join(
      process.env.HOME || process.env.USERPROFILE || '',
      resolvedPath.slice(1)
    );
  }

  return path.resolve(resolvedPath);
}

export function getRepoRoot() {
  try {
    // Use git to find the repository root (the folder containing .git)
    const { stdout } = execaSync('git', ['rev-parse', '--show-toplevel']);
    return stdout.trim();
  } catch {
    // If git command fails (not in a git repo), use current working directory
    return process.cwd();
  }
}

/**
 * Git utilities
 */

export async function gitBranchExists(branchName) {
  try {
    await execa('git', ['rev-parse', '--verify', '--quiet', `refs/heads/${branchName}`]);
    return true;
  } catch {
    try {
      await execa('git', ['rev-parse', '--verify', '--quiet', `refs/remotes/origin/${branchName}`]);
      return true;
    } catch {
      return false;
    }
  }
}

export async function gitCheckout(branchName, createNew = false) {
  const args = ['checkout'];
  if (createNew) args.push('-b');
  args.push(branchName);
  await execa('git', args, { stdio: 'inherit' });
}

export async function getGitConfig(key) {
  try {
    const { stdout } = await execa('git', ['config', '--get', key]);
    return stdout.trim();
  } catch {
    return '';
  }
}

/**
 * Random color generator
 */

export function generateHexColor() {
  const randomInt = Math.floor(Math.random() * 16777216);
  return randomInt.toString(16).toUpperCase().padStart(6, '0');
}

/**
 * Output formatters
 */

export function outputResults(jsonResult, outputJson) {
  if (outputJson) {
    console.log(JSON.stringify(jsonResult, null, 2));
    return;
  }

  // Output as key=value pairs
  for (const [key, value] of Object.entries(jsonResult)) {
    let displayValue = value;
    if (Array.isArray(value)) {
      displayValue = value.join(',');
    } else if (typeof value === 'object') {
      displayValue = JSON.stringify(value);
    }
    console.log(`${key}="${displayValue}"`);
  }
}

/**
 * Environment loader
 */

export async function loadEnvironment(repoRoot) {
  const envFiles = [
    path.join(repoRoot, '.env'),
    path.join(repoRoot, '.env.local')
  ];

  for (const envFile of envFiles) {
    if (await fs.pathExists(envFile)) {
      const content = await fs.readFile(envFile, 'utf-8');
      for (const line of content.split('\n')) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const [key, ...valueParts] = trimmed.split('=');
        if (key && valueParts.length > 0) {
          process.env[key.trim()] = valueParts.join('=').trim();
        }
      }
    }
  }

  // Set defaults
  process.env.CWAI_SPECS_FOLDER = process.env.CWAI_SPECS_FOLDER || 'specs';
  process.env.CWAI_ISSUE_MANAGER = process.env.CWAI_ISSUE_MANAGER || 'localfs';
}
