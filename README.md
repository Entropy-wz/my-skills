# My Toolkit

个人工具库：Cursor / Claude **Skills**、可运行的 **Tools**、小型 **Agents**，以及按能力打包的 **Kits**（例如自建搜索）。

由原先的纯 skills 仓库演进为混合布局（skills 保持扁平；多部件能力进 `kits/`）。

## 目录结构

```
.
├── skills/                # 纯编排 / 流程类技能（扁平）
│   ├── _template/
│   ├── build-loop/
│   ├── code-review/
│   ├── commit-message/
│   ├── hunk-walkthrough/
│   ├── merge-code-review/
│   └── work-lanes/
├── kits/                  # 多部件能力包（skill + tools + docker + …）
│   ├── README.md          # kit 约定
│   └── _template/         # 新建 kit 的模板（不安装）
├── tools/                 # 跨 kit 共享脚本 / CLI
├── agents/                # 跨 kit 小型 agent
├── docs/                  # 设计文档 / ADR
├── scripts/
│   ├── install.ps1        # Windows：安装 skills + kit skills
│   ├── install.sh         # macOS / Linux
│   └── check-layout.ps1   # 布局与发现逻辑冒烟检查
└── README.md
```

### 放哪里？

| 放这里 | 什么时候 |
| --- | --- |
| `skills/` | 几乎只有 `SKILL.md` 的流程/编排技能 |
| `kits/<name>/` | 需要 docker、本地工具、小 agent 等与 skill 绑在一起 |
| `tools/` / `agents/` | 被多个 kit 复用的共享件 |
| `docs/` | 设计与决策（Lane A 文档） |

详见 [`kits/README.md`](kits/README.md)。

## 安装到本地

技能需要出现在 `~/.cursor/skills/`（或项目 `.cursor/skills/`）才会被 AI 识别。

安装脚本会安装：

1. `skills/<name>/SKILL.md`（跳过 `_…`）
2. `kits/<name>/skill/SKILL.md`（跳过 `_…`；安装名为 kit 目录名）

**Windows (PowerShell):**

```powershell
./scripts/install.ps1
./scripts/install.ps1 -Copy   # 无符号链接权限时用复制
```

**macOS / Linux:**

```bash
bash scripts/install.sh
bash scripts/install.sh --copy
```

默认符号链接（改仓库即生效）。`-Copy` / `--copy` 改为复制。

## 冒烟检查

```powershell
./scripts/check-layout.ps1
```

## 新建 skill

1. 复制 `skills/_template` → `skills/<name>`
2. 编辑 `SKILL.md`
3. 重新运行安装脚本

## 新建 kit

1. 复制 `kits/_template` → `kits/<name>`（不要用 `_` 前缀）
2. 按需填写 `skill/`、`tools/`、`agents/`、`docker/`
3. 若有 `skill/SKILL.md`，重新运行安装脚本

## SKILL.md 规范要点

- `name`：最多 64 字符，仅小写字母、数字、连字符
- `description`：说明**做什么（WHAT）**和**何时用（WHEN）**，第三人称，含触发关键词
- 正文尽量 < 500 行；细节拆到同目录 `reference.md` 等
- 路径用正斜杠风格（`scripts/x.py`）
