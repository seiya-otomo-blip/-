#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列まとめてDM通知
# 毎日18:00（平日のみ）にcronで実行する

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。以下の手順をすべて実行してください。

## 収集対象
本日（${TODAY}）の情報を時系列でまとめます。

---

### 1. Googleカレンダー: 本日のスケジュール取得
- list_events で本日（${TODAY_ISO}）のイベントを取得する
- 開始時刻・終了時刻・タイトル・場所（あれば）を収集する

### 2. Slack: 本日の自分の投稿を取得
- slack_search_public_and_private で 'from:@seiya-otomo after:${TODAY_ISO}' を検索
- 自分が送信したメッセージ・スレッド返信を取得する
- チャンネル名、時刻、メッセージ概要を収集する

### 3. Gmail: 本日の自分の返信を取得
- search_threads で 'from:me after:${TODAY_ISO}' を検索
- 自分が送信した返信メール（スレッド内で自分が返信したもの）を取得する
- 件名、宛先、送信時刻を収集する

---

### 4. 時系列レポートをまとめてSlack DMで送信
上記1〜3のデータを時刻順に並べ、seiya-otomo本人（user_id: U01SC3UBKMX）へSlack DMで以下の形式で送信すること:

【日次レポート】${TODAY} 18:00

📅 本日のスケジュール
  HH:MM〜HH:MM タイトル（場所）
  ※予定がない場合は「予定なし」と記載

💬 本日のSlack投稿
  HH:MM [#チャンネル名] メッセージ概要
  ※投稿がない場合は「投稿なし」と記載

📧 本日のGmail返信
  HH:MM 件名 → 宛先
  ※返信がない場合は「返信なし」と記載

---
以上の形式でSlack DMを必ず送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_channel,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
