/** Deterministic AGENT.md from workflow object. Stable trailing newline. */

function bullets(arr) {
  if (!arr?.length) return '_None._\n';
  return arr.map((x) => `- ${x}`).join('\n') + '\n';
}

function topoSteps(nodes, edges) {
  const steps = nodes.filter((n) => n.type === 'step');
  const ids = new Set(steps.map((n) => n.id));
  const indeg = Object.fromEntries([...ids].map((id) => [id, 0]));
  for (const e of edges || []) {
    if (ids.has(e.from) && ids.has(e.to)) indeg[e.to] = (indeg[e.to] || 0) + 1;
  }
  const q = steps.filter((n) => indeg[n.id] === 0).map((n) => n.id);
  const order = [];
  const adj = {};
  for (const e of edges || []) {
    if (ids.has(e.from) && ids.has(e.to)) {
      (adj[e.from] ||= []).push(e.to);
    }
  }
  while (q.length) {
    const id = q.shift();
    order.push(id);
    for (const t of adj[id] || []) {
      indeg[t]--;
      if (indeg[t] === 0) q.push(t);
    }
  }
  for (const n of steps) {
    if (!order.includes(n.id)) order.push(n.id);
  }
  const byId = Object.fromEntries(steps.map((n) => [n.id, n]));
  return order.map((id) => byId[id]);
}

export function generateAgentMd(wf) {
  const lines = [];
  lines.push(`# Agent: ${wf.id}`);
  lines.push('');
  lines.push('## Purpose');
  lines.push('');
  lines.push(wf.summary?.trim() || wf.name);
  lines.push('');
  lines.push('## When');
  lines.push('');
  lines.push(bullets(wf.when));
  lines.push('## When not');
  lines.push('');
  lines.push(bullets(wf.when_not));
  lines.push('## Steps');
  lines.push('');
  const steps = topoSteps(wf.nodes || [], wf.edges || []);
  if (!steps.length) {
    lines.push('_No step nodes._');
    lines.push('');
  } else {
    steps.forEach((n, i) => {
      lines.push(`${i + 1}. **${n.label}**`);
      if (n.notes?.trim()) {
        for (const para of n.notes.trim().split(/\n+/)) {
          lines.push(`   ${para}`);
        }
      }
      lines.push('');
    });
  }
  lines.push('## Handoffs');
  lines.push('');
  lines.push('| Situation | Go to |');
  lines.push('| --- | --- |');
  const handoffs = (wf.nodes || []).filter((n) => n.type === 'skill' || n.type === 'gate');
  if (!handoffs.length) {
    lines.push('| — | — |');
  } else {
    for (const n of handoffs) {
      const ref = n.ref ? `\`/${n.ref}\`` : n.label;
      lines.push(`| ${n.label} | ${ref} |`);
    }
  }
  lines.push('');
  lines.push('## Boundaries');
  lines.push('');
  if (wf.banned_actions?.length) {
    for (const a of wf.banned_actions) {
      lines.push(`- **Forbidden:** \`${a}\``);
    }
  } else {
    lines.push('_None listed._');
  }
  lines.push('');
  lines.push('## Inputs');
  lines.push('');
  lines.push(bullets(wf.inputs));
  lines.push('## Outputs');
  lines.push('');
  lines.push(bullets(wf.outputs));
  return lines.join('\n').replace(/\n+$/, '\n');
}
