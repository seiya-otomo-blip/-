#!/bin/bash
# 平日18:00に実行: Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめてSlack DMに通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=月曜 ... 7=日曜

# 土日はスキップ
if [ "$WEEKDAY" -ge 6 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 土日のためスキップ" >> /home/user/-/daily_report.log
  exit 0
fi

SLACK_ID="mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a"
GMAIL_ID="mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457"
GCAL_ID="mcp__4abecda0-f819-4c96-8704-7e8adce94aab"

claude -p "
あなたは日次レポート作成アシスタントです。今日 ${TODAY} の活動をまとめてSlack DMで通知してください。

## 手順

### 1. Googleカレンダーから本日のスケジュール取得
- list_events ツールで今日 ${TODAY_ISO} の予定を全て取得する
- timeMin: '${TODAY_ISO}T00:00:00+09:00', timeMax: '${TODAY_ISO}T23:59:59+09:00'

### 2. Slackで自分の投稿を取得
- slack_search_public_and_private で 'from:@seiya-otomo after:${TODAY_ISO}' を検索
- 自分(U01SC3UBKMX)が今日投稿したメッセージを収集する

### 3. Gmailで本日受信した返信を取得
- search_threads で 'in:inbox after:${TODAY_ISO}' を検索
- 今日受信したメール（自分宛の返信、重要なスレッド）を取得する
- 各スレッドの件名・送信者・概要を把握する

### 4. 時系列レポートを作成してSlack DM送信
上記で取得した情報を時刻順に並べ、seiya-otomo(U01SC3UBKMX)へDMで以下の形式で送信する:

---
【日次レポート】${TODAY} 18:00

📅 本日のカレンダー
  HH:MM 予定名（所要時間）
  ...（時系列順）

💬 本日のSlack投稿
  HH:MM [チャンネル名] メッセージ概要
  ...（時系列順）

📧 本日の受信メール
  HH:MM 件名（送信者）
  ...（時系列順）

---

※ 各セクションで該当なしの場合は「なし」と記載すること
※ 必ずSlack DMを送信すること（seiya-otomo / U01SC3UBKMX 宛）
" \
  --allowedTools "${GCAL_ID}__list_events,${GCAL_ID}__list_calendars,${GCAL_ID}__get_event,${SLACK_ID}__slack_search_public_and_private,${SLACK_ID}__slack_read_thread,${SLACK_ID}__slack_read_channel,${SLACK_ID}__slack_send_message,${SLACK_ID}__slack_search_users,${GMAIL_ID}__search_threads,${GMAIL_ID}__get_thread" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
