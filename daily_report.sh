#!/bin/bash
# 平日18:00に実行する日次レポート通知スクリプト
# Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめてDM送信

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。本日（${TODAY}）の活動を以下の手順でまとめ、Slack DMで報告してください。

## 手順

### 1. Slackの自分の投稿を取得
- ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
- 検索クエリ: 'from:@seiya-otomo after:${TODAY_ISO}' で本日の自分の投稿を検索
- チャンネル投稿・DM・スレッド返信を含める
- 各投稿のチャンネル名、時刻、メッセージ概要を記録

### 2. Gmailの返信（受信メール）を取得
- 本日（${TODAY_ISO}）受信したメールを検索: 'after:${TODAY_ISO} in:inbox'
- 送信者、件名、受信時刻を記録
- 重要度の高いもの（返信が必要そうなもの）を特定

### 3. Googleカレンダーのスケジュールを取得
- 本日のカレンダーイベントを取得（timeMin: ${TODAY_ISO}T00:00:00+09:00, timeMax: ${TODAY_ISO}T23:59:59+09:00）
- イベント名、開始・終了時刻、参加者を記録

### 4. 時系列でまとめてSlack DMに送信
seiya-otomo (U01SC3UBKMX) へ以下の形式でDM送信:

---
【日次レポート】${TODAY} 18:00

📅 本日のスケジュール
HH:MM [イベント名]（所要時間）
...（カレンダーイベントを時系列で）

💬 Slackの自分の投稿
HH:MM [#チャンネル名] メッセージ概要
...（本日の投稿を時系列で）

📧 受信メール
HH:MM [送信者] 件名
...（本日の受信メールを時系列で）

⚠️ 要対応
- 返信が必要なメールや未返信のSlackメッセージがあれば列挙

活動なし の場合は「本日の活動はありませんでした」と記載。
---

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_read_channel,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
