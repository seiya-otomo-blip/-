#!/bin/bash
# 日次レポートを平日18:00に実行し、seiya-otomo(U01SC3UBKMX)へSlack DMで通知するスクリプト
#
# ローカルcronで使う場合:
#   0 18 * * 1-5 /path/to/daily_report.sh
#
# MCP tool名について:
#   Slack:          mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__*  (既存設定から)
#   Gmail:          claude mcp list で確認したIDを GMAIL_MCP_ID に設定
#   Google Calendar: 同上を GCAL_MCP_ID に設定

export PATH="/opt/node22/bin:$PATH"

# ローカルMCPサーバーID設定
SLACK_MCP_ID="e59ce691-91d7-47bc-a81b-1f5cc340e15a"
# TODO: `claude mcp list` で確認して以下を書き換えてください
GMAIL_MCP_ID="${GMAIL_MCP_ID:-Gmail}"
GCAL_MCP_ID="${GCAL_MCP_ID:-Google-Calendar}"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="$(dirname "$0")/daily_report.log"

ALLOWED_TOOLS="\
mcp__${SLACK_MCP_ID}__slack_search_public_and_private,\
mcp__${SLACK_MCP_ID}__slack_read_channel,\
mcp__${SLACK_MCP_ID}__slack_read_thread,\
mcp__${SLACK_MCP_ID}__slack_send_message,\
mcp__${SLACK_MCP_ID}__slack_search_users,\
mcp__${GMAIL_MCP_ID}__search_threads,\
mcp__${GMAIL_MCP_ID}__get_thread,\
mcp__${GCAL_MCP_ID}__list_events,\
mcp__${GCAL_MCP_ID}__list_calendars"

claude -p "
あなたは日次レポートアシスタントです。以下の手順を順番に実行してください。

今日の日付: ${TODAY}
自分のSlack user_id: U01SC3UBKMX

## STEP 1: Slackの本日の自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}'
- 投稿チャンネル・内容の概要・タイムスタンプ（時刻）を記録する
- スレッド返信も含めて取得する

## STEP 2: Gmailの本日受信した返信メールを取得
- 検索クエリ: 'newer_than:1d in:inbox'
- 件名・送信者・受信時刻を記録する（本文は不要、件名と送信者のみ）

## STEP 3: Googleカレンダーの本日のスケジュールを取得
- 本日 ${TODAY_ISO}T00:00:00 〜 ${TODAY_ISO}T23:59:59 のイベントを取得
- イベント名・開始時刻・終了時刻・参加者を記録する

## STEP 4: 時系列で整理してSlack DMを送信
上記3つの情報を時刻順（早い順）に並べ、以下の形式でU01SC3UBKMXへSlack DMを送信してください:

---
【日次レポート】${TODAY}

📅 本日のスケジュール・活動サマリー
━━━━━━━━━━━━━━━━━━━━

[時刻] 絵文字 内容 (種別)
例:
09:00–10:00 📅 朝会 _(Google Calendar)_
10:15 💬 #general にメッセージ投稿: 「XXXについて...」 _(Slack)_
11:30 📧 田中さんから返信: 件名「Re: XXX」 _(Gmail)_
...

（データがない種別は「なし」と表記）

━━━━━━━━━━━━━━━━━━━━
📊 本日のサマリー
• 📅 予定: N件
• 💬 Slack投稿: N件
• 📧 受信メール返信: N件
---

必ず最後にSlack DM（channel_id: U01SC3UBKMX）を送信すること。
" \
  --allowedTools "${ALLOWED_TOOLS}" \
  --output-format text \
  2>&1 | tee -a "${LOG_FILE}"
