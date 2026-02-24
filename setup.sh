#!/usr/bin/env bash
# AiGoCode × OpenClaw 一键配置
# bash <(curl -sL https://raw.githubusercontent.com/sit-in/aigocode-openclaw-start/main/setup.sh)
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${CYAN}🦞 AiGoCode × OpenClaw 一键配置${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ===== 环境自动处理 =====
if ! command -v node &> /dev/null; then
  echo -e "${RED}❌ 请先安装 Node.js (v20+): ${CYAN}https://nodejs.org${NC}"
  exit 1
fi

if ! command -v openclaw &> /dev/null; then
  echo -e "正在安装 OpenClaw..."
  npm i -g openclaw@latest 2>&1 | tail -1
fi
echo -e "OpenClaw ${GREEN}$(openclaw --version 2>/dev/null || echo 'installed')${NC}"
echo ""

# ===== 已有配置检测 =====
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  echo -e "${YELLOW}⚠️  已有配置，将备份为 openclaw.json.bak${NC}"
  cp "$OPENCLAW_HOME/openclaw.json" "$OPENCLAW_HOME/openclaw.json.bak"
fi
mkdir -p "$OPENCLAW_HOME/workspace/memory" "$OPENCLAW_HOME/workspace/content"

# ===== 只问必要的 =====

# 1. API Key（唯一必填）
echo -e "去 ${CYAN}https://aigocode.com${NC} → 个人中心 → 复制 API Key"
echo ""
while true; do
  read -p "API Key: " API_KEY
  [[ -n "$API_KEY" ]] && break
  echo -e "${RED}不能为空${NC}"
done
echo ""

# 2. Telegram（可选）
read -p "Telegram Bot Token（没有直接回车跳过）: " TG_TOKEN
echo ""

# 3. 代理（自动检测常见端口，或手动填）
PROXY=""
if [[ -n "$TG_TOKEN" ]]; then
  # 有 Telegram 才需要代理（国内用户）
  for P in 7890 7897 1087 1080 8080; do
    if curl -s --proxy "http://127.0.0.1:$P" --max-time 2 -o /dev/null https://api.telegram.org 2>/dev/null; then
      PROXY="http://127.0.0.1:$P"
      echo -e "自动检测到代理: ${GREEN}$PROXY${NC}"
      break
    fi
  done
  if [[ -z "$PROXY" ]]; then
    read -p "代理地址（国内需要，回车跳过）: " PROXY
    [[ -n "$PROXY" && ! "$PROXY" =~ ^https?:// ]] && PROXY="http://$PROXY"
  fi
  echo ""
fi

# ===== 生成配置（全自动） =====
echo -e "生成配置..."

TG_SECTION=""
if [[ -n "$TG_TOKEN" ]]; then
  TG_PROXY=""
  [[ -n "$PROXY" ]] && TG_PROXY=",\"proxy\":\"$PROXY\""
  TG_SECTION=",\"channels\":{\"telegram\":{\"enabled\":true,\"dmPolicy\":\"pairing\",\"botToken\":\"$TG_TOKEN\",\"groupPolicy\":\"allowlist\",\"streamMode\":\"partial\"$TG_PROXY}},\"plugins\":{\"entries\":{\"telegram\":{\"enabled\":true}}}"
fi

cat > "$OPENCLAW_HOME/openclaw.json" << JSONEOF
{
    "models": {
        "default": "aigocode-claude/claude-opus-4-6",
        "providers": {
            "aigocode-claude": {
                "baseUrl": "https://api.aigocode.com",
                "apiKey": "$API_KEY",
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
            },
            "openai-codex": {
                "baseUrl": "https://api.aigocode.com/v1",
                "apiKey": "$API_KEY",
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
            }
        }
    },
    "agents": {
        "defaults": {
            "workspace": "$OPENCLAW_HOME/workspace",
            "compaction": { "mode": "safeguard" },
            "maxConcurrent": 4
        }
    },
    "gateway": {
        "port": 18789,
        "mode": "local",
        "bind": "loopback",
        "auth": { "mode": "open" }
    }
}
JSONEOF

# 注入 Telegram 配置（如果有）
if [[ -n "$TG_TOKEN" ]]; then
  # 用 node 做 JSON merge，比 sed 安全
  node -e "
    const fs = require('fs');
    const p = '$OPENCLAW_HOME/openclaw.json';
    const c = JSON.parse(fs.readFileSync(p, 'utf8'));
    c.channels = {telegram:{enabled:true,dmPolicy:'pairing',botToken:'$TG_TOKEN',groupPolicy:'allowlist',streamMode:'partial'$([ -n "$PROXY" ] && echo ",proxy:'$PROXY'")}};
    c.plugins = {entries:{telegram:{enabled:true}}};
    fs.writeFileSync(p, JSON.stringify(c, null, 4));
  " 2>/dev/null
fi

chmod 600 "$OPENCLAW_HOME/openclaw.json"

# 复制模板文件（从 starter-kit 目录运行时）
if [[ -f "SOUL.md" ]]; then
  for f in SOUL.md IDENTITY.md USER.md AGENTS.md HEARTBEAT.md MEMORY.md TOOLS.md; do
    [[ -f "$f" && ! -f "$OPENCLAW_HOME/workspace/$f" ]] && cp "$f" "$OPENCLAW_HOME/workspace/"
  done
fi

# ===== API 测试 =====
PROXY_OPT=""
[[ -n "$PROXY" ]] && PROXY_OPT="--proxy $PROXY"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $PROXY_OPT --max-time 10 \
  -H "x-api-key: $API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
  -d '{"model":"claude-opus-4-6","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' \
  "https://api.aigocode.com/v1/messages" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  echo -e "${GREEN}✅ API 连接正常${NC}"
elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
  echo -e "${YELLOW}⚠️  API Key 可能无效，请检查 aigocode.com 后台${NC}"
elif [[ "$HTTP_CODE" == "000" ]]; then
  echo -e "${YELLOW}⚠️  无法连接 API，可能需要代理${NC}"
else
  echo -e "${GREEN}✅ 配置完成${NC}"
fi

# ===== 完成 =====
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "🎉 ${GREEN}搞定！${NC}启动你的 AI 助手："
echo ""
echo -e "   ${CYAN}openclaw gateway${NC}"
echo ""
if [[ -n "$TG_TOKEN" ]]; then
  echo -e "   然后去 Telegram 跟你的 Bot 说句话 👋"
else
  echo -e "   然后打开 ${CYAN}http://localhost:18789${NC}"
fi
echo ""
echo -e "${DIM}文档 docs.openclaw.ai | 社区 t.me/claw101 | 客服 aigocode.com${NC}"
echo ""
