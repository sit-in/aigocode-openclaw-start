#!/usr/bin/env bash
# AiGoCode × OpenClaw 一键配置
# 用法: bash <(curl -sL https://raw.githubusercontent.com/aigocode/aigocode-openclaw-start/main/setup.sh)
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}🦞 AiGoCode × OpenClaw 快速配置${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 0: Check if openclaw is installed
if ! command -v openclaw &> /dev/null; then
  echo -e "${YELLOW}⚠️  未检测到 OpenClaw，正在安装...${NC}"
  if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ 需要先安装 Node.js: https://nodejs.org${NC}"
    exit 1
  fi
  npm i -g openclaw@latest
  echo -e "${GREEN}✅ OpenClaw 安装完成${NC}"
  echo ""
fi

VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
echo -e "OpenClaw 版本: ${GREEN}${VERSION}${NC}"
echo ""

# Step 1: AiGoCode API Key
echo -e "${BOLD}📌 第1步：AiGoCode API Key${NC}"
echo -e "   去 ${CYAN}https://aigocode.com${NC} → 个人中心 → 复制你的 API Key"
echo -e "   格式: sk-xxxxxxxx"
echo ""
read -p "   请粘贴你的 API Key: " API_KEY

if [[ -z "$API_KEY" ]]; then
  echo -e "${RED}❌ API Key 不能为空${NC}"
  exit 1
fi
echo -e "   ${GREEN}✅ API Key 已记录${NC}"
echo ""

# Step 2: Choose models
echo -e "${BOLD}📌 第2步：选择模型${NC}"
echo ""
echo -e "   ${CYAN}[1]${NC} Claude Opus 4.6      （最强，推荐日常+编程）"
echo -e "   ${CYAN}[2]${NC} GPT-5.3 Codex        （OpenAI 最新，擅长编程）"
echo -e "   ${CYAN}[3]${NC} 全部都要              （推荐 ⭐）"
echo ""
read -p "   选择 [1/2/3，默认3]: " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-3}
echo ""

# Step 3: Telegram Bot (optional)
echo -e "${BOLD}📌 第3步：Telegram Bot（可选）${NC}"
echo -e "   想通过 Telegram 跟 AI 对话吗？"
echo -e "   找 ${CYAN}@BotFather${NC} 创建 Bot，拿到 Token"
echo ""
read -p "   Bot Token（没有直接回车跳过）: " TG_TOKEN
echo ""

# Step 4: Proxy (optional)
echo -e "${BOLD}📌 第4步：代理设置（可选）${NC}"
echo -e "   国内用户需要代理连接 Telegram / API"
echo -e "   常见: http://127.0.0.1:7890 或 http://127.0.0.1:7897"
echo ""
read -p "   代理地址（没有直接回车跳过）: " PROXY
echo ""

# Step 5: Gateway port
read -p "📌 第5步：Gateway 端口 [默认 18789]: " PORT
PORT=${PORT:-18789}
echo ""

# ===== Generate config =====
echo -e "${BOLD}⚙️  正在生成配置...${NC}"

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
mkdir -p "$OPENCLAW_HOME/workspace"

# Build providers based on choice
build_providers() {
  local claude_provider=""
  local codex_provider=""

  # Claude Opus 4.6
  if [[ "$MODEL_CHOICE" == "1" || "$MODEL_CHOICE" == "3" ]]; then
    claude_provider='"aigocode-claude": {
                "baseUrl": "https://api.aigocode.com",
                "apiKey": "'"$API_KEY"'",
                "auth": "api-key",
                "api": "anthropic-messages",
                "models": [
                    {
                        "id": "claude-opus-4-6",
                        "name": "Claude Opus 4.6",
                        "reasoning": true,
                        "input": ["text", "image"],
                        "contextWindow": 200000,
                        "maxTokens": 16384
                    }
                ]
            }'
  fi

  # GPT-5.3 Codex
  if [[ "$MODEL_CHOICE" == "2" || "$MODEL_CHOICE" == "3" ]]; then
    codex_provider='"openai-codex": {
                "baseUrl": "https://api.aigocode.com/v1",
                "apiKey": "'"$API_KEY"'",
                "auth": "api-key",
                "api": "openai-responses",
                "models": [
                    {
                        "id": "gpt-5.3-codex",
                        "name": "GPT-5.3 Codex",
                        "reasoning": true,
                        "input": ["text", "image"],
                        "contextWindow": 200000,
                        "maxTokens": 16384
                    }
                ]
            }'
  fi

  # Combine
  if [[ -n "$claude_provider" && -n "$codex_provider" ]]; then
    echo "${claude_provider},
            ${codex_provider}"
  elif [[ -n "$claude_provider" ]]; then
    echo "$claude_provider"
  else
    echo "$codex_provider"
  fi
}

