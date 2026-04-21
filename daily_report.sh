#!/bin/bash
# 日次レポート: 毎日18時（平日のみ）に実行
# Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめてSlack DMに通知
# crontab: 0 18 * * 1-5 /home/user/-/daily_report.sh

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。以下の手順で本日（${TODAY}）の活動サマリーを作成し、seiya-otomo本人(U01SC3UBKMX)へSlack DMで通知してください。

## 取得するデータ

### 1. Slackの自分の投稿（本日分）
- seiya-otomo (user_id: U01SC3UBKMX) が本日投稿したメッセージを検索
- 検索クエリ: 'from:seiya-otomo after:${TODAY_ISO}'
- チャンネル・DM問わず取得し、チャンネル名・投稿時刻・メッセージ概要（30文字以内）を記録

### 2. Gmailの返信・受信（本日分）
- 本日のメールスレッドを2パターンで検索:
  a) 送信メール: クエリ 'in:sent after:${TODAY_ISO}'
  b) 受信メール: クエリ 'in:inbox after:${TODAY_ISO}'
- 各スレッドの件名・送受信者・時刻を記録

### 3. Googleカレンダーのスケジュール（本日分）
- 本日 ${TODAY_ISO}T00:00:00 〜 ${TODAY_ISO}T23:59:59 のイベントを取得
- 開始時刻・終了時刻・イベント名・参加者を記録

## レポート送信形式

上記3つのデータを **時系列順（早い順）** に並べて、以下の形式でSlack DM（U01SC3UBKMX）に送信してください:

【日次レポート】${TODAY} 18:00

📅 本日のタイムライン
━━━━━━━━━━━━━━━━━━━━━━

※ 時系列で並べる（例）:
HH:MM 📅 [カレンダー] イベント名（参加者名）
HH:MM 📨 [Gmail受信] 件名 from 送信者名
HH:MM 💬 [Slack] #チャンネル名 メッセージ概要
HH:MM 📤 [Gmail送信] 件名 → 宛先名

データが0件の場合は「（なし）」と表示してください。

━━━━━━━━━━━━━━━━━━━━━━
📊 本日のサマリー
• 予定: N件
• Gmail受信: N件 / 送信: N件
• Slack投稿: N件

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
