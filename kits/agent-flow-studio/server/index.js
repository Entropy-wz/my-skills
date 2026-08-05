import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import YAML from 'yaml';
import { resolveRoot, wantServeStatic } from './lib/root.js';
import { agentDir, assertAgentName } from './lib/paths.js';
import { validateWorkflow } from './lib/validate.js';
import { generateAgentMd } from './lib/generate.js';
import { migrateFromAgentMd } from './lib/migrate.js';
import {
  syncAgentSnapshot,
  ensureThinSkill,
  assertThinSkillReady,
} from './lib/sync.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const kitRoot = path.join(__dirname, '..');

function loadEnvFile() {
  const envPath = path.join(kitRoot, '.env');
  if (!fs.existsSync(envPath)) return;
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!m) continue;
    if (process.env[m[1]] == null || process.env[m[1]] === '') {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, '').trim();
    }
  }
}

loadEnvFile();

let ROOT;
try {
  ROOT = resolveRoot();
} catch (e) {
  console.error(e.message);
  process.exit(1);
}

const PORT = Number(process.env.PORT || 8787);
const app = express();
app.use(express.json({ limit: '2mb' }));

function writeSoT(dir, wf, { preserveAgentMd }) {
  const yamlPath = path.join(dir, 'workflow.yaml');
  const agentMdPath = path.join(dir, 'AGENT.md');
  const promptPath = path.join(dir, 'prompt.md');
  const staging = path.join(dir, `.studio-staging-${process.pid}`);
  fs.rmSync(staging, { recursive: true, force: true });
  fs.mkdirSync(staging, { recursive: true });
  fs.writeFileSync(path.join(staging, 'workflow.yaml'), YAML.stringify(wf), 'utf8');
  if (preserveAgentMd && fs.existsSync(agentMdPath)) {
    fs.copyFileSync(agentMdPath, path.join(staging, 'AGENT.md'));
  } else {
    fs.writeFileSync(path.join(staging, 'AGENT.md'), generateAgentMd(wf), 'utf8');
  }
  if (typeof wf.prompt === 'string' && wf.prompt.length) {
    const p = wf.prompt.endsWith('\n') ? wf.prompt : `${wf.prompt}\n`;
    fs.writeFileSync(path.join(staging, 'prompt.md'), p, 'utf8');
  }
  // Copy other existing pack files (except staging / managed)
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name.startsWith('.studio-staging')) continue;
    if (['workflow.yaml', 'AGENT.md', 'prompt.md'].includes(ent.name)) continue;
    const src = path.join(dir, ent.name);
    const dest = path.join(staging, ent.name);
    if (ent.isDirectory()) {
      fs.cpSync(src, dest, { recursive: true });
    } else {
      fs.copyFileSync(src, dest);
    }
  }
  // Replace managed files via rename when possible (same volume)
  const swap = (from, to) => {
    const bak = `${to}.bak-${process.pid}`;
    try {
      if (fs.existsSync(to)) fs.renameSync(to, bak);
      fs.renameSync(from, to);
      if (fs.existsSync(bak)) fs.unlinkSync(bak);
    } catch {
      fs.copyFileSync(from, to);
      if (fs.existsSync(bak)) {
        try {
          fs.unlinkSync(bak);
        } catch {
          /* ignore */
        }
      }
    }
  };
  swap(path.join(staging, 'workflow.yaml'), yamlPath);
  swap(path.join(staging, 'AGENT.md'), agentMdPath);
  if (fs.existsSync(path.join(staging, 'prompt.md'))) {
    swap(path.join(staging, 'prompt.md'), promptPath);
  } else if (fs.existsSync(promptPath)) {
    fs.unlinkSync(promptPath);
  }
  fs.rmSync(staging, { recursive: true, force: true });
}

app.get('/api/meta', (_req, res) => {
  res.json({ root: ROOT, version: '0.1.1', bind: '127.0.0.1' });
});

