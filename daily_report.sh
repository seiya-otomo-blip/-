#!/bin/bash
# 平日18時に実行する日次レポートスクリプト
# Googleカレンダー・Gmail・Slackの活動を時系列でまとめてSlack DMに送信

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。以下の手順を順番に実行してください。

今日の日付: ${TODAY}
対象ユーザー: seiya-otomo (Slack user_id: U01SC3UBKMX)

## ステップ1: データ収集

以下の3つのソースから今日のデータを収集してください。

### A. Googleカレンダー
- 今日（${TODAY_ISO}）のカレンダーイベントを全て取得する
- list_calendars で利用可能なカレンダーIDを確認してから list_events を実行
- パラメータ: timeMin=${TODAY_ISO}T00:00:00+09:00, timeMax=${TODAY_ISO}T23:59:59+09:00
- 取得項目: イベント名、開始時刻、終了時刻

### B. Gmail
- 今日受信したメール返信を取得する
- search_threads で検索クエリ: 'after:${TODAY_ISO} in:inbox'
- 各スレッドの get_thread で最新メッセージを確認
- 取得項目: 送信者、件名、受信時刻

### C. Slack
- 今日の自分（seiya-otomo）の投稿を取得する
- slack_search_public_and_private で検索クエリ: 'from:seiya-otomo after:${TODAY_ISO}'
- 取得項目: チャンネル名、投稿内容の概要、時刻

## ステップ2: 日次レポートをSlack DMで送信

収集したデータを時系列（古い順）で整理し、seiya-otomo (U01SC3UBKMX) へSlack DMで以下の形式で送信する:

【日次レポート】${TODAY} 18:00

📅 Googleカレンダー（本日のスケジュール）
（取得したイベントを HH:MM 形式の時刻順に列挙。なければ「予定なし」）

📧 Gmail（本日の受信返信）
（取得したメール返信を時刻順に列挙。なければ「受信返信なし」）

💬 Slack（本日の自分の投稿）
（取得した投稿を時刻順に列挙。なければ「投稿なし」）

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__get_event,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
