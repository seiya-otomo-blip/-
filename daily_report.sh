#!/bin/bash
# 平日18:00に実行する日次活動レポートスクリプト
# Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめ、自分のSlack DMに送信する

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=月曜, 7=日曜

# 平日チェック（月〜金のみ実行）
if [ "$WEEKDAY" -ge 6 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 土日のためスキップ" | tee -a /home/user/-/daily_report.log
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート生成開始" | tee -a /home/user/-/daily_report.log

claude -p "
あなたは日次活動レポートアシスタントです。本日（${TODAY}）の活動を以下の手順で集約し、seiya-otomoのSlack DMに送信してください。

## 収集対象

### 1. Slack投稿（自分の投稿）
- seiya-otomo (user_id: U01SC3UBKMX) が本日送信したメッセージを検索
- 検索クエリ例: 'from:@seiya-otomo after:${TODAY_ISO}'
- 各メッセージのチャンネル名・時刻・内容概要を取得

### 2. Gmailの返信
- 本日受信した返信メールを検索（in:inbox after:${TODAY_ISO}）
- 送信者・件名・時刻を取得
- 重要度の高いもの（要返信のもの）を識別

### 3. Googleカレンダーのスケジュール
- 本日のカレンダーイベントを一覧取得
- 各イベントの時刻・タイトル・参加者を取得

## レポート作成ルール
- 上記3つの情報を時系列（時刻順）でまとめる
- 各項目の時刻が不明な場合はその旨を記載
- 重要な対応漏れや未返信メールがあれば冒頭で警告

## Slack DM送信内容
以下の形式でseiya-otomo本人（U01SC3UBKMX）にSlack DMを送信すること:

---
📊 *日次レポート - ${TODAY}*

🗓 *本日のスケジュール*
HH:MM [イベント名]（参加者）
HH:MM [イベント名]（参加者）
（イベントなしの場合: スケジュールなし）

💬 *Slack投稿（本日の自分の発言）*
HH:MM [#チャンネル名] メッセージ概要
（投稿なしの場合: 投稿なし）

📧 *Gmailの返信（本日受信）*
HH:MM [送信者] 件名
⚠️ 要返信: 件名（ある場合のみ）
（メールなしの場合: 受信なし）

---
※ 時系列順に並べること。情報が取得できない場合はその旨を明記すること。
必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__list_labels,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__get_event" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート生成完了" | tee -a /home/user/-/daily_report.log