app.get('/api/agents', (_req, res) => {
  try {
    const agentsRoot = path.join(ROOT, 'agents');
    const names = fs
      .readdirSync(agentsRoot, { withFileTypes: true })
      .filter((d) => d.isDirectory() && !d.name.startsWith('_'))
      .map((d) => d.name)
      .filter((n) => {
        try {
          assertAgentName(n);
        } catch {
          return false;
        }
        const dir = path.join(agentsRoot, n);
        return (
          fs.existsSync(path.join(dir, 'AGENT.md')) ||
          fs.existsSync(path.join(dir, 'workflow.yaml'))
        );
      });
    res.json({
      agents: names.map((name) => ({
        name,
        hasYaml: fs.existsSync(path.join(agentsRoot, name, 'workflow.yaml')),
        hasAgentMd: fs.existsSync(path.join(agentsRoot, name, 'AGENT.md')),
      })),
    });
  } catch (e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

app.get('/api/agents/:name', (req, res) => {
  try {
    const dir = agentDir(ROOT, req.params.name);
    const yamlPath = path.join(dir, 'workflow.yaml');
    const agentMdPath = path.join(dir, 'AGENT.md');
    if (!fs.existsSync(yamlPath)) {
      return res.status(404).json({
        error: 'no workflow.yaml',
        hasAgentMd: fs.existsSync(agentMdPath),
      });
    }
    const wf = YAML.parse(fs.readFileSync(yamlPath, 'utf8'));
    res.json({ workflow: wf });
  } catch (e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

app.post('/api/agents/:name/migrate', (req, res) => {
  try {
    const name = req.params.name;
    const dir = agentDir(ROOT, name);
    const yamlPath = path.join(dir, 'workflow.yaml');
    const agentMdPath = path.join(dir, 'AGENT.md');
    if (!fs.existsSync(agentMdPath)) {
      return res.status(404).json({ error: 'AGENT.md missing' });
    }
    if (fs.existsSync(yamlPath) && !req.query.force) {
      return res.status(409).json({ error: 'workflow.yaml already exists; pass ?force=1' });
    }
    assertThinSkillReady(ROOT, name);
    const md = fs.readFileSync(agentMdPath, 'utf8');
    const before = md;
    const wf = migrateFromAgentMd(md, name);
    const v = validateWorkflow(wf, { folderName: name });
    if (!v.ok) {
      return res.status(400).json({ error: 'migrate produced invalid workflow', errors: v.errors });
    }
    // Atomic-ish: stage yaml, re-check AGENT.md, then rename into place (no orphan yaml on D1 fail)
    fs.mkdirSync(dir, { recursive: true });
    const tmpYaml = path.join(dir, `.workflow.yaml.${process.pid}.tmp`);
    fs.writeFileSync(tmpYaml, YAML.stringify(wf), 'utf8');
    const after = fs.readFileSync(agentMdPath, 'utf8');
    if (after !== before) {
      fs.unlinkSync(tmpYaml);
      return res.status(500).json({ error: 'D1 violation: AGENT.md changed during migrate' });
    }
    fs.renameSync(tmpYaml, yamlPath);
    const snap = syncAgentSnapshot(ROOT, name, dir);
    const skill = ensureThinSkill(ROOT, name);
    res.json({ workflow: wf, agentMdUnchanged: true, snapshot: snap, thinSkill: skill });
  } catch (e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

app.put('/api/agents/:name', (req, res) => {
  try {
    const name = req.params.name;
    const dir = agentDir(ROOT, name);
    const body = req.body || {};
    const wf = body.workflow ?? body;
    const forceRegen =
      body.forceRegenerateAgentMd === true || req.query.forceRegenerateAgentMd === '1';
    const v = validateWorkflow(wf, { folderName: name });
    if (!v.ok) return res.status(400).json({ error: 'validation failed', errors: v.errors });

    // Preflight collision BEFORE any writes
    assertThinSkillReady(ROOT, name);

    const preserveAgentMd = Boolean(wf.preserve_agent_md) && !forceRegen;
    fs.mkdirSync(dir, { recursive: true });
    writeSoT(dir, wf, { preserveAgentMd });
    const snap = syncAgentSnapshot(ROOT, name, dir);
    const skill = ensureThinSkill(ROOT, name);
    res.json({
      ok: true,
      snapshot: snap,
      thinSkill: skill,
      preservedAgentMd: preserveAgentMd,
    });
  } catch (e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

app.post('/api/agents/:name/sync', (req, res) => {
  try {
    const name = req.params.name;
    const dir = agentDir(ROOT, name);
    if (!fs.existsSync(dir)) return res.status(404).json({ error: 'agent missing' });
    assertThinSkillReady(ROOT, name);
    const snap = syncAgentSnapshot(ROOT, name, dir);
    const skill = ensureThinSkill(ROOT, name);
    res.json({ ok: true, snapshot: snap, thinSkill: skill });
  } catch (e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

app.use((err, _req, res, _next) => {
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'invalid JSON body' });
  }
  res.status(err.status || 500).json({ error: err.message || 'error' });
});

if (wantServeStatic()) {
  const dist = path.join(kitRoot, 'web', 'dist');
  if (fs.existsSync(dist)) {
    app.use(express.static(dist));
    app.get('*', (_req, res) => res.sendFile(path.join(dist, 'index.html')));
  } else {
    console.warn('web/dist missing — run npm run build');
  }
}

app.listen(PORT, '127.0.0.1', () => {
  console.log(`agent-flow-studio API http://127.0.0.1:${PORT}  ROOT=${ROOT}`);
});
