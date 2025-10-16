#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { resolveNextVersion, parseVersion, compareSemver } = require('./lib/version-utils.js');

/**
 * Fetch all tags from GitHub API
 */
async function fetchTags({ owner, repo, token, apiBase }) {
  const tags = [];
  let page = 1;
  const perPage = 100;

  while (true) {
    const url = `${apiBase}/repos/${owner}/${repo}/tags?per_page=${perPage}&page=${page}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `token ${token}`,
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'GitHub-Actions'
      }
    });

    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.status} ${response.statusText}`);
    }

    const batch = await response.json();
    if (batch.length === 0) break;

    tags.push(...batch.map(t => t.name));
    if (batch.length < perPage) break;
    page++;
  }

  return tags;
}

/**
 * Find the latest semantic version tag
 */
function findLatestSemverTag(tags) {
  const semverTags = tags
    .map(tag => {
      try {
        return parseVersion(tag);
      } catch {
        return null;
      }
    })
    .filter(Boolean);

  if (semverTags.length === 0) return null;

  return semverTags.reduce((latest, current) =>
    compareSemver(current.normalized, latest.normalized) > 0 ? current : latest
  );
}

/**
 * Write output to GITHUB_OUTPUT
 */
function setOutput(name, value) {
  const outputFile = process.env.GITHUB_OUTPUT;
  if (!outputFile) {
    console.log(`::set-output name=${name}::${value}`);
    return;
  }
  fs.appendFileSync(outputFile, `${name}=${value}\n`, 'utf8');
}

/**
 * Main execution
 */
async function main() {
  try {
    // Get inputs from environment
    const token = process.env.GITHUB_TOKEN;
    const releaseType = process.env.INPUT_RELEASE_TYPE || 'patch';
    const explicitVersion = process.env.INPUT_EXPLICIT_VERSION || '';
    const repository = process.env.GITHUB_REPOSITORY;
    const apiBase = process.env.GITHUB_API_URL || 'https://api.github.com';

    if (!token) {
      throw new Error('GITHUB_TOKEN environment variable is required');
    }

    if (!repository) {
      throw new Error('GITHUB_REPOSITORY environment variable is required');
    }

    const [owner, repo] = repository.split('/');

    console.log('Fetching tags from GitHub...');
    const tags = await fetchTags({ owner, repo, token, apiBase });
    console.log(`Found ${tags.length} total tags`);

    const latestTag = findLatestSemverTag(tags);
    const currentTag = latestTag ? latestTag.normalized : '';

    console.log('Current tag:', currentTag || '(none - bootstrap)');
    console.log('Release type:', releaseType);
    console.log('Explicit version:', explicitVersion || '(none)');

    // Calculate next version
    const result = resolveNextVersion({
      currentTag,
      releaseType,
      explicitVersion
    });

    console.log('\nVersion calculation result:');
    console.log('  Next version:', result.nextVersion);
    console.log('  Is bootstrap:', result.isBootstrap);
    console.log('  Previous version:', result.previousVersion);
    console.log('  Release strategy:', result.releaseStrategy);
    console.log('  Resolved release type:', result.resolvedReleaseType);

    // Set outputs
    setOutput('next_version', result.nextVersion);
    setOutput('is_bootstrap', result.isBootstrap);
    setOutput('previous_version', result.previousVersion);
    setOutput('release_strategy', result.releaseStrategy);
    setOutput('resolved_release_type', result.resolvedReleaseType);

    console.log('\n✓ Version calculation complete');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();
