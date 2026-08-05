import fs from 'node:fs';
import path from 'node:path';

export const NAME_RE = /^[a-z0-9][a-z0-9-]*$/;

function underRoot(child, parent) {
  const c = path.resolve(child);
  const p = path.resolve(parent);
  const norm = (s) => (process.platform === 'win32' ? s.toLowerCase() : s);
  const cn = norm(c);
  const pn = norm(p);
  return cn === pn || cn.startsWith(pn + path.sep);
}

export function assertAgentName(name) {
  if (!NAME_RE.test(name) || name.startsWith('_')) {
    throw Object.assign(new Error(`invalid agent name: ${name}`), { status: 400 });
  }
  return name;
}

function assertUnder(realPath, rootPath, label) {
  if (!underRoot(realPath, rootPath)) {
    throw Object.assign(new Error(`${label} escapes ROOT: ${realPath}`), { status: 400 });
  }
}

/** Resolve agents/<name> under ROOT; reject traversal / symlink escape. */
export function agentDir(root, name) {
  assertAgentName(name);
  const agentsRoot = path.resolve(root, 'agents');
  const dir = path.resolve(agentsRoot, name);
  if (!underRoot(dir, agentsRoot)) {
    throw Object.assign(new Error('path escape'), { status: 400 });
  }
  const realAgents = fs.existsSync(agentsRoot) ? fs.realpathSync(agentsRoot) : agentsRoot;
  if (fs.existsSync(dir)) {
    assertUnder(fs.realpathSync(dir), realAgents, 'agentDir');
  }
  return dir;
}

export function snapshotDir(root, name) {
  assertAgentName(name);
  const orch = path.resolve(root, 'skills', 'orchestration');
  const skillDir = path.resolve(orch, name);
  const dir = path.resolve(skillDir, 'agent');
  if (!underRoot(dir, orch)) {
    throw Object.assign(new Error('path escape'), { status: 400 });
  }
  const realOrch = fs.existsSync(orch) ? fs.realpathSync(orch) : orch;
  if (fs.existsSync(skillDir)) {
    assertUnder(fs.realpathSync(skillDir), realOrch, 'skillDir');
  }
  if (fs.existsSync(dir)) {
    assertUnder(fs.realpathSync(dir), realOrch, 'snapshotDir');
  }
  // Creating new agent/ under a junctioned skillDir: resolve parent after mkdir in sync
  return dir;
}

export function thinSkillPath(root, name) {
  assertAgentName(name);
  const orch = path.resolve(root, 'skills', 'orchestration');
  const p = path.resolve(orch, name, 'SKILL.md');
  if (!underRoot(p, orch)) {
    throw Object.assign(new Error('path escape'), { status: 400 });
  }
  const realOrch = fs.existsSync(orch) ? fs.realpathSync(orch) : orch;
  const skillDir = path.resolve(orch, name);
  if (fs.existsSync(skillDir)) {
    assertUnder(fs.realpathSync(skillDir), realOrch, 'thinSkillDir');
  }
  if (fs.existsSync(p)) {
    assertUnder(fs.realpathSync(p), realOrch, 'thinSkillPath');
  }
  return p;
}

/** Call after mkdir of snapshot so new junctions are caught. */
export function assertSnapshotRealpath(root, name) {
  const orch = path.resolve(root, 'skills', 'orchestration');
  const realOrch = fs.realpathSync(orch);
  const dir = snapshotDir(root, name);
  if (fs.existsSync(dir)) {
    assertUnder(fs.realpathSync(dir), realOrch, 'snapshotDir');
  }
}
