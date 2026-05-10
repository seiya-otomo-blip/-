#!/bin/bash
# 日次レポート: 毎日18:00（平日のみ）にSlack/Gmail/Googleカレンダーを集計してDMで通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="/home/user/-/daily_report.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "日次レポート開始"

MAX_RETRIES=3
RETRY_DELAY=30

run_with_retry() {
  local attempt=1
  local delay=$RETRY_DELAY

  while [ $attempt -le $MAX_RETRIES ]; do
    log "実行試行 $attempt/$MAX_RETRIES"

    claude -p "
あなたは日次活動レポートアシスタントです。本日（${TODAY}）の活動を以下の手順で集計し、Slack DMで報告してください。

## ステップ1: Googleカレンダーの予定を取得
- 本日 ${TODAY_ISO}T00:00:00 〜 ${TODAY_ISO}T23:59:59 の全予定を取得する
- 各予定の開始時刻・終了時刻・タイトル・説明を記録する

## ステップ2: Slackの自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO} before:${TODAY_ISO}' で本日の投稿を検索
- チャンネル名・投稿時刻・メッセージ概要を記録する
- スレッドへの返信も含める

## ステップ3: Gmailの送受信を取得
- 本日送信したメール: クエリ 'in:sent after:${TODAY_ISO} before:${TODAY_ISO}'
- 本日受信した返信（未読含む）: クエリ 'after:${TODAY_ISO} before:${TODAY_ISO} -in:sent'
- 各メールの時刻・件名・送受信相手を記録する

## ステップ4: 時系列でまとめてSlack DMに送信
以下のフォーマットで seiya-otomo（U01SC3UBKMX）へSlack DMを送信すること:

【日次レポート】${TODAY}

📅 カレンダー
HH:MM [予定タイトル]（所要時間）
...（時系列順）

💬 Slack投稿
HH:MM [#チャンネル名] メッセージ概要
...（時系列順）

📧 Gmail
HH:MM [送信/受信] 件名（相手）
...（時系列順）

---
以上、本日の活動サマリーでした。

※ データが取得できなかった項目は「データなし」と記載すること。
※ 必ず最後にSlack DMを送信すること。
" \
      --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events" \
      --output-format text \
      2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
      log "日次レポート送信成功"
      return 0
    fi

    log "失敗。${delay}秒後にリトライします..."
    sleep $delay
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done

  log "全試行失敗。ログを確認: $LOG_FILE"
  return 1
}

run_with_retry
log "日次レポート終了"
