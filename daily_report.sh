#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列で集約し、Slack DMに通知
# スケジュール: 毎日 18:00（平日のみ） → crontab: 0 18 * * 1-5 /home/user/-/daily_report.sh
# JST環境の場合: 0 18 * * 1-5 TZ=Asia/Tokyo /home/user/-/daily_report.sh

export PATH="/opt/node22/bin:$PATH"
export TZ="Asia/Tokyo"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
YESTERDAY_ISO=$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d')

claude -p "
あなたは日次業務レポート作成アシスタントです。本日 ${TODAY} の活動を以下の手順で収集し、時系列でまとめてください。

## 収集手順

### 1. Googleカレンダー: 本日のスケジュール取得
- 本日（${TODAY_ISO}T00:00:00+09:00 〜 ${TODAY_ISO}T23:59:59+09:00）の全イベントを取得する
- 時刻・イベント名・参加者・場所を記録する

### 2. Slack: 自分の本日の投稿を取得
- ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
- 検索クエリ: 'from:seiya-otomo after:${YESTERDAY_ISO}' でチャンネル投稿を検索
- DM送信も含め、投稿時刻・チャンネル・内容を記録する
- スレッド返信も取得する

### 3. Gmail: 本日の返信・受信メールを取得
- 検索クエリ: 'after:${TODAY_ISO} (in:sent OR label:inbox)' で本日のメールを取得
- 送信メールと重要な受信メールを時刻順に記録する
- 件名・相手・送受信時刻を記録する

## レポート送信
上記を時系列に並べ、以下の形式でSeiya-otomo本人（user_id: U01SC3UBKMX）にSlack DMで送信してください：

---
【日次レポート】${TODAY} 18:00

📅 本日のスケジュール（Googleカレンダー）
HH:MM イベント名 [参加者/場所があれば]
（例）09:00 週次MTG [田中, 鈴木]
（イベントがない場合は「予定なし」）

💬 本日のSlack投稿
HH:MM [#チャンネル名 or DM] 投稿内容の要約（30文字以内）
（投稿がない場合は「投稿なし」）

📧 本日のGmail
HH:MM [送/受] 件名 (相手)
（メールがない場合は「メールなし」）

---
合計: スケジュールN件 / Slack投稿N件 / メールN件
---

必ず最後にSlack DMを seiya-otomo(U01SC3UBKMX) に送信すること。
" \
  --allowedTools "mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__get_event,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__list_labels" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
