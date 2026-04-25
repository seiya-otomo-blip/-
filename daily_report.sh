#!/bin/bash
# 平日18:00に実行する日次レポートスクリプト
# Slack投稿・Gメール返信・Googleカレンダーを時系列で集約し、自分のDMに通知する

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。seiya-otomo (user_id: U01SC3UBKMX) の本日の活動を集約し、Slack DMで報告してください。

## 実行手順

### 1. Slackの自分の投稿を取得
- 検索クエリ: 'from:seiya-otomo after:${TODAY_ISO}' でチャンネル投稿を検索
- 各メッセージのチャンネル名・時刻・内容の概要を記録する

### 2. GmailのSent/返信メールを取得
- 本日送信したメール: 'from:me after:${TODAY_ISO}' で検索（上限10件）
- 本日受信した返信メール: 'to:me after:${TODAY_ISO}' で検索（上限10件）
- 件名・送受信先・時刻を記録する

### 3. Googleカレンダーの今日のスケジュールを取得
- 本日 ${TODAY} のイベント一覧を取得する（全カレンダー対象）
- イベント名・開始時刻・終了時刻・場所/URLを記録する

### 4. 時系列に並べて日次レポートを作成
上記1〜3のデータを時刻順に並べ、以下のフォーマットで seiya-otomo (U01SC3UBKMX) のSlack DMに送信する:

---
【日次レポート】${TODAY} 18:00

📅 本日のスケジュール
  HH:MM - HH:MM イベント名（場所/URL）
  ...（時刻順）

💬 Slackの投稿 (N件)
  HH:MM [#チャンネル名] メッセージ概要
  ...（時刻順）

📧 メールの送受信 (N件)
  HH:MM [送信/受信] 件名 (相手)
  ...（時刻順）

---

何もない項目は「なし」と記載する。
必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_read_channel,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_calendars,mcp__Google-Calendar__list_events,mcp__Google-Calendar__get_event" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
