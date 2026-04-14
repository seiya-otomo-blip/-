#!/bin/bash
# 日次レポートを毎日18時（平日のみ）に実行するスクリプト
# 内容: Slackの自分の投稿 / Gmailの返信 / Googleカレンダーのスケジュールを時系列で取得し、
#       seiya-otomo本人のSlack DMに通知する

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
YESTERDAY_ISO=$(date -d 'yesterday' '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。本日 ${TODAY} の活動を以下の手順でまとめてください。

## Step 1: Slackの自分の投稿を取得
- ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
- 検索クエリ: 'from:@seiya-otomo after:${YESTERDAY_ISO}' で本日分の投稿を取得
- チャンネル投稿・スレッド返信を含める
- 各投稿の時刻・チャンネル・内容を記録する

## Step 2: Gmailの返信メールを取得
- 本日 ${TODAY_ISO} に受信または送信したメールを検索
- 検索クエリ例: 'after:${YESTERDAY_ISO}' で本日のメールを取得
- 件名・送受信時刻・相手・概要を記録する（最大10件）

## Step 3: Googleカレンダーのスケジュールを取得
- 本日 ${TODAY_ISO} のカレンダーイベントをすべて取得する
- イベント名・開始時刻・終了時刻・参加者を記録する

## Step 4: 時系列で整理してSlack DMに送信
上記Step 1〜3の情報を時刻順に並べ、以下の形式で seiya-otomo本人(U01SC3UBKMX) へSlack DMを送信すること。

---
【日次レポート】${TODAY} 18:00

📅 本日のスケジュール・活動まとめ

━━━━━━━━━━━━━━━━━━━━
[時系列で各イベント・投稿・メールを記載]
例:
09:00 [カレンダー] 朝会 (〜09:30) - 参加者: ...
09:45 [Gmail] 件名: ... → 返信 from ...
10:12 [Slack] #channel-name: 投稿内容の概要...
...
━━━━━━━━━━━━━━━━━━━━

📊 本日のサマリー
• Slack投稿: N件
• Gmail送受信: N件
• カレンダーイベント: N件
---

必ず最後にSlack DMを送信すること。情報が取得できなかった項目は「(データなし)」と記載すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_read_channel,mcp__Slack__slack_search_users,mcp__Slack__slack_send_message,mcp__Gmail__gmail_search_messages,mcp__Gmail__gmail_read_message,mcp__Gmail__gmail_read_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__get_event,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
