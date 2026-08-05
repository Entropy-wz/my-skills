import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { validateWorkflow } from '../server/lib/validate.js';
import { generateAgentMd } from '../server/lib/generate.js';
import { migrateFromAgentMd } from '../server/lib/migrate.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const schema = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'schema', 'workflow.schema.json'), 'utf8')
);
const ajv = new Ajv2020({ allErrors: true, strict: false });
addFormats(ajv);
const ajvOnly = ajv.compile(schema);

const sample = {
  id: 'studio-fixture',
  name: 'studio-fixture',
  version: '1',
  summary: 'A fixture',
  when: ['test'],
  when_not: ['prod'],
  inputs: ['root'],
  outputs: ['out'],
  banned_actions: ['push'],
  nodes: [
    { id: 'step-1', type: 'step', label: 'Do thing', notes: 'details' },
    { id: 'gate-1', type: 'gate', label: 'Need gates', ref: 'ship-gate' },
  ],
  edges: [{ from: 'step-1', to: 'gate-1', condition: 'optional' }],
};

describe('validateWorkflow', () => {
  it('accepts valid v1 workflow', () => {
    const r = validateWorkflow(sample, { folderName: 'studio-fixture' });
    expect(r.ok).toBe(true);
  });

  it('rejects agent/human at schema and validate layer', () => {
    const badAgent = {
      ...sample,
      nodes: [{ id: 'a1', type: 'agent', label: 'nested' }],
      edges: [],
    };
    expect(ajvOnly(badAgent)).toBe(false);
    const r = validateWorkflow(badAgent, { folderName: 'studio-fixture' });
    expect(r.ok).toBe(false);
  });

  it('rejects id/folder mismatch', () => {
    const r = validateWorkflow(sample, { folderName: 'other' });
    expect(r.ok).toBe(false);
  });

  it('rejects dangling edge', () => {
    const bad = { ...sample, edges: [{ from: 'step-1', to: 'missing' }] };
    const r = validateWorkflow(bad, { folderName: 'studio-fixture' });
    expect(r.ok).toBe(false);
  });
});

describe('generateAgentMd', () => {
  it('is idempotent for stable input', () => {
    const a = generateAgentMd(sample);
    const b = generateAgentMd(sample);
    expect(a).toBe(b);
    expect(a.endsWith('\n')).toBe(true);
    expect(a).toContain('## Purpose');
    expect(a).toContain('/ship-gate');
  });
});

describe('migrateFromAgentMd', () => {
  const mdLf = `# Agent: demo

## Purpose

Demo purpose line.

## When

- when a

## When not

- when not b

## Steps

1. **First**
   body one
2. **Second**
   body two

## Handoffs

| Situation | Go to |
| --- | --- |
| Gates | \`/ship-gate\` |

## Boundaries

- **Forbidden:** \`git push\`, \`gh pr create\`
- Advisory review only — human owns merge call.

## Inputs

- repo

## Outputs

- report
`;

  it('extracts steps and handoffs (LF)', () => {
    const wf = migrateFromAgentMd(mdLf, 'demo');
    expect(wf.nodes.filter((n) => n.type === 'step').length).toBe(2);
    expect(wf.nodes.some((n) => n.ref === 'ship-gate')).toBe(true);
    expect(wf.banned_actions).toEqual(expect.arrayContaining(['git push', 'gh pr create']));
    expect(wf.banned_actions.join(' ')).not.toMatch(/Advisory/);
    expect(wf.preserve_agent_md).toBe(true);
    expect(validateWorkflow(wf, { folderName: 'demo' }).ok).toBe(true);
  });

  it('extracts steps on CRLF (Windows)', () => {
    const wf = migrateFromAgentMd(mdLf.replace(/\n/g, '\r\n'), 'demo');
    expect(wf.nodes.filter((n) => n.type === 'step').length).toBe(2);
  });

  it('migrates real ship-review AGENT.md with steps', () => {
    const p = path.join(__dirname, '..', '..', '..', 'agents', 'ship-review', 'AGENT.md');
    if (!fs.existsSync(p)) return;
    const wf = migrateFromAgentMd(fs.readFileSync(p, 'utf8'), 'ship-review');
    expect(wf.nodes.filter((n) => n.type === 'step').length).toBeGreaterThanOrEqual(6);
    expect(wf.preserve_agent_md).toBe(true);
    expect(validateWorkflow(wf, { folderName: 'ship-review' }).ok).toBe(true);
  });
});
