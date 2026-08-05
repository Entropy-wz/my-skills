import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  addEdge,
  useEdgesState,
  useNodesState,
  Handle,
  Position,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

function TypeNode({ data }) {
  const color =
    data.nodeType === 'gate' ? '#e6a23c' : data.nodeType === 'skill' ? '#6cb2ff' : '#7fd99a';
  return (
    <div
      style={{
        padding: '8px 12px',
        borderRadius: 8,
        border: `1px solid ${color}`,
        background: '#1e2229',
        minWidth: 140,
        fontSize: 12,
      }}
    >
      <Handle type="target" position={Position.Left} />
      <div style={{ color, fontSize: 10, textTransform: 'uppercase' }}>{data.nodeType}</div>
      <div>{data.label}</div>
      {data.ref ? <div style={{ color: '#9aa0a6' }}>/{data.ref}</div> : null}
      <Handle type="source" position={Position.Right} />
    </div>
  );
}

const nodeTypes = { typed: TypeNode };

function wfToFlow(wf) {
  const nodes = (wf.nodes || []).map((n) => ({
    id: n.id,
    type: 'typed',
    position: wf.ui?.[n.id] || { x: 0, y: 0 },
    data: { label: n.label, nodeType: n.type, ref: n.ref, notes: n.notes },
  }));
  const edges = (wf.edges || []).map((e, i) => ({
    id: `e-${e.from}-${e.to}-${i}`,
    source: e.from,
    target: e.to,
    label: e.condition || undefined,
  }));
  return { nodes, edges };
}

function flowToWf(base, nodes, edges) {
  const ui = { ...(base.ui || {}) };
  const outNodes = nodes.map((n) => {
    ui[n.id] = { x: n.position.x, y: n.position.y };
    return {
      id: n.id,
      type: n.data.nodeType,
      label: n.data.label,
      ref: n.data.ref || undefined,
      notes: n.data.notes || undefined,
    };
  });
  const outEdges = edges.map((e) => ({
    from: e.source,
    to: e.target,
    condition: typeof e.label === 'string' && e.label ? e.label : undefined,
  }));
  return { ...base, nodes: outNodes, edges: outEdges, ui };
}

const emptyWf = (id) => ({
  id,
  name: id,
  version: '1',
  summary: '',
  when: [],
  when_not: [],
  inputs: [],
  outputs: [],
  banned_actions: [],
  nodes: [{ id: 'step-1', type: 'step', label: 'First step', notes: '' }],
  edges: [],
  ui: { 'step-1': { x: 120, y: 80 } },
});

