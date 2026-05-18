#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列にまとめてDM通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。本日 ${TODAY} の活動サマリーを作成し、seiya-otomo (Slack user_id: U01SC3UBKMX) 本人へDMで送信してください。

## 手順

### 1. Googleカレンダーのスケジュール取得
- 本日 ${TODAY_ISO} のカレンダーイベントを全て取得する
- 開始時刻・終了時刻・タイトル・場所（あれば）を記録する

### 2. Slackの自分の投稿取得
- seiya-otomo (U01SC3UBKMX) が本日送信したメッセージを検索する
  - 検索クエリ例: 'from:seiya-otomo after:${TODAY_ISO}'
- チャンネル名・時刻・メッセージ概要を記録する

### 3. Gmailの返信取得
- 本日受信した返信メール（自分が送ったメールへの返信、または自分が返信したメール）を検索する
  - 検索クエリ例: 'after:${TODAY_ISO} (in:sent OR (label:inbox is:read))'
- 件名・相手・時刻・概要を記録する

### 4. 時系列レポートの作成・送信
上記1〜3を **時刻順** に並べて、以下の形式でseiya-otomo本人へSlack DMを送信する:

---
【📋 日次レポート】${TODAY}

📅 *スケジュール*
HH:MM〜HH:MM  イベント名
HH:MM〜HH:MM  イベント名
（なければ「予定なし」）

💬 *Slack投稿*
HH:MM  [#チャンネル名] メッセージ概要
（なければ「投稿なし」）

📧 *メール返信*
HH:MM  件名 (相手)
（なければ「返信なし」）

⏱ 合計アクティビティ: N件
---

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars,mcp__Google-Calendar__get_event,mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Gmail__list_labels" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
