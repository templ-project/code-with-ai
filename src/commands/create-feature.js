import fs from 'fs-extra';
import path from 'node:path';
import {
    detectFeatureName,
    extractFeatureId,
    getRepoRoot,
    gitBranchExists,
    gitCheckout,
    loadEnvironment,
    outputResults,
    paddFeatureId,
    requirementToTitle,
    titleToSlug
} from '../utils/helpers.js';
import { getIssueManager } from '../utils/issue-manager.js';
import { logError, logInfo, logWarn } from '../utils/logger.js';

export async function createFeatureCommand(requirement, options) {
  const repoRoot = getRepoRoot();
  await loadEnvironment(repoRoot);

  if (!requirement) {
    logError('Requirement is required. Provide the requirement as arguments.');
  }

  const specsFolder = process.env.CWAI_SPECS_FOLDER;
  const issueManagerType = process.env.CWAI_ISSUE_MANAGER;

  if (!specsFolder) {
    logError('Environment variable CWAI_SPECS_FOLDER is required');
  }
  if (!issueManagerType) {
    logError('Environment variable CWAI_ISSUE_MANAGER is required');
  }

  // Parse options
  const templates = options.template || [];
  const labels = parseLabels(options.labels);
  const title = options.title || '';
  const outputJson = options.json || false;

  // Detect if this is an existing feature or new
  const featureName = await detectFeatureNameAsync(requirement);

  if (featureName) {
    logInfo(`Detected existing feature reference: ${featureName}`);
    await updateExistingFeature(
      featureName,
      labels,
      requirement,
      templates,
      outputJson,
      specsFolder,
      issueManagerType
    );
  } else {
    logInfo('No existing feature reference found; creating new feature');
    await createNewFeature(
      requirement,
      title,
      labels,
      templates,
      outputJson,
      specsFolder,
      issueManagerType,
      repoRoot
    );
  }
}

async function createNewFeature(requirement, title, labels, templates, outputJson, specsFolder, issueManagerType, repoRoot) {
  const featureTitle = title || requirementToTitle(requirement);
  const featureSlug = titleToSlug(featureTitle);
  const featureParentDir = path.join(repoRoot, specsFolder);
  
  await fs.ensureDir(featureParentDir);

  const issueManager = getIssueManager(issueManagerType);
  const featureId = await issueManager.createIssue(
    featureSlug,
    featureTitle,
    featureParentDir,
    labels,
    requirement
  );

  const featurePaddedId = paddFeatureId(featureId);
  const featureName = `${featurePaddedId}-${featureSlug}`;
  const featureDir = path.join(featureParentDir, featureName);

  logInfo(`🚀 Created feature: ${featureName}`);

  // Create branch (or switch to it if it already exists)
  try {
    const branchExists = await gitBranchExists(featureName);
    if (branchExists) {
      await gitCheckout(featureName, false);
      logInfo(`Switched to existing branch: ${featureName}`);
    } else {
      await gitCheckout(featureName, true);
      logInfo(`Created new branch: ${featureName}`);
    }
  } catch (error) {
    logError(`Failed to create/switch to branch ${featureName}: ${error.message}`);
  }

  // Copy templates
  const copiedFilesCsv = await copyTemplates(featureDir, templates);

  // Output results
  const results = {
    BRANCH_NAME: featureName,
    FEATURE_FOLDER: featureDir,
    ISSUE_NUMBER: String(featureId),
    TITLE: featureTitle,
    REQUIREMENT: requirement,
    COPIED_TEMPLATES: copiedFilesCsv ? copiedFilesCsv.split(',') : []
  };

  outputResults(results, outputJson);
}

async function updateExistingFeature(featureName, labels, requirement, templates, outputJson, specsFolder, issueManagerType) {
  const featureId = extractFeatureId(featureName);
  const featureParentDir = path.join(process.cwd(), specsFolder);
  const featureDir = path.join(featureParentDir, featureName);

  if (!(await fs.pathExists(featureDir))) {
    logError(`Feature directory '${featureDir}' not found`);
  }

  // Checkout branch
  try {
    await gitCheckout(featureName, false);
  } catch (error) {
    logError(`Failed to switch to branch ${featureName}`);
  }

  if (!featureId || featureId === 0) {
    logError(`Could not determine issue from branch '${featureName}'`);
  }

  const issueManager = getIssueManager(issueManagerType);
  await issueManager.updateIssue(featureId, featureName, featureDir, labels, requirement);

  // Copy templates
  const copiedFilesCsv = await copyTemplates(featureDir, templates);

  // Get feature title
  let featureTitle = featureName;
  const issueJsonPath = path.join(featureDir, 'issue.json');
  if (await fs.pathExists(issueJsonPath)) {
    const issueData = await fs.readJson(issueJsonPath);
    featureTitle = issueData.title || featureName;
  }

  // Output results
  const results = {
    BRANCH_NAME: featureName,
    FEATURE_FOLDER: featureDir,
    ISSUE_NUMBER: String(featureId),
    TITLE: featureTitle,
    REQUIREMENT: requirement,
    COPIED_TEMPLATES: copiedFilesCsv ? copiedFilesCsv.split(',') : []
  };

  outputResults(results, outputJson);
}

async function copyTemplates(featureDir, requestedTemplates) {
  if (!requestedTemplates || requestedTemplates.length === 0) {
    logInfo('ℹ️  No templates specified. Only creating directory structure.');
    return '';
  }

  const repoRoot = getRepoRoot();
  const templatesDir = path.join(repoRoot, '.cwai/templates/outline');
  const copiedFiles = [];

  for (let template of requestedTemplates) {
    template = template.trim();
    if (!template) continue;

    let sourcePath = path.join(templatesDir, template);
    if (!(await fs.pathExists(sourcePath)) && !template.endsWith('.md')) {
      sourcePath = path.join(templatesDir, `${template}.md`);
    }

    if (!(await fs.pathExists(sourcePath))) {
      logWarn(`Template '${template}' not found in ${templatesDir}`);
      continue;
    }

    await fs.ensureDir(featureDir);
    const destination = path.join(featureDir, path.basename(sourcePath));

    if (await fs.pathExists(destination)) {
      logWarn(`Template '${path.basename(destination)}' already exists in ${featureDir}; skipping`);
      continue;
    }

    await fs.copy(sourcePath, destination);
    copiedFiles.push(destination);
    logInfo(`📄 Copied template: ${path.basename(sourcePath)}`);
  }

  return copiedFiles.join(',');
}

function parseLabels(labelsOption) {
  if (!labelsOption) return '';
  if (Array.isArray(labelsOption)) {
    return labelsOption.join(',');
  }
  return labelsOption;
}

async function detectFeatureNameAsync(requirement) {
  const featureName = detectFeatureName(requirement);
  if (!featureName) return '';

  if (await gitBranchExists(featureName)) {
    return featureName;
  }

  return '';
}
