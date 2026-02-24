#!/usr/bin/env bash
# AiGoCode × OpenClaw 一键配置
# 用法: bash <(curl -sL https://raw.githubusercontent.com/sit-in/-aigocode-openclaw-start/main/setup.sh)
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${CYAN}🦞 AiGoCode × OpenClaw 快速配置${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ===== 环境检查 =====

# Check OS
OS="$(uname -s)"
case "$OS" in
  Linux*)  PLATFORM="linux" ;;
  Darwin*) PLATFORM="mac" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  *) PLATFORM="unknown" ;;
esac
echo -e "系统: ${GREEN}${OS}${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
  echo -e "${RED}❌ 未检测到 Node.js${NC}"
  echo -e "   请先安装: ${CYAN}https://nodejs.org${NC} (推荐 v20+)"
  if [[ "$PLATFORM" == "mac" ]]; then
    echo -e "   或: ${CYAN}brew install node${NC}"
  elif [[ "$PLATFORM" == "linux" ]]; then
    echo -e "   或: ${CYAN}curl -fsSL https://fnm.vercel.app/install | bash && fnm install 22${NC}"
  fi
  exit 1
fi

NODE_VER=$(node -v)
echo -e "Node.js: ${GREEN}${NODE_VER}${NC}"

# Check Node version >= 20
NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
if [[ "$NODE_MAJOR" -lt 20 ]]; then
  echo -e "${YELLOW}⚠️  Node.js 版本较低（建议 v20+），可能遇到兼容问题${NC}"
fi

# Check/install OpenClaw
if command -v openclaw &> /dev/null; then
  VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
  echo -e "OpenClaw: ${GREEN}${VERSION}${NC}"
else
  echo -e "${YELLOW}⚠️  未检测到 OpenClaw，正在安装...${NC}"
  npm i -g openclaw@latest 2>&1 | tail -1
  VERSION=$(openclaw --version 2>/dev/null || echo "installed")
  echo -e "OpenClaw: ${GREEN}${VERSION}${NC}"
fi
echo ""

# ===== 检测已有配置 =====
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  echo -e "${YELLOW}⚠️  检测到已有配置: $OPENCLAW_HOME/openclaw.json${NC}"
  read -p "   覆盖？(y/N): " OVERWRITE
  if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
    echo -e "   已取消。如需重新配置，先备份或删除旧配置。"
    exit 0
  fi
  # Backup existing config
  cp "$OPENCLAW_HOME/openclaw.json" "$OPENCLAW_HOME/openclaw.json.bak.$(date +%s)"
  echo -e "   ${DIM}已备份到 openclaw.json.bak${NC}"
  echo ""
fi

# ===== 开始配置 =====

# Step 1: AiGoCode API Key
echo -e "${BOLD}📌 第1步：AiGoCode API Key${NC}"
echo -e "   去 ${CYAN}https://aigocode.com${NC} → 个人中心 → 复制 API Key"
echo ""
while true; do
  read -p "   API Key: " API_KEY
  if [[ -z "$API_KEY" ]]; then
    echo -e "   ${RED}不能为空，请重新输入${NC}"
  else
    break
  fi
done
echo -e "   ${GREEN}✅${NC}"
echo ""

# Step 2: Choose models
echo -e "${BOLD}📌 第2步：选择模型${NC}"
echo ""
echo -e "   ${CYAN}[1]${NC} Claude Opus 4.6      最强推理 + 编程 + 写作"
echo -e "   ${CYAN}[2]${NC} GPT-5.3 Codex        OpenAI 最新编程模型"
echo -e "   ${CYAN}[3]${NC} 全部都要              ${GREEN}推荐 ⭐${NC}"
echo ""
read -p "   选择 [1/2/3，默认3]: " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-3}

if [[ ! "$MODEL_CHOICE" =~ ^[123]$ ]]; then
  MODEL_CHOICE=3
