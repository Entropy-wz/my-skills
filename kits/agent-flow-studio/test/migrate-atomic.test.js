import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import YAML from 'yaml';
import { migrateFromAgentMd } from '../server/lib/migrate.js';
import { validateWorkflow } from '../server/lib/validate.js';

/**
 * Mirrors server migrate staging: tmp → D1 check → rename (no orphan yaml on fail).
 */
function migrateAtomic(dir, folderName) {
  const agentMdPath = path.join(dir, 'AGENT.md');
  const yamlPath = path.join(dir, 'workflow.yaml');
  const before = fs.readFileSync(agentMdPath, 'utf8');
  const wf = migrateFromAgentMd(before, folderName);
  const v = validateWorkflow(wf, { folderName });
  if (!v.ok) throw new Error(v.errors.join('; '));
  const tmpYaml = path.join(dir, `.workflow.yaml.${process.pid}.tmp`);
  fs.writeFileSync(tmpYaml, YAML.stringify(wf), 'utf8');
  // Simulate concurrent edit → D1 fail
  fs.writeFileSync(agentMdPath, before + '\n<!-- edited -->\n', 'utf8');
  const after = fs.readFileSync(agentMdPath, 'utf8');
  if (after !== before) {
    fs.unlinkSync(tmpYaml);
    return { ok: false, yamlExists: fs.existsSync(yamlPath), tmpExists: fs.existsSync(tmpYaml) };
  }
  fs.renameSync(tmpYaml, yamlPath);
  return { ok: true, yamlExists: fs.existsSync(yamlPath) };
}

describe('migrate atomic yaml publish', () => {
  let dir;
  beforeEach(() => {
    dir = fs.mkdtempSync(path.join(os.tmpdir(), 'afs-mig-'));
    fs.writeFileSync(
      path.join(dir, 'AGENT.md'),
      `# Agent: demo

## Purpose

Demo.

## When

- a

## When not

- b

## Steps

1. **One**
   body

## Handoffs

| Situation | Go to |
| --- | --- |
| Gates | \`/ship-gate\` |

## Boundaries

- **Forbidden:** \`push\`

## Inputs

- x

## Outputs

- y
`
    );
  });
  afterEach(() => {
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it('leaves no workflow.yaml when D1 check fails', () => {
    const r = migrateAtomic(dir, 'demo');
    expect(r.ok).toBe(false);
    expect(r.yamlExists).toBe(false);
    expect(r.tmpExists).toBe(false);
  });
});
