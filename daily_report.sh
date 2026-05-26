#!/bin/bash
# 日次活動レポート（平日 18:00 実行用）
# Slack投稿・Gmailメール・Googleカレンダーを時系列で集計してSlack DMで通知

export PATH="/opt/node22/bin:$PATH"

SLACK_MCP="e59ce691-91d7-47bc-a81b-1f5cc340e15a"
GMAIL_MCP="ec8b2c1c-d01c-4297-8a5e-afc11958c457"
GCAL_MCP="4abecda0-f819-4c96-8704-7e8adce94aab"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="$(dirname "$0")/daily_report.log"

claude -p "
あなたは日次活動レポートを作成するアシスタントです。今日(${TODAY})の活動を以下の手順で集計し、Slack DMで通知してください。

## 手順1: Googleカレンダーの本日のスケジュールを取得
- list_calendars でカレンダー一覧を取得
- list_events で今日(${TODAY_ISO}T00:00:00〜${TODAY_ISO}T23:59:59)のイベントを全て取得
- 各イベントの開始時刻・終了時刻・タイトルを記録

## 手順2: Gmailの本日の送受信メールを取得
- search_threads で今日のメールを検索（クエリ例: 'after:${TODAY_ISO}'）
- 件名・送信者・受信時刻を記録（最大10件）

## 手順3: 本日の自分のSlack投稿を取得
- seiya-otomo（user_id: U01SC3UBKMX）の本日の投稿を検索
- 検索クエリ: 'from:seiya-otomo after:${TODAY_ISO}'
- チャンネル名・メッセージ概要・投稿時刻を記録

## 手順4: 時系列でまとめてSlack DMを送信
取得したカレンダー・メール・Slack投稿を時系列（古い順）に整理し、seiya-otomo本人（U01SC3UBKMX）へSlack DMで以下の形式で送信:

【日次レポート】${TODAY} 18:00

🗓 *カレンダー*
(時刻順にイベント一覧。予定なしの場合は「なし」)

📧 *Gメール*
(時刻順に送受信メール一覧。なければ「なし」)

💬 *Slack投稿*
(時刻順に自分の投稿一覧。なければ「なし」)

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__${SLACK_MCP}__slack_search_public_and_private,mcp__${SLACK_MCP}__slack_read_thread,mcp__${SLACK_MCP}__slack_send_message,mcp__${SLACK_MCP}__slack_search_users,mcp__${SLACK_MCP}__slack_read_channel,mcp__${GMAIL_MCP}__search_threads,mcp__${GMAIL_MCP}__get_thread,mcp__${GCAL_MCP}__list_events,mcp__${GCAL_MCP}__list_calendars" \
  --output-format text \
  2>&1 | tee -a "${LOG_FILE}"