fi
echo ""

# Step 3: Telegram Bot (optional)
echo -e "${BOLD}📌 第3步：Telegram Bot${NC} ${DIM}（可选，回车跳过）${NC}"
echo -e "   Telegram 上找 ${CYAN}@BotFather${NC} → /newbot → 拿到 Token"
echo ""
read -p "   Bot Token: " TG_TOKEN

if [[ -n "$TG_TOKEN" ]]; then
  # Validate Telegram token format: digits:alphanumeric
  if [[ ! "$TG_TOKEN" =~ ^[0-9]+:.+ ]]; then
    echo -e "   ${YELLOW}⚠️  Token 格式看起来不对（应该是 数字:字母 格式），继续使用${NC}"
  fi
  echo -e "   ${GREEN}✅${NC}"
fi
echo ""

# Step 4: Proxy (optional)
echo -e "${BOLD}📌 第4步：代理${NC} ${DIM}（可选，回车跳过）${NC}"
echo -e "   国内连 Telegram 需要代理"
echo -e "   ${DIM}常见: http://127.0.0.1:7890  http://127.0.0.1:7897${NC}"
echo ""
read -p "   代理地址: " PROXY

if [[ -n "$PROXY" && ! "$PROXY" =~ ^https?:// ]]; then
  echo -e "   ${YELLOW}⚠️  代理地址通常以 http:// 开头，已自动补全${NC}"
  PROXY="http://$PROXY"
fi
[[ -n "$PROXY" ]] && echo -e "   ${GREEN}✅ $PROXY${NC}"
echo ""

# Step 5: Gateway port
echo -e "${BOLD}📌 第5步：端口${NC} ${DIM}（回车用默认）${NC}"
read -p "   Gateway 端口 [18789]: " PORT
PORT=${PORT:-18789}

# Validate port is a number
if [[ ! "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1024 ]] || [[ "$PORT" -gt 65535 ]]; then
  echo -e "   ${YELLOW}⚠️  端口无效，使用默认 18789${NC}"
  PORT=18789
fi

# Check if port is already in use
if command -v ss &> /dev/null && ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
  echo -e "   ${YELLOW}⚠️  端口 $PORT 已被占用，可能需要换一个${NC}"
elif command -v lsof &> /dev/null && lsof -i ":$PORT" &>/dev/null; then
  echo -e "   ${YELLOW}⚠️  端口 $PORT 已被占用，可能需要换一个${NC}"
fi
echo ""

# ===== 生成配置 =====
echo -e "${BOLD}⚙️  生成配置中...${NC}"
echo ""

mkdir -p "$OPENCLAW_HOME/workspace/memory"
mkdir -p "$OPENCLAW_HOME/workspace/content"

# Build providers
build_providers() {
  local claude_provider=""
  local codex_provider=""

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

  if [[ -n "$claude_provider" && -n "$codex_provider" ]]; then
    echo "${claude_provider},
            ${codex_provider}"
  elif [[ -n "$claude_provider" ]]; then
    echo "$claude_provider"
  else
    echo "$codex_provider"
  fi
}

case "$MODEL_CHOICE" in
  1) DEFAULT_MODEL="aigocode-claude/claude-opus-4-6" ;;
  2) DEFAULT_MODEL="openai-codex/gpt-5.3-codex" ;;
  3) DEFAULT_MODEL="aigocode-claude/claude-opus-4-6" ;;
esac

PROVIDERS=$(build_providers)

# Build Telegram config
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

# Write config
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

chmod 600 "$OPENCLAW_HOME/openclaw.json"
echo -e "${GREEN}✅ 配置已写入: $OPENCLAW_HOME/openclaw.json${NC}"

# Copy workspace templates (only if run from starter-kit directory)
TEMPLATE_COUNT=0
if [[ -f "SOUL.md" ]]; then
  for f in SOUL.md IDENTITY.md USER.md AGENTS.md HEARTBEAT.md MEMORY.md TOOLS.md; do
    if [[ -f "$f" && ! -f "$OPENCLAW_HOME/workspace/$f" ]]; then
      cp "$f" "$OPENCLAW_HOME/workspace/"
      TEMPLATE_COUNT=$((TEMPLATE_COUNT + 1))
    fi
  done
  [[ -d "docs" && ! -d "$OPENCLAW_HOME/workspace/docs" ]] && cp -r docs "$OPENCLAW_HOME/workspace/"
  [[ $TEMPLATE_COUNT -gt 0 ]] && echo -e "${GREEN}✅ 复制了 $TEMPLATE_COUNT 个模板文件${NC}"
fi

# ===== API 连通性测试 =====
echo ""
echo -e "${DIM}测试 API 连接...${NC}"

PROXY_OPT=""
[[ -n "$PROXY" ]] && PROXY_OPT="--proxy $PROXY"

if command -v curl &> /dev/null; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $PROXY_OPT --max-time 10 \
    -H "x-api-key: $API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-opus-4-6","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' \
    "https://api.aigocode.com/v1/messages" 2>/dev/null || echo "000")

  if [[ "$HTTP_CODE" == "200" ]]; then
    echo -e "${GREEN}✅ API 连接正常${NC}"
  elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
    echo -e "${YELLOW}⚠️  API Key 可能无效（HTTP $HTTP_CODE），请检查${NC}"
  elif [[ "$HTTP_CODE" == "000" ]]; then
    echo -e "${YELLOW}⚠️  无法连接 API（网络问题），启动后可能需要代理${NC}"
  else
    echo -e "${YELLOW}⚠️  API 返回 HTTP $HTTP_CODE，启动后注意检查${NC}"
  fi
else
  echo -e "${DIM}跳过（未安装 curl）${NC}"
fi

# ===== 完成 =====
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🎉 全部搞定！${NC}"
echo ""
echo -e "   📁 配置文件  ${CYAN}$OPENCLAW_HOME/openclaw.json${NC}"
echo -e "   📂 工作目录  ${CYAN}$OPENCLAW_HOME/workspace/${NC}"
echo -e "   🤖 默认模型  ${CYAN}$DEFAULT_MODEL${NC}"
echo -e "   🌐 端口      ${CYAN}$PORT${NC}"
[[ -n "$TG_TOKEN" ]] && echo -e "   💬 Telegram  ${GREEN}已配置${NC}"
[[ -n "$PROXY" ]]    && echo -e "   🔗 代理      ${GREEN}$PROXY${NC}"
echo ""
echo -e "${BOLD}▶ 启动你的 AI 助手：${NC}"
echo ""
echo -e "   ${CYAN}openclaw gateway${NC}"
echo ""
if [[ -n "$TG_TOKEN" ]]; then
  echo -e "   启动后去 Telegram 找你的 Bot 说句话 👋"
  echo -e "   首次需要配对：Bot 会发一个确认链接，点一下就好"
else
  echo -e "   启动后访问 ${CYAN}http://localhost:$PORT${NC} 打开 Web 界面"
fi
echo ""
echo -e "${BOLD}▶ 后台运行（推荐）：${NC}"
echo ""
echo -e "   ${CYAN}openclaw gateway start${NC}    # 后台启动"
echo -e "   ${CYAN}openclaw gateway stop${NC}     # 停止"
echo -e "   ${CYAN}openclaw gateway restart${NC}  # 重启"
echo -e "   ${CYAN}openclaw status${NC}           # 查看状态"
echo ""
echo -e "${CYAN}遇到问题？${NC}"
echo -e "   ${CYAN}openclaw doctor${NC}           # 自动诊断"
echo -e "   文档  https://docs.openclaw.ai"
echo -e "   社区  https://t.me/claw101"
echo -e "   客服  https://aigocode.com"
echo ""
