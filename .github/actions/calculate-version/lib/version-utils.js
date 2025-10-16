'use strict';

/**
 * Semantic version parsing and manipulation utilities
 */

const SEMVER_PATTERN = /^v?(\d+)\.(\d+)\.(\d+)$/;

/**
 * Parse a semantic version string
 * @param {string} version - Version string (e.g., "v1.2.3" or "1.2.3")
 * @returns {{ normalized: string, major: number, minor: number, patch: number }}
 */
function parseVersion(version) {
  const match = version.match(SEMVER_PATTERN);
  if (!match) {
    throw new Error(`Invalid semantic version: ${version}`);
  }

  const [, major, minor, patch] = match;
  return {
    normalized: `v${major}.${minor}.${patch}`,
    major: parseInt(major, 10),
    minor: parseInt(minor, 10),
    patch: parseInt(patch, 10)
  };
}

/**
 * Normalize version to always include 'v' prefix
 * @param {string} version - Version string
 * @returns {string}
 */
function normalizeVersion(version) {
  return version.startsWith('v') ? version : `v${version}`;
}

/**
 * Normalize release type input
 * @param {string} releaseType - Input release type
 * @returns {string} - Normalized release type
 */
function normalizeReleaseType(releaseType) {
  const type = (releaseType || '').toLowerCase().trim();
  if (!type || type === 'patch') return 'patch';
  if (type === 'minor') return 'minor';
  if (type === 'major') return 'major';
  throw new Error(`Unsupported release_type: ${releaseType}. Must be patch, minor, or major.`);
}

/**
 * Compare two semantic versions
 * @param {string} v1 - First version
 * @param {string} v2 - Second version
 * @returns {number} - -1 if v1 < v2, 0 if equal, 1 if v1 > v2
 */
function compareSemver(v1, v2) {
  const p1 = parseVersion(v1);
  const p2 = parseVersion(v2);

  if (p1.major !== p2.major) return p1.major - p2.major;
  if (p1.minor !== p2.minor) return p1.minor - p2.minor;
  return p1.patch - p2.patch;
}

/**
 * Increment a version
 * @param {object} version - Parsed version object
 * @param {string} releaseType - Type of increment (patch, minor, major)
 * @returns {string} - New version string
 */
function incrementVersion(version, releaseType) {
  const type = normalizeReleaseType(releaseType);
  
  if (type === 'major') {
    return `v${version.major + 1}.0.0`;
  }
  if (type === 'minor') {
    return `v${version.major}.${version.minor + 1}.0`;
  }
  return `v${version.major}.${version.minor}.${version.patch + 1}`;
}

/**
 * Resolve the next version based on current state and inputs
 * @param {object} params
 * @param {string} params.currentTag - Current latest tag (empty if none)
 * @param {string} params.releaseType - Desired release type
 * @param {string} params.explicitVersion - Optional explicit version override
 * @returns {object} - Version resolution result
 */
function resolveNextVersion({ currentTag, releaseType, explicitVersion }) {
  // Bootstrap scenario: no existing tags
  if (!currentTag) {
    return {
      nextVersion: 'v1.0.0',
      isBootstrap: true,
      previousVersion: '',
      releaseStrategy: 'bootstrap',
      resolvedReleaseType: 'major'
    };
  }

  const current = parseVersion(currentTag);

  // Explicit version override
  if (explicitVersion) {
    const explicit = parseVersion(normalizeVersion(explicitVersion));
    if (compareSemver(explicit.normalized, current.normalized) <= 0) {
      throw new Error(
        `explicit_version (${explicit.normalized}) must be greater than current version (${current.normalized})`
      );
    }
    return {
      nextVersion: explicit.normalized,
      isBootstrap: false,
      previousVersion: current.normalized,
      releaseStrategy: 'explicit',
      resolvedReleaseType: 'explicit'
    };
  }

  // Automatic increment based on release type
  const type = normalizeReleaseType(releaseType);
  const nextVersion = incrementVersion(current, type);

  return {
    nextVersion,
    isBootstrap: false,
    previousVersion: current.normalized,
    releaseStrategy: releaseType === 'patch' ? 'auto' : 'override',
    resolvedReleaseType: type
  };
}

module.exports = {
  SEMVER_PATTERN,
  parseVersion,
  normalizeVersion,
  normalizeReleaseType,
  compareSemver,
  incrementVersion,
  resolveNextVersion
};
