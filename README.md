# 🦞 AiGoCode × OpenClaw 新手启动包

> 3 分钟拥有你的 AI 私人助手。基于 [OpenClaw](https://openclaw.ai)，由 [AiGoCode](https://aigocode.com) 提供 AI 模型支持。

<p align="center">
  <img src="https://img.shields.io/badge/OpenClaw-2026.2.23-blueviolet" alt="OpenClaw" />
  <img src="https://img.shields.io/badge/AiGoCode-Claude%20|%20GPT-blue" alt="AiGoCode" />
  <img src="https://img.shields.io/badge/Language-中文-orange" alt="Chinese" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" />
</p>

---

## ✨ 这是什么？

一个预配置好的 OpenClaw AI 助手模板，**内置 AiGoCode 模型接入**，帮你跳过最难的配置步骤。

**你不需要：**
- ❌ 自己写 `openclaw.json`
- ❌ 研究 models/providers 怎么配
- ❌ 搞清楚 API 格式是 OpenAI 还是 Anthropic

**你只需要：**
- ✅ 一个 AiGoCode API Key（[去注册](https://aigocode.com)）
- ✅ 运行一行命令

## 🚀 快速开始

### 第 1 步：安装 OpenClaw

```bash
npm install -g openclaw
```

### 第 2 步：一键配置

```bash
bash <(curl -sL https://raw.githubusercontent.com/你的用户名/aigocode-starter-kit/main/setup.sh)
```

或者手动：

```bash
git clone https://github.com/sit-in/-aigocode-openclaw-start.git my-assistant
cd my-assistant
bash setup.sh
```

脚本会问你 3 个问题：
1. **AiGoCode API Key** — 去 aigocode.com 复制
2. **Telegram Bot Token** — 可选，找 @BotFather 创建
3. **代理地址** — 国内用户需要，如 `http://127.0.0.1:7890`

30 秒搞定 ✅

### 第 3 步：个性化（可选）

```bash
# 给助手起名字、设定性格
nano SOUL.md
nano IDENTITY.md
nano USER.md
```

### 第 4 步：启动

```bash
openclaw gateway
```

去 Telegram 找你的 Bot 说句话试试 👋

---

## 🤖 支持的模型

通过 AiGoCode，你可以使用：

| 模型 | 说明 | 推荐场景 |
|------|------|---------|
| Claude Opus 4 | Anthropic 最强模型 | 复杂推理、编程、写作 |
| Claude Sonnet 4 | 性价比之王 | 日常对话、快速任务 |
| GPT-5 Codex | OpenAI 最新 | 编程、代码审查 |

在 `openclaw.json` 中切换默认模型：
```json
"default": "aigocode/claude-opus-4"
```

## 📁 文件结构

```
my-assistant/
├── setup.sh           # 一键配置脚本
├── openclaw.example.json  # 配置文件示例（参考用）
├── AGENTS.md          # 助手行为准则
├── SOUL.md            # 灵魂：性格、语气、边界
├── USER.md            # 用户画像
├── IDENTITY.md        # 身份：名字、形象
├── HEARTBEAT.md       # 心跳检查项
├── MEMORY.md          # 长期记忆
├── TOOLS.md           # 工具备忘
├── memory/            # 每日记忆
├── content/           # 内容输出
└── docs/
    └── SKILLS-GUIDE.md
```

## 🔑 AiGoCode 是什么？

[AiGoCode](https://aigocode.com) 是一个 AI 模型中转服务，解决国内用户使用 Claude / ChatGPT 的问题：

- 🌐 **一个 Key 用所有模型** — Claude、GPT、Gemini 统一接入
- ⚡ **稳定快速** — 多节点负载均衡，不掉链子
- 💰 **灵活计费** — 按量付费，不用 $20/月订阅

## 📖 进阶

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [AiGoCode 使用指南](https://aigocode.com/docs)
- [推荐 Skills 列表](docs/SKILLS-GUIDE.md)
- [OpenClaw 中文社区](https://t.me/claw101)

## ❓ 常见问题

**Q: 启动后报错 "model not found"？**
A: 检查 `openclaw.json` 里的 `apiKey` 是否正确，去 aigocode.com 确认 Key 状态。

**Q: Telegram 连不上？**
A: 国内需要配置代理。在 `setup.sh` 第 4 步填入你的代理地址。

**Q: 怎么换模型？**
A: 编辑 `~/.openclaw/openclaw.json`，修改 `models.default` 字段。

**Q: API Key 安全吗？**
A: Key 存储在本地 `openclaw.json` 中，建议 `chmod 600` 限制权限。不要提交到 Git。

## 📄 License

MIT License

---

*基于 [xiaomo-starter-kit](https://github.com/mengjian-github/xiaomo-starter-kit) 改造，感谢孟健和小墨 🐈⬛*
