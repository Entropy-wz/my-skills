import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const schemaPath = path.join(__dirname, '..', '..', 'schema', 'workflow.schema.json');
const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));

const ajv = new Ajv2020({ allErrors: true, strict: false });
addFormats(ajv);
const validateSchema = ajv.compile(schema);

const V1_TYPES = new Set(['step', 'skill', 'gate']);

/**
 * @returns {{ ok: true, data: object } | { ok: false, errors: string[] }}
 */
export function validateWorkflow(data, { folderName } = {}) {
  const errors = [];
  if (!validateSchema(data)) {
    for (const e of validateSchema.errors || []) {
      errors.push(`${e.instancePath || '/'} ${e.message}`);
    }
  }
  if (folderName && data?.id && data.id !== folderName) {
    errors.push(`id "${data.id}" must equal folder name "${folderName}"`);
  }
  const nodeIds = new Set();
  for (const n of data?.nodes || []) {
    if (nodeIds.has(n.id)) errors.push(`duplicate node id: ${n.id}`);
    nodeIds.add(n.id);
    if (n.type && !V1_TYPES.has(n.type)) {
      errors.push(`node ${n.id}: type "${n.type}" not yet supported (v1: step|skill|gate)`);
    }
    if ((n.type === 'skill' || n.type === 'gate') && !n.ref) {
      errors.push(`node ${n.id}: ${n.type} requires ref`);
    }
  }
  for (const e of data?.edges || []) {
    if (!nodeIds.has(e.from)) errors.push(`edge from unknown node: ${e.from}`);
    if (!nodeIds.has(e.to)) errors.push(`edge to unknown node: ${e.to}`);
  }
  if (errors.length) return { ok: false, errors };
  return { ok: true, data };
}
