---
name: commit-message
description: 分析 git 暂存区的改动并生成符合 Conventional Commits 规范的提交信息。当用户请求撰写/生成 commit message、编写提交信息或审查暂存改动时使用。
disable-model-invocation: true
---

# Commit Message

## 用途

根据 `git diff --staged` 的内容，生成简洁、规范的 Git 提交信息。

## 使用步骤

1. 运行 `git diff --staged` 查看已暂存的改动（若为空，提示用户先 `git add`）
2. 判断改动的主要类型（见下表）
3. 用一行 subject 概括「为什么改」，而非逐条罗列「改了什么」
4. 需要时补充 body，说明动机和上下文

## 类型前缀

| 前缀 | 含义 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docs` | 文档 |
| `refactor` | 重构（不改变外部行为） |
| `test` | 测试 |
| `chore` | 构建 / 工具 / 依赖 |
| `perf` | 性能优化 |

## 格式

```
<type>(<scope>): <subject>

<body 可选，解释为什么这么改>
```

- subject 使用祈使句、小写开头、不超过 72 字符、结尾不加句号
- scope 可选，表示受影响的模块

## 示例

**输入：** 新增了基于 JWT 的登录接口和校验中间件

**输出：**

```
feat(auth): 实现基于 JWT 的用户认证

新增登录接口与 token 校验中间件，替换原有的 session 方案。
```

**输入：** 修复报表里时区导致日期显示错误

**输出：**

```
fix(reports): 修正时区转换导致的日期显示错误

统一使用 UTC 时间戳生成报表，避免跨时区偏移。
```
