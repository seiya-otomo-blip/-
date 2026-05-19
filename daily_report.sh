#!/bin/bash
# 平日18:00に実行する日次レポート: Slack投稿・Gmail返信・Googleカレンダーを集約してDM通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
TODAY_START="${TODAY_ISO}T00:00:00+09:00"
TODAY_END="${TODAY_ISO}T23:59:59+09:00"
YESTERDAY_ISO=$(date -d 'yesterday' '+%Y-%m-%d')

# MCP設定ファイルのパス（GitHub Actions: /tmp/mcp-config.json、ローカル: 省略可）
MCP_CONFIG_OPT=""
if [ -f "/tmp/mcp-config.json" ]; then
  MCP_CONFIG_OPT="--mcp-config /tmp/mcp-config.json"
fi

claude -p "
あなたは日次レポートアシスタントです。本日（${TODAY}）の活動を以下の手順で収集し、seiya-otomo（U01SC3UBKMX）本人へSlack DMで送信してください。

## 収集手順

### 1. Slackの自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${YESTERDAY_ISO}' でチャンネル投稿を取得
- 件数・チャンネル名・メッセージ概要を時系列で記録する

### 2. Gmailの返信（受信）を取得
- 検索クエリ: 'newer_than:1d' で本日受信したメールを取得（最大20件）
- 送信者・件名・受信時刻を時系列で記録する

### 3. Googleカレンダーのスケジュールを取得
- 本日（${TODAY_START} 〜 ${TODAY_END}）のイベントをすべて取得
- イベント名・開始・終了時刻を時系列で記録する

## レポート形式
収集した情報を時系列に並べ、以下の形式で seiya-otomo（U01SC3UBKMX）へSlack DMを送信する:

---
【📊 日次レポート】${TODAY}

⏰ **本日のスケジュール**（Googleカレンダー）
（イベントがあれば時刻順に列挙。なければ「予定なし」）

💬 **Slack投稿**（本日）
（投稿があれば チャンネル名・概要・時刻を列挙。なければ「投稿なし」）

📧 **Gmail受信**（本日）
（メールがあれば 送信者・件名・時刻を列挙。なければ「受信なし」）

---
以上3つのセクションをすべて埋めてからSlack DMを送信すること。
情報が取得できなかった項目は「取得なし」と記載すること。
" \
  $MCP_CONFIG_OPT \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
