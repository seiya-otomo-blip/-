#!/bin/bash
# 日次レポート: 毎日18:00（平日のみ）に実行
# Slack投稿・Gmail返信・Googleカレンダーを時系列にまとめてSlack DMへ通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。以下の手順をすべて実行してください。

---
## ステップ1: Googleカレンダーの本日スケジュール取得

- 本日($TODAY_ISO)の全カレンダーイベントを取得する
- 開始時刻・終了時刻・タイトル・場所（あれば）を記録する

---
## ステップ2: Gmailの本日の受信・返信取得

- 本日($TODAY_ISO)に受信または送信したメールスレッドを検索する
  - 検索クエリ例: 'after:$TODAY_ISO before:$(date -d '+1 day' '+%Y-%m-%d')'
- 各スレッドの件名・相手・時刻・概要を取得する
- 自分が返信したもの、受信したもの両方を含める

---
## ステップ3: Slackの本日の自分の投稿取得

- seiya-otomo (user_id: U01SC3UBKMX) が本日($TODAY)送信したメッセージを検索する
  - 検索クエリ: 'from:@seiya-otomo after:$TODAY_ISO'
- チャンネル名・時刻・メッセージ概要を記録する

---
## ステップ4: 時系列レポートを作成してSlack DMに送信

上記1〜3のデータを時刻順に並べ替え、以下のフォーマットでseiya-otomo本人(U01SC3UBKMX)へSlack DMを送信する:

【日次レポート】$TODAY 18:00

📅 本日のまとめ

━━━━━━━━━━━━━━
🗓 カレンダー（今日の予定）
━━━━━━━━━━━━━━
[時刻] イベント名
...（なければ「予定なし」）

━━━━━━━━━━━━━━
📬 Gmail（受信・返信）
━━━━━━━━━━━━━━
[時刻] 件名 — 相手名
...（なければ「メールなし」）

━━━━━━━━━━━━━━
💬 Slack（自分の投稿）
━━━━━━━━━━━━━━
[時刻] #チャンネル名: メッセージ概要
...（なければ「投稿なし」）

━━━━━━━━━━━━━━
📊 サマリー
━━━━━━━━━━━━━━
・予定: N件
・Gmail: N件
・Slack投稿: N件

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
