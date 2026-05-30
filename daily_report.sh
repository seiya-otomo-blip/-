#!/bin/bash
# 毎日18:00（平日のみ）に実行する日次レポートスクリプト
# Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめ、自分のSlack DMに送信する

export PATH="/opt/node22/bin:$PATH"

LOG_FILE="/home/user/-/daily_report.log"
TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "日次レポート生成開始: $TODAY"

claude -p "
あなたは日次レポート作成アシスタントです。本日（${TODAY}）の活動をまとめて、seiya-otomo本人（Slack user_id: U01SC3UBKMX）のDMに日次レポートを送信してください。

## 手順

### 1. Slackの自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}' で本日の自分の投稿を取得
- パブリック・プライベートチャンネル両方を対象にする
- 各投稿のチャンネル名、時刻、メッセージ概要を記録する

### 2. Gmailの返信を取得
- 本日（${TODAY_ISO}以降）に受信した返信メールを検索する
  - クエリ例: 'after:${TODAY_ISO} in:inbox'
- 送信者、件名、時刻、概要を記録する

### 3. Googleカレンダーのスケジュールを取得
- 本日 ${TODAY_ISO}T00:00:00 から ${TODAY_ISO}T23:59:59 のイベントを取得
- タイムゾーン: Asia/Tokyo
- イベント名、開始時刻、終了時刻、参加者を記録する

### 4. 時系列でまとめてSlack DMで送信
取得したすべての情報を時刻順に並べて、以下のフォーマットでseiya-otomo本人（U01SC3UBKMX）にSlack DMを送信する。

---
📊 *日次レポート* ${TODAY}

🗓 *本日のスケジュール*
• HH:MM〜HH:MM イベント名（参加者）
• ...（時刻順）

💬 *Slackの自分の投稿*
• HH:MM [#チャンネル名] メッセージ概要
• ...（時刻順）

📧 *Gmailの受信返信*
• HH:MM 件名（from: 送信者）
• ...（時刻順）

⏱ 以上、本日の活動まとめでした。
---

注意:
- データが取得できなかったカテゴリは「（本日の活動なし）」と記載する
- 必ず最後にSlack DMを送信すること（U01SC3UBKMX宛）
- 時刻はすべてJST（Asia/Tokyo）で表示する
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel" \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    log "日次レポート送信完了"
else
    log "エラー: 日次レポート送信失敗 (exit code: $EXIT_CODE)"
fi

log "日次レポート生成終了"
