#!/bin/bash
# 毎日18時（平日のみ）実行: Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめてSlack DMに通知
# cron設定例: 0 18 * * 1-5 /home/user/-/daily_report.sh

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="/home/user/-/daily_report.log"

claude -p "
あなたはデイリーレポートアシスタントです。以下の手順を実行し、seiya-otomo本人(user_id: U01SC3UBKMX)へSlack DMでレポートを送信してください。

【本日の日付】${TODAY}

## 手順

### 1. Googleカレンダーのスケジュール取得
- 本日 ${TODAY_ISO} のカレンダーイベントを全て取得する
- list_calendars で利用可能なカレンダーを確認してからlist_eventsを実行すること
- 開始時刻・終了時刻・イベント名・場所（あれば）を記録

### 2. Slackの自分の投稿を取得
- seiya-otomo (user_id: U01SC3UBKMX) が本日 ${TODAY_ISO} に投稿したメッセージを検索
- 検索クエリ例: 'from:seiya-otomo after:${TODAY_ISO}'
- チャンネル名・投稿時刻・メッセージ概要を記録

### 3. Gmailの返信・受信メールを取得
- 本日 ${TODAY_ISO} に受信したメールスレッドを検索
- 検索クエリ例: 'after:${TODAY_ISO} is:inbox' または 'after:${TODAY_ISO} in:inbox'
- 件名・送信者・受信時刻を記録（最大10件）

### 4. Slack DMで本人へ送信
取得した情報を**時系列順**（古い順）に並べて、以下の形式でseiya-otomo(U01SC3UBKMX)へDM送信すること:

【デイリーレポート】${TODAY} 18:00

📅 本日のカレンダー
（イベントがあれば「HH:MM イベント名」の形式で列挙、なければ「予定なし」）

💬 Slackの投稿
（投稿があれば「HH:MM [#チャンネル名] メッセージ概要」の形式で列挙、なければ「投稿なし」）

📧 Gmailの返信・受信
（メールがあれば「HH:MM 件名 / 送信者」の形式で列挙、なければ「受信なし」）

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Slack__slack_read_thread,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"
