import chalk from 'chalk';

/**
 * Logging utilities with colored output matching bash script style
 */

const LOG_PREFIX = 'λ';

export function logDebug(message) {
  if (process.env.DEBUG) {
    console.error(chalk.blue(`${LOG_PREFIX} DEBUG ${message}`));
  }
}

export function logInfo(message) {
  console.error(chalk.green(`${LOG_PREFIX} INFO ${message}`));
}

export function logWarn(message) {
  console.error(chalk.yellow(`${LOG_PREFIX} WARN ${message}`));
}

export function logError(message, exitCode = 1) {
  console.error(chalk.red(`${LOG_PREFIX} ERROR ${message}`));
  process.exit(exitCode);
}

export function logSuccess(message) {
  console.error(chalk.green(`${LOG_PREFIX} SUCCESS ${message}`));
}
