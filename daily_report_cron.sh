#!/bin/bash
# cronから実行するラッパー（環境変数を設定してから本体を呼ぶ）

export PATH="/opt/node22/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="/root"

# MCP設定の確認（最新のmcp-configファイルを使用）
MCP_CONFIG=$(ls -t /tmp/mcp-config-*.json 2>/dev/null | head -1)
if [ -z "$MCP_CONFIG" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') エラー: MCP設定ファイルが見つかりません" >> /home/user/-/daily_report.log
  exit 1
fi

exec /home/user/-/daily_report.sh
