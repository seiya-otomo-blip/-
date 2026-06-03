#!/bin/bash
# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列集計し、Slack DMで通知
# スケジュール: 平日 18:00 JST

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG_FILE="$(dirname "$0")/daily_report.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "日次レポート開始: ${TODAY}"

claude -p "
あなたは日次レポート作成アシスタントです。以下の手順を順番に実行してください。

## 対象ユーザー
- Slack user_id: U01SC3UBKMX (seiya-otomo)
- メールアドレス: seiya-otomo@plex.co.jp

## 本日の日付: ${TODAY}

## 手順

### ステップ1: Slack の自分の投稿を取得
- 検索クエリ: 'from:U01SC3UBKMX after:${TODAY_ISO}' で本日のSlack投稿を検索
- 各投稿のチャンネル名、送信時刻、メッセージ概要を収集する
- スレッドへの返信も含めて収集する

### ステップ2: Gmail の送信済み返信を取得
- 検索クエリ: 'from:me after:${TODAY_ISO}' で本日送信したメールを検索
- 各メールの件名、宛先、送信時刻を収集する
- 受信したメールへの返信のみをリストアップする（新規送信は除外）

### ステップ3: Google カレンダーのスケジュールを取得
- 本日 ${TODAY_ISO} のカレンダーイベントを全て取得する
- イベント名、開始時刻〜終了時刻、参加者（5名以上の場合は省略可）を収集する

### ステップ4: 時系列でまとめて Slack DM を送信
ステップ1〜3のデータを時刻順に並べ、seiya-otomo(U01SC3UBKMX)へ Slack DM で送信する。
DM の内容は以下のフォーマットに従うこと:

---
【日次レポート】${TODAY} 18:00

📅 本日のスケジュール・活動サマリー
━━━━━━━━━━━━━━━━━━━━━━

⏰ 時系列アクティビティ

HH:MM 📆 [カレンダー] イベント名（参加者数名）
HH:MM 💬 [Slack: #チャンネル名] メッセージ概要
HH:MM 📧 [Gmail] 件名 → 宛先

（時刻順に全て列挙、データがない時間帯はスキップ）

━━━━━━━━━━━━━━━━━━━━━━
📊 本日のサマリー
📆 カレンダー: N件
💬 Slack投稿: N件
📧 Gmail返信: N件
---

データが取得できない項目は「データなし」と記載すること。
必ず最後に Slack DM を送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_calendars,mcp__Google-Calendar__list_events" \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
log "日次レポート終了: exit=${EXIT_CODE}"
exit $EXIT_CODE
