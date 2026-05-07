#!/bin/bash
# 日次レポート: 毎日18時（平日のみ）にSlack/Gmail/Googleカレンダーをまとめて通知

export PATH="/opt/node22/bin:$PATH"

# 平日チェック（cron側でも制御するが念のため）
DOW=$(date '+%u')  # 1=月曜 〜 7=日曜
if [ "$DOW" -ge 6 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 土日のためスキップ" >> /home/user/-/daily_report.log
  exit 0
fi

SLACK_MCP="mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a"
GMAIL_MCP="mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457"
GCAL_MCP="mcp__4abecda0-f819-4c96-8704-7e8adce94aab"

ALLOWED_TOOLS="${SLACK_MCP}__slack_search_public_and_private,\
${SLACK_MCP}__slack_read_channel,\
${SLACK_MCP}__slack_read_thread,\
${SLACK_MCP}__slack_send_message,\
${SLACK_MCP}__slack_search_users,\
${GMAIL_MCP}__search_threads,\
${GMAIL_MCP}__get_thread,\
${GMAIL_MCP}__list_labels,\
${GCAL_MCP}__list_calendars,\
${GCAL_MCP}__list_events,\
${GCAL_MCP}__get_event"

claude -p "
あなたは日次レポートアシスタントです。本日 $(date '+%Y/%m/%d') 18:00 時点の活動を集約して、seiya-otomo (user_id: U01SC3UBKMX) 本人のSlack DMに日次レポートを送信してください。

## 取得手順

### 1. Googleカレンダー（本日のスケジュール）
- 本日のカレンダーイベントを取得する（list_calendars → list_events で本日分）
- 時刻・タイトル・参加者を記録する

### 2. Slackの自分の投稿
- 検索クエリ: 'from:seiya-otomo after:$(date -d 'yesterday' '+%Y-%m-%d')' で本日分の自分の発言を検索
- チャンネル名・時刻・メッセージ概要を記録する

### 3. Gmailの返信（受信した返信）
- search_threads で 'in:inbox after:$(date '+%Y/%m/%d')' を検索
- 本日受信したスレッドの差出人・件名・概要を記録する

### 4. 時系列に並べてSlack DMで送信
上記1〜3のデータを時系列（古い順）で整理し、seiya-otomo (U01SC3UBKMX) へSlack DMを送信する。

## 送信するDMのフォーマット

【日次レポート】$(date '+%Y/%m/%d') 18:00

📅 *本日のスケジュール*
HH:MM イベント名（参加者）
…（時刻順）

💬 *Slackの自分の投稿*
HH:MM #チャンネル名: メッセージ概要
…（時刻順、最大10件）

📧 *Gmailの受信返信*
HH:MM 差出人: 件名
…（時刻順、最大10件）

---
以上が本日の活動サマリーです。

## 注意事項
- 各セクションで該当がない場合は「なし」と表示
- 必ずSlack DMを送信してから終了すること
- メッセージが長くなりすぎる場合は要約して簡潔にまとめること
" \
  --allowedTools "$ALLOWED_TOOLS" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
