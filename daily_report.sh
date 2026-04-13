#!/bin/bash
# 日次レポート: 毎日18:00（平日のみ）実行
# Slack投稿・Gmail返信・Googleカレンダースケジュールを時系列で取得し、Slack DMで通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
TOMORROW_ISO=$(date -d '+1 day' '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。以下の手順をすべて実行し、最後に seiya-otomo (U01SC3UBKMX) へSlack DMで日次レポートを送信してください。

## 手順

### 1. Googleカレンダーのスケジュール取得
- 本日 $TODAY_ISO のカレンダーイベント一覧を取得する (gcal_list_events)
- 各イベントの開始時刻・件名・参加者・場所を記録する

### 2. Slackの自分の投稿取得
- seiya-otomo (U01SC3UBKMX) が本日送信したメッセージを検索する
- 検索クエリ例: 'from:@seiya-otomo after:$TODAY_ISO before:$TOMORROW_ISO'
- 各メッセージのチャンネル名・時刻・内容概要を記録する

### 3. Gmailの返信・送受信メール取得
- 本日送受信したメールを検索する (gmail_search_messages)
- 検索クエリ: 'after:$TODAY_ISO before:$TOMORROW_ISO'
- 件名・送受信者・時刻・概要を記録する

### 4. 時系列でまとめてSlack DM送信
上記1〜3で取得したデータを時刻順に並べ、以下の形式で seiya-otomo (U01SC3UBKMX) へ Slack DM を送信する:

【日次レポート】$TODAY 18:00

📅 *本日のスケジュール*
HH:MM [イベント名] 参加者・場所など
（なければ「予定なし」）

💬 *Slack投稿*
HH:MM [#チャンネル名] メッセージ概要
（なければ「投稿なし」）

📧 *メール*
HH:MM [件名] 送信者 → 受信者
（なければ「メールなし」）

---
以上が本日 $TODAY の活動サマリーです。

必ずSlack DMを seiya-otomo (U01SC3UBKMX) へ送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__gmail_search_messages,mcp__Gmail__gmail_read_thread,mcp__Gmail__gmail_read_message,mcp__Google-Calendar__gcal_list_events,mcp__Google-Calendar__gcal_get_event,mcp__Google-Calendar__gcal_list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
