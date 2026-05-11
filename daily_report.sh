#!/bin/bash
# 日次レポートを毎日18時（平日のみ）に実行し、自分のSlack DMに通知するスクリプト
# cron: 0 18 * * 1-5 /home/user/-/daily_report.sh

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポート作成アシスタントです。本日 ${TODAY} の活動を以下の手順で収集し、時系列にまとめてSlack DMで通知してください。

## ステップ1: Slackの自分の投稿を取得
- ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
- 検索クエリ: 'from:@seiya-otomo after:${TODAY_ISO}' で本日の投稿を検索
- 取得する情報: チャンネル名、投稿時刻、メッセージ内容（先頭100文字）

## ステップ2: Gmailの返信（受信メール）を取得
- 本日受信したメールを検索: after:${TODAY_ISO}
- 取得する情報: 送信者、受信時刻、件名
- 上限: 最大10件

## ステップ3: Googleカレンダーの本日のスケジュールを取得
- 本日 ${TODAY_ISO} のイベントを取得
- 取得する情報: イベント名、開始時刻、終了時刻、場所（あれば）

## ステップ4: 時系列レポートをまとめてSlack DMに送信
以下のフォーマットで seiya-otomo本人(U01SC3UBKMX) へSlack DMを送信すること:

---
【日次レポート】${TODAY} 18:00

📅 本日のカレンダー
[カレンダーイベントを時系列で列挙。なければ「予定なし」]

💬 Slackの投稿
[本日の自分の投稿を時系列で列挙。なければ「投稿なし」]

📧 受信メール
[本日受信したメールを時系列で列挙。なければ「受信なし」]
---

必ず最後にSlack DMを送信すること。すべてのステップを順に実行してください。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_calendars,mcp__Google-Calendar__list_events" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
