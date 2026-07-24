# My Skills

我个人的 [Cursor / Claude Agent Skills](https://docs.cursor.com/) 技能库。

每个技能都是一个包含 `SKILL.md` 的目录，AI 助手（Cursor、Claude 等）可以读取并调用它们来完成特定任务，例如按我的偏好生成提交信息、执行代码审查、处理特定格式的文件等。

## 目录结构

```
.
├── skills/                # 所有技能
│   ├── _template/         # 新建技能的模板
│   ├── commit-message/    # 示例：生成 Git 提交信息
│   └── code-review/       # 示例：代码审查
├── scripts/               # 安装脚本
│   ├── install.ps1        # Windows / PowerShell
│   └── install.sh         # macOS / Linux
└── README.md
```

## 安装到本地

技能需要放在 `~/.cursor/skills/`（个人级，所有项目可用）或项目的 `.cursor/skills/` 下才能被 AI 识别。

运行安装脚本会把 `skills/` 里的每个技能链接（或复制）到你的个人技能目录。

**Windows (PowerShell):**

```powershell
./scripts/install.ps1
```

**macOS / Linux:**

```bash
bash scripts/install.sh
```

安装脚本默认使用符号链接，这样修改本仓库里的技能会立即生效。加 `-Copy`（PowerShell）或 `--copy`（bash）参数可改为复制。

## 新建一个技能

1. 复制 `skills/_template` 目录并重命名为你的技能名（小写、用连字符，如 `my-new-skill`）
2. 编辑其中的 `SKILL.md`，填写 `name`、`description` 和正文
3. 重新运行安装脚本

## SKILL.md 规范要点

- `name`：最多 64 字符，仅小写字母、数字、连字符
- `description`：说明**做什么（WHAT）**和**何时用（WHEN）**，用第三人称书写，包含触发关键词
- 正文保持在 500 行以内，详细内容拆到同目录下的 `reference.md` 等文件
- 避免 Windows 风格路径（用 `scripts/x.py` 而非 `scripts\x.py`）

完整规范见每个技能目录里的示例。
