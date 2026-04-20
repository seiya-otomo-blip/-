#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列で集約し、Slack DMに送信
# 実行: 毎日 18:00（平日のみ） cron: 0 18 * * 1-5

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポート作成アシスタントです。本日 ${TODAY} の活動を以下の手順で集約し、seiya-otomo (U01SC3UBKMX) のSlack DMに送信してください。

## ステップ1: データ収集

### 1-1. Slackの自分の投稿を取得
- 検索クエリ: 'from:me after:${TODAY_ISO}' で本日の自分の投稿を検索
- 各投稿のチャンネル名・時刻・内容の概要を記録

### 1-2. GmailのメールのReplyを取得
- search_threads で 'after:${TODAY_ISO} is:inbox' を検索
- 自分宛の返信メールを取得（件名、送信者、時刻を記録）
- 重要そうなスレッドは get_thread で詳細確認

### 1-3. Googleカレンダーのスケジュールを取得
- list_events で本日 ${TODAY_ISO}T00:00:00+09:00 から ${TODAY_ISO}T23:59:59+09:00 の予定を取得
- 予定名・時刻・場所（あれば）を記録

## ステップ2: 時系列レポート作成・DM送信

収集したデータを時刻順に並べ、以下の形式でDMを送信:

【日次レポート】${TODAY} 18:00

📅 本日のスケジュール・活動サマリー

━━━━ Googleカレンダー ━━━━
[時刻] 予定名（例: 10:00 チームMTG）
※予定がない場合は「予定なし」

━━━━ Slack投稿 ━━━━
[時刻] #チャンネル名: 投稿内容の概要
※投稿がない場合は「投稿なし」

━━━━ Gmail返信 ━━━━
[時刻] 件名: 送信者からの返信概要
※メールがない場合は「受信なし」

━━━━ 時系列サマリー ━━━━
全イベントを時刻順に1行ずつ列挙:
HH:MM [種別] 内容

必ずSlack DMを seiya-otomo (U01SC3UBKMX) に送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__list_labels,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
