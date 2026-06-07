#!/bin/bash
# 日次レポート: Slack投稿 / Gmailの返信 / Googleカレンダー を時系列で集約して Slack DM に通知
# スケジュール: 毎日 18:00（平日のみ）GitHub Actions により実行

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="$(dirname "$0")/daily_report.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート開始" | tee -a "$LOG_FILE"

claude -p "
あなたは日次レポートアシスタントです。以下の手順を順番に実行してください。

今日の日付: ${TODAY}

---
## STEP 1: Googleカレンダーのスケジュール取得

mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events を使い、
今日（${TODAY_ISO}T00:00:00 〜 ${TODAY_ISO}T23:59:59）のイベントを全て取得してください。
タイムゾーン: Asia/Tokyo

---
## STEP 2: Slackの自分の投稿を取得

mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private を使い、
自分（U01SC3UBKMX）が今日（${TODAY_ISO}）に投稿したメッセージを全チャンネルから取得してください。
検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}'
sort: timestamp, sort_dir: asc

---
## STEP 3: Gmailの返信メールを取得

mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads を使い、
今日（newer_than:1d）に送受信した返信スレッドを取得してください。
検索クエリ: 'newer_than:1d'

---
## STEP 4: 時系列で整理してレポートを作成

STEP 1〜3 で取得したデータを時刻の古い順に整理し、以下のフォーマットで Slack DM（U01SC3UBKMX）に送信してください。

---
📊 *日次レポート* ${TODAY}

*📅 Googleカレンダー*
（イベントがある場合）
• HH:MM 〜 HH:MM　イベント名
...
（イベントがない場合）
本日の予定はありません

*💬 Slack投稿*
（投稿がある場合）
• HH:MM　[#チャンネル名] 投稿内容の要約（30字以内）
...
（投稿がない場合）
本日のSlack投稿はありません

*📧 Gmail返信*
（メールがある場合）
• HH:MM　件名（送信者→受信者）
...
（メールがない場合）
本日のGmail返信はありません
---

必ずこのフォーマットで U01SC3UBKMX へ Slack DM を送信すること。
" \
  --allowedTools "mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads" \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート終了 (exit: $EXIT_CODE)" | tee -a "$LOG_FILE"
exit $EXIT_CODE
