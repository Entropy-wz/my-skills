/**
 * Best-effort AGENT.md → workflow object. Does not write AGENT.md.
 */

function normalizeEol(text) {
  return String(text || '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function sectionBody(md, heading) {
  const re = new RegExp(`## ${heading}\\s*\\n([\\s\\S]*?)(?=\\n## |$)`, 'i');
  const m = md.match(re);
  return m ? m[1].trim() : '';
}

function bulletLines(body) {
  return body
    .split('\n')
    .map((l) => l.replace(/^\s*[-*]\s+/, '').trim())
    .filter((l) => l && !l.startsWith('_None'));
}

function parseSteps(body) {
  const nodes = [];
  const chunks = body.split(/\n(?=\d+\.\s+)/);
  let i = 0;
  for (const chunk of chunks) {
    const m = chunk.match(/^\d+\.\s+(?:\*\*)?(.+?)(?:\*\*)?(?:\n([\s\S]*))?$/);
    if (!m) continue;
    i += 1;
    let label = m[1].replace(/\*\*/g, '').trim();
    // Prefer bold title before em-dash prose on same line
    const dash = label.match(/^(.+?)\s+[—–-]\s+/);
    if (dash) label = dash[1].trim();
    label = label.slice(0, 80);
    const notes = (m[2] || '')
      .split('\n')
      .map((l) => l.replace(/^\s{2,}/, '').trimEnd())
      .join('\n')
      .trim();
    nodes.push({
      id: `step-${i}`,
      type: 'step',
      label: label || `Step ${i}`,
      notes: notes || undefined,
    });
  }
  return nodes;
}

function parseHandoffs(body) {
  const nodes = [];
  const rows = body.split('\n').filter((l) => l.includes('|') && !l.match(/^\|\s*---/));
  let i = 0;
  for (const row of rows) {
    if (/Situation/i.test(row)) continue;
    const cells = row
      .split('|')
      .map((c) => c.trim())
      .filter(Boolean);
    if (cells.length < 2) continue;
    const [situation, go] = cells;
    if (situation === '—' || go === '—') continue;
    i += 1;
    const refMatch = go.match(/\/([a-z0-9-]+)/i) || go.match(/`([a-z0-9-]+)`/i);
    const ref = refMatch ? refMatch[1] : undefined;
    const type = ref === 'ship-gate' || /gate/i.test(situation) ? 'gate' : 'skill';
    nodes.push({
      id: `${type}-${i}`,
      type,
      label: situation.slice(0, 80),
      ref: ref || 'unknown',
    });
  }
  return { nodes };
}

function parseBannedActions(body) {
  const out = [];
  for (const line of bulletLines(body)) {
    if (!/\*\*Forbidden:\*\*/i.test(line) && !/^Forbidden:/i.test(line)) continue;
    const rest = line
      .replace(/^\*\*Forbidden:\*\*\s*/i, '')
      .replace(/^Forbidden:\s*/i, '')
      .trim();
    const ticks = [...rest.matchAll(/`([^`]+)`/g)].map((m) => m[1].trim());
    if (ticks.length) {
      for (const t of ticks) {
        // split "git push, gh pr create" style inside one tick? keep whole tick
        out.push(t);
      }
    } else if (rest) {
      out.push(rest.replace(/`/g, '').trim());
    }
  }
  return [...new Set(out.filter(Boolean))];
}

export function migrateFromAgentMd(rawMd, folderName) {
  const md = normalizeEol(rawMd);
  const purpose = sectionBody(md, 'Purpose');
  const when = bulletLines(sectionBody(md, 'When'));
  const when_not = bulletLines(sectionBody(md, 'When not'));
  const steps = parseSteps(sectionBody(md, 'Steps'));
  const { nodes: handoffNodes } = parseHandoffs(sectionBody(md, 'Handoffs'));
  const banned = parseBannedActions(sectionBody(md, 'Boundaries'));
  const inputs = bulletLines(sectionBody(md, 'Inputs'));
  const outputs = bulletLines(sectionBody(md, 'Outputs'));

  const nodes = [...steps, ...handoffNodes];
  if (!nodes.length) {
    nodes.push({
      id: 'step-1',
      type: 'step',
      label: 'TODO',
      notes: purpose || 'Migrated empty pack',
    });
  }

  const edges = [];
  for (let i = 0; i < steps.length - 1; i++) {
    edges.push({ from: steps[i].id, to: steps[i + 1].id });
  }
  if (steps.length && handoffNodes.length) {
    edges.push({
      from: steps[steps.length - 1].id,
      to: handoffNodes[0].id,
      condition: 'handoff',
    });
  }

  const ui = {};
  nodes.forEach((n, idx) => {
    ui[n.id] = { x: 80 + (idx % 4) * 220, y: 80 + Math.floor(idx / 4) * 120 };
  });

  return {
    id: folderName,
    name: folderName,
    version: '1',
    summary: purpose.trim() || folderName,
    when,
    when_not,
    inputs,
    outputs,
    banned_actions: banned,
    /** D1: Save must not overwrite hand-authored AGENT.md until explicitly cleared */
    preserve_agent_md: true,
    nodes,
    edges,
    ui,
  };
}
