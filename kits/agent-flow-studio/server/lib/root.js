import fs from 'node:fs';
import path from 'node:path';

export function resolveRoot(argv = process.argv.slice(2), env = process.env) {
  let fromArg;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--root' && argv[i + 1]) {
      fromArg = argv[i + 1];
      break;
    }
  }
  const candidate = fromArg || env.ROOT || env.MY_SKILLS_ROOT || process.cwd();
  const root = path.resolve(candidate);
  const agents = path.join(root, 'agents');
  const orch = path.join(root, 'skills', 'orchestration');
  if (!fs.existsSync(agents) || !fs.existsSync(orch)) {
    throw new Error(
      `ROOT is not a my-skills checkout (need agents/ and skills/orchestration/): ${root}`
    );
  }
  return root;
}

export function wantServeStatic(argv = process.argv.slice(2)) {
  return argv.includes('--serve-static');
}
