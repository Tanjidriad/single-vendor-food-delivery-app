#!/usr/bin/env node
/**
 * Merge one or more Firebase Android SDK config JSON files into a single
 * google-services.json (multi-client). Used after registering each app via CLI.
 *
 * Usage:
 *   node scripts/firebase/merge-google-services.mjs infra/firebase/google-services.json out/temp.json
 *   node scripts/firebase/merge-google-services.mjs --write infra/firebase/google-services.json a.json b.json
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);
const writeMode = args[0] === '--write';
const paths = writeMode ? args.slice(2) : args;
const outPath = writeMode ? args[1] : null;

if (paths.length === 0) {
  console.error('Provide at least one google-services.json path.');
  process.exit(1);
}

/** @param {string} filePath */
function load(filePath) {
  const abs = resolve(filePath);
  return JSON.parse(readFileSync(abs, 'utf8'));
}

/** @param {object} base @param {object} incoming */
function mergeClient(base, incoming) {
  const packages = new Set(
    (base.client ?? []).map((c) => c.client_info?.android_client_info?.package_name),
  );

  for (const client of incoming.client ?? []) {
    const pkg = client.client_info?.android_client_info?.package_name;
    if (!pkg) continue;
    if (packages.has(pkg)) continue;
    base.client.push(client);
    packages.add(pkg);
  }

  base.project_info = incoming.project_info ?? base.project_info;
  base.configuration_version =
    incoming.configuration_version ?? base.configuration_version ?? '1';

  return base;
}

let merged = load(paths[0]);
for (let i = 1; i < paths.length; i++) {
  merged = mergeClient(merged, load(paths[i]));
}

const json = `${JSON.stringify(merged, null, 2)}\n`;

if (writeMode && outPath) {
  writeFileSync(resolve(outPath), json, 'utf8');
  const packages = (merged.client ?? []).map(
    (c) => c.client_info?.android_client_info?.package_name,
  );
  console.log(`Wrote ${outPath}`);
  console.log(`Registered packages: ${packages.join(', ')}`);
} else {
  process.stdout.write(json);
}
