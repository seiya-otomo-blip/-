#!/bin/bash
# 日次レポート: 毎日18時（平日のみ）にSlack/Gmail/Googleカレンダーを集計してDM通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y-%m-%d')
TODAY_JP=$(date '+%Y/%m/%d')

claude -p "
あなたは日次レポートアシスタントです。本日 ${TODAY_JP} 18:00 の日次レポートを作成し、seiya-otomo(U01SC3UBKMX)へSlack DMで送信してください。

## 収集手順

### 1. Googleカレンダー：本日のスケジュール取得
- 本日(${TODAY}T00:00:00 〜 ${TODAY}T23:59:59)の全イベントを取得する
- イベントを開始時刻順に整理する

### 2. Slack：本日の自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY} before:${TODAY}' で本日の自分の投稿を取得する
- channel_types は 'public_channel,private_channel,mpim,im' を対象とする
- 投稿時刻・チャンネル名・メッセージ概要を取得する

### 3. Gmail：本日受信した返信メールを取得
- 検索クエリ: 'after:${TODAY} (in:inbox OR is:sent)' で本日のメールを取得する（最大30件）
- 返信スレッドを中心に、送受信したメールを取得する
- 件名・送受信者・時刻を取得する

## レポート形式

以下の形式でSlack DMメッセージを作成し、seiya-otomo(U01SC3UBKMX)へ送信すること:

---
*【日次レポート】${TODAY_JP} 18:00*

*📅 本日のスケジュール*
(時系列順。イベントがない場合は「予定なし」と記載)
• HH:MM - HH:MM　イベント名

*💬 本日のSlack投稿*
(時系列順。投稿がない場合は「投稿なし」と記載)
• HH:MM　[チャンネル名]　メッセージ概要（20文字程度）

*📧 本日のGmail返信*
(時系列順。メールがない場合は「メールなし」と記載)
• HH:MM　件名（送信者 or 宛先）

*📊 本日のサマリー*
• スケジュール: N件
• Slack投稿: N件
• Gmail返信: N件
---

必ず最後にSlack DMを seiya-otomo (U01SC3UBKMX) へ送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_channels,mcp__Slack__slack_read_channel,mcp__Gmail__gmail_search_messages,mcp__Gmail__gmail_read_message,mcp__Gmail__gmail_read_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
