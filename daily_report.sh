#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列で集計し、Slack DMで通知する
# 実行: 毎日18:00（平日のみ）cron で起動

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。本日 ${TODAY} の活動サマリーを作成し、seiya-otomo本人へSlack DMで送信してください。

【ユーザー情報】
- Slack user_id: U01SC3UBKMX
- 名前: seiya-otomo

【手順】

## Step 1: Slackの自分の投稿を取得
- 検索クエリ: 'from:@seiya-otomo after:${TODAY_ISO}' で本日の自分の投稿を取得
- 各メッセージの時刻・チャンネル・内容を記録する

## Step 2: Gmailの返信（受信メール）を取得
- 本日受信した重要なメールを検索する
- 検索クエリ: 'in:inbox after:${TODAY_ISO}' で本日受信したメールを取得
- 送信者・件名・時刻を記録する（スレッドの詳細が必要な場合はget_threadで確認）

## Step 3: Googleカレンダーのスケジュールを取得
- 本日 ${TODAY_ISO} のカレンダーイベントをすべて取得する
- イベント名・開始時刻・終了時刻・参加者を記録する

## Step 4: 時系列レポートを作成してSlack DMで送信
以下のフォーマットでseiya-otomo (U01SC3UBKMX) にSlack DMを送信する:

---
📊 *日次レポート ${TODAY}*

🗓 *本日のスケジュール*
(時系列順でカレンダーイベントを列挙)
例:
• 09:00-10:00 朝会 (参加者: ...)
• 14:00-15:00 ミーティング

💬 *Slackの自分の投稿*
(時系列順で投稿を列挙)
例:
• 10:05 #general: メッセージ概要
• 14:30 #dev: メッセージ概要

📧 *Gmailの受信*
(時系列順で重要なメールを列挙)
例:
• 09:15 件名: ... (送信者: ...)
• 13:00 件名: ... (送信者: ...)

✅ *本日の活動サマリー*
(全体を1〜2文で要約)
---

データが取得できないセクションは「データなし」と記載する。
必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
