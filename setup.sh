#!/usr/bin/env bash
# AiGoCode × OpenClaw 一键配置
# 用法: bash <(curl -sL https://aigocode.com/start)
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

if [[ ! "$API_KEY" =~ ^sk- ]]; then
  echo -e "${RED}❌ API Key 格式不对，应该以 sk- 开头${NC}"
  exit 1
fi
echo -e "   ${GREEN}✅ API Key 已记录${NC}"
echo ""

# Step 2: Choose models
echo -e "${BOLD}📌 第2步：选择模型${NC}"
echo -e "   AiGoCode 支持以下模型："
echo ""
echo -e "   ${CYAN}[1]${NC} Claude Opus 4        （最强，推荐）"
echo -e "   ${CYAN}[2]${NC} Claude Sonnet 4      （性价比高）"
echo -e "   ${CYAN}[3]${NC} GPT-5 Codex          （OpenAI 最新）"
echo -e "   ${CYAN}[4]${NC} 全部都要              （推荐）"
echo ""
read -p "   选择 [1/2/3/4，默认4]: " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-4}

# Step 3: Telegram Bot (optional)
echo ""
echo -e "${BOLD}📌 第3步：Telegram Bot（可选）${NC}"
echo -e "   想通过 Telegram 跟 AI 对话吗？"
echo -e "   需要先找 ${CYAN}@BotFather${NC} 创建一个 Bot，拿到 Token"
echo -e "   格式: 123456789:ABCdefGHI..."
echo ""
read -p "   Telegram Bot Token（没有直接回车跳过）: " TG_TOKEN
echo ""

# Step 4: Proxy (optional)
echo -e "${BOLD}📌 第4步：代理设置（可选）${NC}"
echo -e "   国内用户需要代理才能连接 Telegram 和部分 API"
echo -e "   常见格式: http://127.0.0.1:7890"
echo ""
read -p "   代理地址（没有直接回车跳过）: " PROXY
echo ""

# Step 5: Gateway port
echo -e "${BOLD}📌 第5步：端口${NC}"
read -p "   Gateway 端口 [默认 18789]: " PORT
PORT=${PORT:-18789}
echo ""

# ===== Generate config =====
echo -e "${BOLD}⚙️  正在生成配置...${NC}"

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
mkdir -p "$OPENCLAW_HOME/workspace"

# Build models section based on choice
build_models() {
  local models=""
  
  # Claude Opus
  if [[ "$MODEL_CHOICE" == "1" || "$MODEL_CHOICE" == "4" ]]; then
    models+='
                    {
                        "id": "claude-opus-4",
                        "name": "Claude Opus 4",
                        "reasoning": true,
                        "input": ["text", "image"],
                        "contextWindow": 200000,
                        "maxTokens": 16384
                    }'
  fi
  
  # Claude Sonnet
  if [[ "$MODEL_CHOICE" == "2" || "$MODEL_CHOICE" == "4" ]]; then
    [[ -n "$models" ]] && models+=","
    models+='
                    {
                        "id": "claude-sonnet-4",
                        "name": "Claude Sonnet 4",
                        "reasoning": true,
                        "input": ["text", "image"],
                        "contextWindow": 200000,
                        "maxTokens": 16384
                    }'
  fi
  
  # GPT-5 Codex
  if [[ "$MODEL_CHOICE" == "3" || "$MODEL_CHOICE" == "4" ]]; then
    [[ -n "$models" ]] && models+=","
    models+='
                    {
                        "id": "gpt-5-codex",
                        "name": "GPT-5 Codex",
                        "reasoning": true,
                        "input": ["text", "image"],
                        "contextWindow": 200000,
                        "maxTokens": 8192
                    }'
  fi
  
  echo "$models"
}

MODELS=$(build_models)

# Determine default model
case "$MODEL_CHOICE" in
  1) DEFAULT_MODEL="aigocode/claude-opus-4" ;;
  2) DEFAULT_MODEL="aigocode/claude-sonnet-4" ;;
  3) DEFAULT_MODEL="aigocode/gpt-5-codex" ;;
  4) DEFAULT_MODEL="aigocode/claude-opus-4" ;;
esac

# Build Telegram section
TG_SECTION=""
if [[ -n "$TG_TOKEN" ]]; then
  TG_SECTION=',
    "channels": {
        "telegram": {
            "enabled": true,
            "dmPolicy": "pairing",
            "botToken": "'"$TG_TOKEN"'",
            "groupPolicy": "allowlist",
            "streamMode": "partial"'"$([ -n "$PROXY" ] && echo ',
            "proxy": "'"$PROXY"'"')"'
        }
    },
    "plugins": {
        "entries": {
            "telegram": {
                "enabled": true
            }
        }
    }'
fi

# Build proxy env section for gateway
PROXY_ENV=""
if [[ -n "$PROXY" ]]; then
  PROXY_ENV=',
        "env": {
            "HTTPS_PROXY": "'"$PROXY"'",
            "HTTP_PROXY": "'"$PROXY"'",
            "NODE_OPTIONS": "--use-env-proxy"
        }'
fi

# Write openclaw.json
cat > "$OPENCLAW_HOME/openclaw.json" << JSONEOF
{
    "models": {
        "default": "$DEFAULT_MODEL",
        "providers": {
            "aigocode": {
                "baseUrl": "https://api.aigocode.com",
                "apiKey": "$API_KEY",
                "auth": "api-key",
                "api": "anthropic-messages",
                "models": [${MODELS}
                ]
            }
        }
    },
    "agents": {
        "defaults": {
            "workspace": "$OPENCLAW_HOME/workspace",
            "compaction": {
                "mode": "safeguard"
            },
            "maxConcurrent": 4,
            "subagents": {
                "maxConcurrent": 8
            }
        }
    },
    "gateway": {
        "port": $PORT,
        "mode": "local",
        "bind": "loopback",
        "auth": {
            "mode": "open"
        }
    }${TG_SECTION}
}
JSONEOF

echo -e "${GREEN}✅ 配置已写入: $OPENCLAW_HOME/openclaw.json${NC}"
echo ""

# ===== Summary =====
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🎉 配置完成！${NC}"
echo ""
echo -e "   📁 配置文件: ${CYAN}$OPENCLAW_HOME/openclaw.json${NC}"
echo -e "   🤖 默认模型: ${CYAN}$DEFAULT_MODEL${NC}"
echo -e "   🌐 端口:     ${CYAN}$PORT${NC}"
[[ -n "$TG_TOKEN" ]] && echo -e "   💬 Telegram:  ${GREEN}已配置${NC}"
[[ -n "$PROXY" ]]    && echo -e "   🔗 代理:      ${GREEN}$PROXY${NC}"
echo ""
echo -e "${BOLD}下一步：${NC}"
echo -e "   启动: ${CYAN}openclaw gateway${NC}"
[[ -n "$TG_TOKEN" ]] && echo -e "   然后去 Telegram 找你的 Bot 说句话试试 👋"
echo ""
echo -e "${CYAN}遇到问题？${NC}"
echo -e "   文档: https://docs.openclaw.ai"
echo -e "   社区: https://t.me/claw101"
echo -e "   客服: https://aigocode.com"
echo ""
