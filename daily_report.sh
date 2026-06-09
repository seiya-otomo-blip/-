#!/bin/bash
# 平日18時の日次レポートをSlack DMで送信するスクリプト

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=月曜 ... 5=金曜

# 平日のみ実行（GitHub Actions のスケジュールでも念のため確認）
if [ "$WEEKDAY" -gt 5 ]; then
  echo "本日は週末のためスキップします。"
  exit 0
fi

LOG_FILE="/home/user/-/daily_report.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート開始" | tee -a "$LOG_FILE"

claude -p "
今日（${TODAY}）の日次レポートを作成して、自分のSlack DM（user_id: U01SC3UBKMX）に送信してください。

【手順】

1. **Googleカレンダーのスケジュール取得**
   - 今日（${TODAY_ISO}T00:00:00〜${TODAY_ISO}T23:59:59）のイベントをすべて取得
   - 時間順に並べる

2. **Slackの自分の投稿を取得**
   - 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}'
   - 今日自分が投稿したメッセージを時系列で収集（返信・チャンネル投稿含む）

3. **Gmailの返信を取得**
   - 今日受信したメール（自分宛ての返信や重要メール）を時系列で取得
   - 検索クエリ: 'to:me newer_than:1d'
   - 件名・送信者・受信時刻を収集

4. **日次レポートを作成**
   上記のデータをすべて時系列で整理して、以下のフォーマットでSlack DM（U01SC3UBKMX）に送信：

   ━━━━━━━━━━━━━━━━━━━━━━
   📋 *日次レポート ${TODAY}*
   ━━━━━━━━━━━━━━━━━━━━━━

   📅 *本日のスケジュール*
   • HH:MM〜HH:MM　イベント名
   （なければ「予定なし」）

   💬 *Slackの自分の投稿*
   • HH:MM　[チャンネル名] 投稿内容の要約
   （なければ「投稿なし」）

   📧 *Gmailの返信*
   • HH:MM　件名（送信者）
   （なければ「メールなし」）

   ━━━━━━━━━━━━━━━━━━━━━━

   必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars" \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート終了（exit: $EXIT_CODE）" | tee -a "$LOG_FILE"
exit $EXIT_CODE
