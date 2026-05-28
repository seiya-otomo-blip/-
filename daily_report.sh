#!/bin/bash
# 日次レポート: Slack投稿 / Gmail返信 / Googleカレンダー を時系列でまとめ、Slack DMで通知
# 平日 18:00 に実行する想定

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="$(dirname "$0")/daily_report.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "日次レポート開始: ${TODAY}"

MAX_RETRIES=3
RETRY_DELAY=30
SUCCESS=false

for i in $(seq 1 $MAX_RETRIES); do
    log "実行試行 ${i}/${MAX_RETRIES}"

    claude -p "
あなたは日次レポートアシスタントです。本日 ${TODAY} の活動を以下の手順で収集し、Slack DMで送信してください。

## 収集手順

### 1. Googleカレンダー: 本日のスケジュール
- 本日（${TODAY_ISO}T00:00:00+09:00 〜 ${TODAY_ISO}T23:59:59+09:00）の全イベントを取得する
- list_calendars でカレンダー一覧を取得後、主要カレンダーのイベントを list_events で取得する
- 各イベントの開始時刻・タイトル・場所/会議URLを記録する

### 2. Slack: 本日の自分の投稿（seiya-otomo, user_id: U01SC3UBKMX）
- 検索クエリ: 'from:seiya-otomo after:${TODAY_ISO}' で本日投稿したメッセージを取得する
- チャンネル名・投稿時刻（JST）・メッセージ本文の概要を記録する

### 3. Gmail: 本日受信した返信メール
- 検索クエリ: 'in:inbox newer_than:1d' で本日受信したメールを取得する
- 送信者・件名・受信時刻を記録する

## レポート送信

収集した全イベントを **時系列（古い順）** に並べ、seiya-otomo本人（user_id: U01SC3UBKMX）へSlack DMで以下の形式で送信する:

【日次レポート】${TODAY} 18:00

⏰ タイムライン
HH:MM 📅 [カレンダー] イベントタイトル（場所/URL）
HH:MM 💬 [Slack #チャンネル名] メッセージ概要
HH:MM 📧 [Gmail] 送信者: 件名
...
（時刻不明のものは末尾にまとめる）

📅 カレンダー: N件 / 💬 Slack投稿: N件 / 📧 Gmail返信受信: N件

各種別で情報が取得できなかった場合は「0件」と記載する。
必ず最後にSlack DMを送信すること。
" \
      --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
      --output-format text \
      2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "成功"
        SUCCESS=true
        break
    fi

    if [ $i -lt $MAX_RETRIES ]; then
        log "${RETRY_DELAY}秒後にリトライします..."
        sleep $RETRY_DELAY
        RETRY_DELAY=$((RETRY_DELAY * 2))
    fi
done

if [ "$SUCCESS" = false ]; then
    log "全試行失敗。ログを確認してください: ${LOG_FILE}"
fi

log "日次レポート終了"
