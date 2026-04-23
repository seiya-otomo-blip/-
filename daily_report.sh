#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列集約してDM通知
# cron: 0 18 * * 1-5  (平日18:00)

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
YESTERDAY_ISO=$(date -d 'yesterday' '+%Y-%m-%d')

claude -p "
あなたは日次レポート作成アシスタントです。本日 ${TODAY} の活動サマリーを作成し、seiya-otomo(U01SC3UBKMX)のSlack DMに送信してください。

## 手順

### 1. Googleカレンダーのスケジュール取得
- 本日 ${TODAY_ISO}T00:00:00 〜 ${TODAY_ISO}T23:59:59 の全イベントを取得する
- startTime: ${TODAY_ISO}T00:00:00、endTime: ${TODAY_ISO}T23:59:59、orderBy: startTime

### 2. Gmailの返信取得
- 本日受信したメールスレッドを検索する
- クエリ: 'after:${TODAY_ISO} is:inbox'
- 最大20件取得し、返信済み(自分が最後に送信)・未返信を区別して整理する

### 3. Slackの自分の投稿取得
- seiya-otomo(U01SC3UBKMX)が本日投稿したメッセージを検索する
- 検索クエリ: 'from:seiya-otomo after:${YESTERDAY_ISO}'
- 投稿内容とチャンネル名を取得する

### 4. 時系列レポートを作成してSlack DMに送信
以下のフォーマットでまとめ、U01SC3UBKMX宛にDMを送信すること:

【日次レポート】${TODAY} 18:00

📅 *本日のスケジュール*
<時刻順にイベント一覧。例: 10:00-11:00 週次MTG / 14:00-15:00 1on1>
（予定なしの場合は「予定なし」と記載）

📨 *Gmail受信サマリー*
・受信数: N件
・未返信: N件
<未返信スレッドがあれば件名と送信者を最大5件列挙>
（受信なしの場合は「受信なし」と記載）

💬 *Slack投稿サマリー*
・投稿数: N件
<チャンネル別に投稿数をまとめ、主な投稿内容を1行で記載>
（投稿なしの場合は「投稿なし」と記載）

---
必ず最後に mcp__Slack__slack_send_message でU01SC3UBKMX宛にDMを送信すること。
" \
  --allowedTools "mcp__Google-Calendar__list_events,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