# Determine default model
case "$MODEL_CHOICE" in
  1) DEFAULT_MODEL="aigocode-claude/claude-opus-4-6" ;;
  2) DEFAULT_MODEL="openai-codex/gpt-5.3-codex" ;;
  3) DEFAULT_MODEL="aigocode-claude/claude-opus-4-6" ;;
esac

PROVIDERS=$(build_providers)

# Build Telegram section
TG_SECTION=""
if [[ -n "$TG_TOKEN" ]]; then
  TG_PROXY=""
  [[ -n "$PROXY" ]] && TG_PROXY=',
            "proxy": "'"$PROXY"'"'
  TG_SECTION=',
    "channels": {
        "telegram": {
            "enabled": true,
            "dmPolicy": "pairing",
            "botToken": "'"$TG_TOKEN"'",
            "groupPolicy": "allowlist",
            "streamMode": "partial"'"$TG_PROXY"'
        }
    },
    "plugins": {
        "entries": {
            "telegram": { "enabled": true }
        }
    }'
fi

# Write openclaw.json
cat > "$OPENCLAW_HOME/openclaw.json" << JSONEOF
{
    "models": {
        "default": "$DEFAULT_MODEL",
        "providers": {
            $PROVIDERS
        }
    },
    "agents": {
        "defaults": {
            "workspace": "$OPENCLAW_HOME/workspace",
            "compaction": { "mode": "safeguard" },
            "maxConcurrent": 4,
            "subagents": { "maxConcurrent": 8 }
        }
    },
    "gateway": {
        "port": $PORT,
        "mode": "local",
        "bind": "loopback",
        "auth": { "mode": "open" }
    }${TG_SECTION}
}
JSONEOF

# Copy workspace templates if this is run from the starter-kit directory
if [[ -f "SOUL.md" ]]; then
  for f in SOUL.md IDENTITY.md USER.md AGENTS.md HEARTBEAT.md MEMORY.md TOOLS.md; do
    [[ -f "$f" ]] && cp "$f" "$OPENCLAW_HOME/workspace/" 2>/dev/null
  done
  [[ -d "docs" ]] && cp -r docs "$OPENCLAW_HOME/workspace/" 2>/dev/null
  mkdir -p "$OPENCLAW_HOME/workspace/memory" "$OPENCLAW_HOME/workspace/content"
  echo -e "${GREEN}✅ 模板文件已复制到 workspace${NC}"
fi

echo -e "${GREEN}✅ 配置已写入: $OPENCLAW_HOME/openclaw.json${NC}"
echo ""

# Set permissions
chmod 600 "$OPENCLAW_HOME/openclaw.json"

# ===== Summary =====
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🎉 配置完成！${NC}"
echo ""
echo -e "   📁 配置: ${CYAN}$OPENCLAW_HOME/openclaw.json${NC}"
echo -e "   🤖 模型: ${CYAN}$DEFAULT_MODEL${NC}"
echo -e "   🌐 端口: ${CYAN}$PORT${NC}"
[[ -n "$TG_TOKEN" ]] && echo -e "   💬 Telegram: ${GREEN}已配置${NC}"
[[ -n "$PROXY" ]]    && echo -e "   🔗 代理: ${GREEN}$PROXY${NC}"
echo ""
echo -e "${BOLD}▶ 启动：${NC}"
echo -e "   ${CYAN}openclaw gateway${NC}"
echo ""
[[ -n "$TG_TOKEN" ]] && echo -e "   然后去 Telegram 找你的 Bot 说句话 👋"
echo ""
echo -e "${CYAN}遇到问题？${NC}"
echo -e "   文档: https://docs.openclaw.ai"
echo -e "   社区: https://t.me/claw101"
echo -e "   AiGoCode: https://aigocode.com"
echo ""
