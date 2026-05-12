#!/bin/bash
# 日次レポート自動送信スクリプト
# スケジュール: 毎日18:00（平日のみ）
# cron設定例:
#   JST環境: 0 18 * * 1-5 /home/user/-/scripts/daily_report_cron.sh
#   UTC環境: 0  9 * * 1-5 /home/user/-/scripts/daily_report_cron.sh

set -euo pipefail

export PATH="/opt/node22/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WORKDIR="/home/user/-"
LOG_DIR="$WORKDIR/logs"
LOG_FILE="$LOG_DIR/daily_report.log"
MAX_LOG_LINES=1000

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ログローテーション（1000行超えたら古い半分を削除）
if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt "$MAX_LOG_LINES" ]; then
    tail -n $((MAX_LOG_LINES / 2)) "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

TODAY=$(date '+%Y-%m-%d')
TODAY_JP=$(date '+%Y年%m月%d日')

PROMPT="今日（${TODAY_JP}、JST）の日次レポートを作成してSlackのDMに送信してください。

## Step 1: データ取得（以下を並行して実行）

### 1a. Slackの自分の投稿
- 検索クエリ: \`from:<@U01SC3UBKMX> after:${TODAY}\`
- 取得する情報: 時刻、チャンネル名、メッセージ概要
- ソート: 時刻昇順

### 1b. Gmailの受信返信
- 検索クエリ: \`newer_than:1d in:inbox\`
- 取得する情報: 時刻、送信者名、件名
- ソート: 時刻昇順

### 1c. Googleカレンダーのスケジュール
- 期間: ${TODAY}T00:00:00+09:00 〜 ${TODAY}T23:59:59+09:00
- タイムゾーン: Asia/Tokyo
- 取得する情報: 開始時刻、イベント名、場所（あれば）
- ソート: 時刻昇順

## Step 2: Slack DMで送信
Slack DM（宛先チャンネルID: U01SC3UBKMX）に以下のフォーマットで送信してください:

📊 *日次レポート - ${TODAY_JP}*

📅 *本日のカレンダー*
• HH:MM [イベント名]（場所）
• ...（なければ「予定なし」）

💬 *Slackの自分の投稿*
• HH:MM [#チャンネル名] メッセージの概要
• ...（なければ「投稿なし」）

📧 *Gmailの受信返信*
• HH:MM [送信者名] 件名
• ...（なければ「受信なし」）

_生成時刻: $(date '+%H:%M') JST_

必ず最後にSlack DMを送信すること。"

ALLOWED_TOOLS="mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events"

MAX_RETRIES=3
RETRY_DELAY=30

log "日次レポート開始 (${TODAY})"

for i in $(seq 1 $MAX_RETRIES); do
    log "実行試行 ${i}/${MAX_RETRIES}"
    if claude -p "$PROMPT" \
        --allowedTools "$ALLOWED_TOOLS" \
        --output-format text \
        >> "$LOG_FILE" 2>&1; then
        log "日次レポート送信完了"
        exit 0
    fi

    if [ "$i" -lt "$MAX_RETRIES" ]; then
        log "${RETRY_DELAY}秒後にリトライします..."
        sleep "$RETRY_DELAY"
        RETRY_DELAY=$((RETRY_DELAY * 2))
    fi
done

log "全試行失敗。ログを確認してください: $LOG_FILE"
exit 1
