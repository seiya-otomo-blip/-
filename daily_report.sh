#!/bin/bash
# 平日18:00に実行する日次レポートスクリプト
# 今日のSlack投稿・Gメール返信・Googleカレンダーを時系列でまとめ、Slack DMで通知する
#
# 【事前準備】
#   ローカルで `claude mcp list` を実行してGmail・Google CalendarのMCP UUIDを確認し、
#   以下の GMAIL_MCP_UUID / GCAL_MCP_UUID を置き換えてください。
#   例: mcp__xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx__gmail_search_threads
#
#   Slack UUID (設定済み): e59ce691-91d7-47bc-a81b-1f5cc340e15a
#   Gmail UUID:            <claude mcp listで確認 → GMAIL_MCP_UUID を置換>
#   Google Calendar UUID:  <claude mcp listで確認 → GCAL_MCP_UUID を置換>
#
# 【cron設定例 (Mac/Linux)】
#   crontab -e で以下を追加（平日18:00）:
#   0 18 * * 1-5 /path/to/daily_report.sh >> /path/to/daily_report.log 2>&1
#
# 【Mac launchd の場合】 daily_report.plist を ~/Library/LaunchAgents/ に配置

export PATH="/opt/node22/bin:$PATH"

# 平日チェック（土=6, 日=0 はスキップ）
DOW=$(date '+%u')  # 1=Mon ... 7=Sun
if [ "$DOW" -ge 6 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M')] 週末のためスキップ"
  exit 0
fi

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

# MCP UUIDs (ローカルの claude mcp list で確認して置き換える)
SLACK_UUID="e59ce691-91d7-47bc-a81b-1f5cc340e15a"
GMAIL_UUID="GMAIL_MCP_UUID"       # ← 要置換
GCAL_UUID="GCAL_MCP_UUID"         # ← 要置換

claude -p "
あなたは日次レポートアシスタントです。以下の手順を順番に実行してください。

## 対象日
本日: ${TODAY}

## ステップ1: Googleカレンダーの今日のスケジュール取得
- 本日 ${TODAY_ISO}T00:00:00 〜 ${TODAY_ISO}T23:59:59 の範囲でイベントを取得する
- startTimeで昇順に並べる

## ステップ2: Gmailの今日の受信メール取得
- クエリ: 'newer_than:1d -in:sent -in:draft' で今日受信したスレッドを最大20件取得
- 送信者・件名・受信時刻をリストアップ

## ステップ3: Slackの今日の自分の投稿取得
- ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
- 検索クエリ: 'from:@seiya-otomo after:${TODAY}' で自分の投稿を検索
- チャンネル名・投稿内容の概要・時刻をリストアップ

## ステップ4: 日次レポートを Slack DM で送信
上記3つの情報を時系列（時刻順）で統合し、seiya-otomo本人(U01SC3UBKMX)へ以下の形式でDM送信する:

---
【日次レポート】${TODAY} 18:00

📅 **本日のカレンダー**
(イベントがあれば時刻・タイトル・場所を列挙、なければ「予定なし」)

📧 **Gmailの受信メール** (N件)
(送信者・件名・時刻を列挙、なければ「受信なし」)

💬 **本日のSlack投稿** (N件)
(チャンネル・投稿概要・時刻を列挙、なければ「投稿なし」)
---

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "\
mcp__${SLACK_UUID}__slack_search_public_and_private,\
mcp__${SLACK_UUID}__slack_read_thread,\
mcp__${SLACK_UUID}__slack_read_channel,\
mcp__${SLACK_UUID}__slack_send_message,\
mcp__${SLACK_UUID}__slack_search_users,\
mcp__${GMAIL_UUID}__search_threads,\
mcp__${GMAIL_UUID}__get_thread,\
mcp__${GCAL_UUID}__list_events" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
