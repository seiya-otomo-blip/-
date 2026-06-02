#!/bin/bash
# 毎日18:00（平日のみ）に実行し、Slack/Gmail/Googleカレンダーの活動をまとめて
# seiya-otomo本人のSlack DMへ日次レポートを送信するスクリプト

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポート作成アシスタントです。本日 ${TODAY} の活動を収集し、時系列にまとめてSlack DMに送信してください。

## 実行手順

### 1. Googleカレンダーのスケジュールを取得
- 今日 ${TODAY_ISO} のカレンダーイベントを全て取得する
- timeMin: ${TODAY_ISO}T00:00:00+09:00
- timeMax: ${TODAY_ISO}T23:59:59+09:00
- 各イベントの開始時刻・終了時刻・タイトル・参加者を記録する

### 2. Slackの自分の投稿を取得
- ユーザーID: U01SC3UBKMX (seiya-otomo)
- 今日の自分の投稿を検索する
- 検索クエリ: 'from:@seiya-otomo after:${TODAY_ISO}'
- 各投稿のチャンネル名・時刻・内容の要約を記録する

### 3. Gmailの返信・送受信メールを取得
- 今日受信したメールを検索: 'after:${TODAY_ISO} in:inbox'
- 今日送信したメールを検索: 'after:${TODAY_ISO} in:sent'
- 各メールの時刻・件名・送信者/宛先を記録する

### 4. 日次レポートを作成してSlack DMに送信
上記を全て時刻順に並べ替えて、以下のフォーマットで seiya-otomo (user_id: U01SC3UBKMX) へ Slack DM を送信してください。

---
【日次レポート】${TODAY}

📅 *カレンダー*
HH:MM〜HH:MM イベント名（参加者: 名前, ...）
※ イベントがない場合は「予定なし」と記載

💬 *Slack投稿*
HH:MM [#チャンネル名] 投稿内容の要約（30文字以内）
※ 投稿がない場合は「投稿なし」と記載

📧 *Gmail*
HH:MM 受信: 件名 （from: 送信者）
HH:MM 送信: 件名 （to: 宛先）
※ メールがない場合は「メールなし」と記載

━━━━━━━━━━━━━━
本日もお疲れ様でした 🎉
---

注意:
- 必ず最後に Slack DM を user_id U01SC3UBKMX へ送信すること
- データが取得できなかった項目は「取得できませんでした」と記載すること
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
