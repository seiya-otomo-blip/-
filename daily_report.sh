#!/bin/bash
# 日次レポート: 自分のSlack投稿・Gmailの返信・Googleカレンダーを時系列で取得し、Slack DMに送信

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="$(dirname "$0")/daily_report.log"

# 平日のみ実行 (1=月, 2=火, 3=水, 4=木, 5=金)
DOW=$(date '+%u')
if [ "$DOW" -ge 6 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 週末のためスキップ" | tee -a "$LOG_FILE"
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート開始" | tee -a "$LOG_FILE"

claude -p "
あなたは日次レポート作成アシスタントです。以下の手順を順番に実行してください。

【対象ユーザー】seiya-otomo (Slack user_id: U01SC3UBKMX, メール: seiya-otomo@plex.co.jp)

---

## 手順1: Googleカレンダーのスケジュール取得
本日 ${TODAY_ISO} のカレンダーイベントを取得する。
timeMin: ${TODAY_ISO}T00:00:00+09:00, timeMax: ${TODAY_ISO}T23:59:59+09:00 の範囲で list_events を実行する。

## 手順2: Slackの自分の投稿取得
本日 ${TODAY_ISO} に seiya-otomo が送信したSlackメッセージを取得する。
- 検索クエリ1: 'from:seiya-otomo after:${TODAY_ISO}'
- 取得したメッセージから、チャンネル名・時刻・内容を一覧化する

## 手順3: Gmailの返信メール取得
本日 ${TODAY_ISO} に受信したメールスレッドを検索する。
- 検索クエリ: 'after:${TODAY_ISO} is:inbox'
- 件名・送信者・時刻を一覧化する（最大10件）

## 手順4: 日次レポートを日本語で作成
手順1〜3の情報を時系列（古い順）でまとめる。
以下のフォーマットを使用:

【日次レポート】${TODAY}

📅 本日のスケジュール
{カレンダーの予定一覧。なければ「予定なし」}

💬 Slack投稿
{自分のSlack投稿一覧（チャンネル・時刻・内容）。なければ「投稿なし」}

📧 受信メール
{受信メール一覧（件名・送信者・時刻）。なければ「なし」}

## 手順5: Slack DMで送信
作成したレポートを seiya-otomo 本人（user_id: U01SC3UBKMX）のSlack DMに送信する。

**必ず最後にSlack DMを送信すること。**
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート終了" | tee -a "$LOG_FILE"
