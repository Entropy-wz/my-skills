import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {
  mirrorPrune,
  assertThinSkillReady,
  looksLikeThinAgentSkill,
  syncAgentSnapshot,
} from '../server/lib/sync.js';

describe('looksLikeThinAgentSkill', () => {
  it('accepts scaffold link form', () => {
    expect(
      looksLikeThinAgentSkill('Read [`agent/AGENT.md`](agent/AGENT.md) and follow it.')
    ).toBe(true);
  });

  it('rejects bare prose mention', () => {
    expect(
      looksLikeThinAgentSkill('See also agent/AGENT.md in the agents folder for inspiration.')
    ).toBe(false);
  });
});

describe('mirrorPrune', () => {
  let root;
  beforeEach(() => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), 'afs-mirror-'));
  });
  afterEach(() => {
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('removes extra files and empty directories', () => {
    const src = path.join(root, 'src');
    const dest = path.join(root, 'dest');
    fs.mkdirSync(path.join(src, 'keep'), { recursive: true });
    fs.writeFileSync(path.join(src, 'keep', 'a.md'), 'a');
    fs.mkdirSync(path.join(dest, 'keep'), { recursive: true });
    fs.writeFileSync(path.join(dest, 'keep', 'a.md'), 'old');
    fs.mkdirSync(path.join(dest, 'orphan', 'nested'), { recursive: true });
    fs.writeFileSync(path.join(dest, 'orphan', 'nested', 'gone.md'), 'x');
    mirrorPrune(src, dest);
    expect(fs.existsSync(path.join(dest, 'keep', 'a.md'))).toBe(true);
    expect(fs.readFileSync(path.join(dest, 'keep', 'a.md'), 'utf8')).toBe('a');
    expect(fs.existsSync(path.join(dest, 'orphan'))).toBe(false);
  });
});

describe('assertThinSkillReady', () => {
  let root;
  beforeEach(() => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), 'afs-thin-'));
    fs.mkdirSync(path.join(root, 'skills', 'orchestration', 'demo'), { recursive: true });
    fs.mkdirSync(path.join(root, 'agents'), { recursive: true });
  });
  afterEach(() => {
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('409 when SKILL.md is not a thin agent entry', () => {
    fs.writeFileSync(
      path.join(root, 'skills', 'orchestration', 'demo', 'SKILL.md'),
      '---\nname: demo\n---\n# Demo\n\nMentions agent/AGENT.md in prose only.\n'
    );
    expect(() => assertThinSkillReady(root, 'demo')).toThrow(/refusing save/);
    try {
      assertThinSkillReady(root, 'demo');
    } catch (e) {
      expect(e.status).toBe(409);
    }
  });

  it('allows missing SKILL.md', () => {
    const r = assertThinSkillReady(root, 'demo');
    expect(r.exists).toBe(false);
  });
});

describe('syncAgentSnapshot', () => {
  let root;
  beforeEach(() => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), 'afs-sync-'));
    fs.mkdirSync(path.join(root, 'agents', 'pack'), { recursive: true });
    fs.mkdirSync(path.join(root, 'skills', 'orchestration'), { recursive: true });
    fs.writeFileSync(path.join(root, 'agents', 'pack', 'AGENT.md'), '# hi\n');
    fs.writeFileSync(path.join(root, 'agents', 'pack', 'workflow.yaml'), 'id: pack\n');
  });
  afterEach(() => {
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('mirrors pack into skills/orchestration/<name>/agent', () => {
    const dest = syncAgentSnapshot(root, 'pack', path.join(root, 'agents', 'pack'));
    expect(fs.existsSync(path.join(dest, 'AGENT.md'))).toBe(true);
    expect(fs.existsSync(path.join(dest, 'workflow.yaml'))).toBe(true);
  });
});
