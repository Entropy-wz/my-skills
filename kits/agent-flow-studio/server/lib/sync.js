import fs from 'node:fs';
import path from 'node:path';
import { snapshotDir, thinSkillPath, assertSnapshotRealpath } from './paths.js';

function walkFiles(dir) {
  const out = [];
  if (!fs.existsSync(dir)) return out;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...walkFiles(p));
    else out.push(p);
  }
  return out;
}

function walkDirsDepthFirst(dir) {
  const out = [];
  if (!fs.existsSync(dir)) return out;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      out.push(...walkDirsDepthFirst(p));
      out.push(p);
    }
  }
  return out;
}

/** Recursive mirror src → dest, prune extra files and empty dirs. */
export function mirrorPrune(srcDir, destDir) {
  fs.mkdirSync(destDir, { recursive: true });
  const srcFiles = walkFiles(srcDir);
  const srcRels = new Set(
    srcFiles.map((f) => path.relative(srcDir, f).split(path.sep).join('/'))
  );
  for (const f of srcFiles) {
    const rel = path.relative(srcDir, f);
    const dest = path.join(destDir, rel);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(f, dest);
  }
  for (const f of walkFiles(destDir)) {
    const rel = path.relative(destDir, f).split(path.sep).join('/');
    if (!srcRels.has(rel)) fs.unlinkSync(f);
  }
  for (const d of walkDirsDepthFirst(destDir)) {
    if (d === destDir) continue;
    try {
      if (fs.readdirSync(d).length === 0) fs.rmdirSync(d);
    } catch {
      /* ignore */
    }
  }
}

/** True if SKILL.md looks like a role-pack thin entry (not prose mention). */
export function looksLikeThinAgentSkill(body) {
  if (!body || typeof body !== 'string') return false;
  // Prefer markdown link target used by our scaffold / ADR-002 thin skills
  if (/\(\s*\.?\/?agent\/AGENT\.md\s*\)/.test(body)) return true;
  if (/\[`agent\/AGENT\.md`\]/.test(body)) return true;
  return false;
}

/**
 * Preflight: refuse colliding non-thin SKILL.md before any SoT/snapshot writes.
 */
export function assertThinSkillReady(root, name) {
  const p = thinSkillPath(root, name);
  if (!fs.existsSync(p)) return { path: p, exists: false };
  const body = fs.readFileSync(p, 'utf8');
  if (!looksLikeThinAgentSkill(body)) {
    throw Object.assign(
      new Error(
        `refusing save: ${path.relative(root, p)} is not a thin role-pack skill (missing agent/AGENT.md link)`
      ),
      { status: 409 }
    );
  }
  return { path: p, exists: true };
}

export function syncAgentSnapshot(root, name, agentAbsDir) {
  const dest = snapshotDir(root, name);
  fs.mkdirSync(dest, { recursive: true });
  assertSnapshotRealpath(root, name);
  mirrorPrune(agentAbsDir, dest);
  assertSnapshotRealpath(root, name);
  return dest;
}

const THIN_SKILL = (name) => `---
name: ${name}
description: Role pack entry for ${name}. Loads skill-local agent/AGENT.md. Trigger — "/${name}", "${name}".
disable-model-invocation: true
---

# ${name} (thin entry)

**Thin skill.** Read [\`agent/AGENT.md\`](agent/AGENT.md) and execute that pack only.
`;

export function ensureThinSkill(root, name) {
  const ready = assertThinSkillReady(root, name);
  if (ready.exists) return { path: ready.path, created: false };
  fs.mkdirSync(path.dirname(ready.path), { recursive: true });
  fs.writeFileSync(ready.path, THIN_SKILL(name), 'utf8');
  return { path: ready.path, created: true };
}