export default function App() {
  const [meta, setMeta] = useState(null);
  const [agents, setAgents] = useState([]);
  const [selected, setSelected] = useState(null);
  const [wf, setWf] = useState(null);
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [dirty, setDirty] = useState(false);
  const [errors, setErrors] = useState([]);
  const [status, setStatus] = useState('');
  const [selectedNodeId, setSelectedNodeId] = useState(null);
  const [needsMigrate, setNeedsMigrate] = useState(false);

  const refreshAgents = useCallback(async () => {
    const r = await fetch('/api/agents');
    const j = await r.json();
    setAgents(j.agents || []);
  }, []);

  useEffect(() => {
    fetch('/api/meta')
      .then((r) => r.json())
      .then(setMeta)
      .catch((e) => setErrors([String(e)]));
    refreshAgents();
  }, [refreshAgents]);

  const loadAgent = async (name) => {
    if (dirty && !confirm('Discard unsaved changes?')) return;
    setSelected(name);
    setErrors([]);
    setStatus('');
    setSelectedNodeId(null);
    const r = await fetch(`/api/agents/${name}`);
    if (r.status === 404) {
      const j = await r.json();
      setNeedsMigrate(!!j.hasAgentMd);
      setWf(null);
      setNodes([]);
      setEdges([]);
      setDirty(false);
      return;
    }
    if (!r.ok) {
      setErrors([await r.text()]);
      return;
    }
    const j = await r.json();
    setNeedsMigrate(false);
    setWf(j.workflow);
    const flow = wfToFlow(j.workflow);
    setNodes(flow.nodes);
    setEdges(flow.edges);
    setDirty(false);
  };

  const onConnect = useCallback(
    (conn) => {
      setEdges((eds) => addEdge({ ...conn, id: `e-${conn.source}-${conn.target}-${Date.now()}` }, eds));
      setDirty(true);
    },
    [setEdges]
  );

  const markDirtyNodes = useCallback(
    (chs) => {
      onNodesChange(chs);
      if (chs.some((c) => c.type === 'position' || c.type === 'remove' || c.type === 'add')) setDirty(true);
    },
    [onNodesChange]
  );

  const markDirtyEdges = useCallback(
    (chs) => {
      onEdgesChange(chs);
      setDirty(true);
    },
    [onEdgesChange]
  );

  const currentWf = useMemo(() => {
    if (!wf) return null;
    return flowToWf(wf, nodes, edges);
  }, [wf, nodes, edges]);

  const selectedNode = nodes.find((n) => n.id === selectedNodeId);

  const updateSelected = (patch) => {
    setNodes((ns) =>
      ns.map((n) => (n.id === selectedNodeId ? { ...n, data: { ...n.data, ...patch } } : n))
    );
    setDirty(true);
  };

  const addNode = (type) => {
    if (!wf) return;
    const id = `${type}-${Date.now().toString(36)}`;
    setNodes((ns) => [
      ...ns,
      {
        id,
        type: 'typed',
        position: { x: 160 + ns.length * 20, y: 120 + ns.length * 10 },
        data: {
          label: type === 'step' ? 'New step' : type,
          nodeType: type,
          ref: type === 'step' ? undefined : 'skill-name',
          notes: '',
        },
      },
    ]);
    setDirty(true);
  };

  const save = async () => {
    if (!selected || !currentWf) return;
    setErrors([]);
    const r = await fetch(`/api/agents/${selected}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ workflow: currentWf }),
    });
    const j = await r.json();
    if (!r.ok) {
      setErrors(j.errors || [j.error || 'save failed']);
      setStatus('');
      return;
    }
    setWf(currentWf);
    setDirty(false);
    setStatus(
      j.preservedAgentMd
        ? 'Saved YAML + snapshot; AGENT.md preserved (D1)'
        : 'Saved (SoT + snapshot sync)'
    );
    refreshAgents();
  };

  const migrate = async () => {
    if (!selected) return;
    setErrors([]);
    const r = await fetch(`/api/agents/${selected}/migrate`, { method: 'POST' });
    const j = await r.json();
    if (!r.ok) {
      setErrors(j.errors || [j.error || 'migrate failed']);
      return;
    }
    setNeedsMigrate(false);
    setWf(j.workflow);
    const flow = wfToFlow(j.workflow);
    setNodes(flow.nodes);
    setEdges(flow.edges);
    setDirty(false);
    setStatus('Migrated YAML only — AGENT.md unchanged (D1)');
    refreshAgents();
  };

  const createFixture = async () => {
    const id = 'studio-fixture';
    if (dirty && !confirm('Discard unsaved changes?')) return;
    setSelected(id);
    const w = emptyWf(id);
    w.summary = 'Graph-first fixture for Agent Flow Studio acceptance.';
    w.when = ['Testing studio save round-trip'];
    w.when_not = ['Production demos'];
    w.banned_actions = ['push', 'pr_create'];
    w.inputs = ['repo root'];
    w.outputs = ['report'];
    setWf(w);
    const flow = wfToFlow(w);
    setNodes(flow.nodes);
    setEdges(flow.edges);
    setNeedsMigrate(false);
    setDirty(true);
    setStatus('New fixture in memory — click Save to write + sync');
  };

  return (
    <div className="app">
      <header className="top">
        <h1>Agent Flow Studio</h1>
        <span className="meta">{meta ? meta.root : '…'}</span>
        <button type="button" className="btn" onClick={createFixture}>
          New fixture
        </button>
        <button type="button" className="btn" disabled={!needsMigrate} onClick={migrate}>
          Migrate
        </button>
        <button type="button" className="btn primary" disabled={!wf || !dirty} onClick={save}>
          Save{dirty ? ' *' : ''}
        </button>
      </header>

      <aside className="sidebar">
        <h2>Agents</h2>
        {agents.map((a) => (
          <button
            key={a.name}
            type="button"
            className={`agent-item ${selected === a.name ? 'active' : ''}`}
            onClick={() => loadAgent(a.name)}
          >
            {a.name}
            <div className="tag">{a.hasYaml ? 'yaml' : 'md-only'}</div>
          </button>
        ))}
      </aside>

      <main className="canvas-wrap">
        {!wf && needsMigrate ? (
          <div className="empty">
            <p>No workflow.yaml for <strong>{selected}</strong>.</p>
            <p>Migrate from AGENT.md (writes YAML only; does not change AGENT.md).</p>
            <button type="button" className="btn primary" onClick={migrate}>
              Migrate from AGENT.md
            </button>
          </div>
        ) : !wf ? (
          <div className="empty">Select an agent or create a fixture.</div>
        ) : (
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={markDirtyNodes}
            onEdgesChange={markDirtyEdges}
            onConnect={onConnect}
            nodeTypes={nodeTypes}
            onNodeClick={(_, n) => setSelectedNodeId(n.id)}
            fitView
          >
            <Background gap={16} />
            <MiniMap />
            <Controls />
          </ReactFlow>
        )}
      </main>

      <aside className="props">
        <h2>Pack</h2>
        {wf ? (
          <>
            <label className="field">name</label>
            <input
              value={wf.name || ''}
              onChange={(e) => {
                setWf({ ...wf, name: e.target.value });
                setDirty(true);
              }}
            />
            <label className="field">summary</label>
            <textarea
              value={wf.summary || ''}
              onChange={(e) => {
                setWf({ ...wf, summary: e.target.value });
                setDirty(true);
              }}
            />
            <label className="field">when (one per line)</label>
            <textarea
              value={(wf.when || []).join('\n')}
              onChange={(e) => {
                setWf({
                  ...wf,
                  when: e.target.value.split('\n').map((s) => s.trim()).filter(Boolean),
                });
                setDirty(true);
              }}
            />
            <label className="field">when_not</label>
            <textarea
              value={(wf.when_not || []).join('\n')}
              onChange={(e) => {
                setWf({
                  ...wf,
                  when_not: e.target.value.split('\n').map((s) => s.trim()).filter(Boolean),
                });
                setDirty(true);
              }}
            />
            <label className="field">banned_actions</label>
            <textarea
              value={(wf.banned_actions || []).join('\n')}
              onChange={(e) => {
                setWf({
                  ...wf,
                  banned_actions: e.target.value.split('\n').map((s) => s.trim()).filter(Boolean),
                });
                setDirty(true);
              }}
            />
            <label className="field">inputs</label>
            <textarea
              value={(wf.inputs || []).join('\n')}
              onChange={(e) => {
                setWf({
                  ...wf,
                  inputs: e.target.value.split('\n').map((s) => s.trim()).filter(Boolean),
                });
                setDirty(true);
              }}
            />
            <label className="field">outputs</label>
            <textarea
              value={(wf.outputs || []).join('\n')}
              onChange={(e) => {
                setWf({
                  ...wf,
                  outputs: e.target.value.split('\n').map((s) => s.trim()).filter(Boolean),
                });
                setDirty(true);
              }}
            />
            <label className="field" style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={Boolean(wf.preserve_agent_md)}
                onChange={(e) => {
                  setWf({ ...wf, preserve_agent_md: e.target.checked });
                  setDirty(true);
                }}
              />
              preserve AGENT.md (D1)
            </label>
            <h2>Palette</h2>
            <div className="palette">
              <button type="button" className="btn" onClick={() => addNode('step')}>
                + step
              </button>
              <button type="button" className="btn" onClick={() => addNode('skill')}>
                + skill
              </button>
              <button type="button" className="btn" onClick={() => addNode('gate')}>
                + gate
              </button>
            </div>
          </>
        ) : null}

        <h2>Node</h2>
        {selectedNode ? (
          <>
            <label className="field">label</label>
            <input
              value={selectedNode.data.label || ''}
              onChange={(e) => updateSelected({ label: e.target.value })}
            />
            {(selectedNode.data.nodeType === 'skill' || selectedNode.data.nodeType === 'gate') && (
              <>
                <label className="field">ref</label>
                <input
                  value={selectedNode.data.ref || ''}
                  onChange={(e) => updateSelected({ ref: e.target.value })}
                />
              </>
            )}
            <label className="field">notes</label>
            <textarea
              value={selectedNode.data.notes || ''}
              onChange={(e) => updateSelected({ notes: e.target.value })}
            />
          </>
        ) : (
          <p style={{ color: 'var(--muted)', fontSize: 12 }}>Select a node</p>
        )}

        {errors.length ? <div className="errors">{errors.join('\n')}</div> : null}
        {status ? <div className="ok">{status}</div> : null}
      </aside>
    </div>
  );
}
