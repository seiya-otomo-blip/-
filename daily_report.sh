#!/bin/bash
# 日次レポート: 毎日18:00（平日のみ）
# Slack投稿・Gmail・Googleカレンダーを時系列でまとめてSlack DM通知

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=月 ... 7=日
LOG_FILE="$(dirname "$0")/daily_report.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ "$WEEKDAY" -ge 6 ]; then
    log "土日のためスキップします"
    exit 0
fi

log "日次レポート開始 (${TODAY})"

MAX_RETRIES=3
RETRY_DELAY=30
SUCCESS=false

for i in $(seq 1 $MAX_RETRIES); do
    log "実行試行 ${i}/${MAX_RETRIES}"

    claude -p "
あなたは日次レポートアシスタントです。
本日 ${TODAY} の seiya-otomo (user_id: U01SC3UBKMX) の活動を収集し、Slack DM でレポートしてください。

## ステップ1: Slackの自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}' で本日の投稿を収集
- チャンネル投稿・DM・スレッド返信をすべて含める
- 時刻順に並べる

## ステップ2: Gmail の本日のメールを取得
- 受信メール: クエリ 'in:inbox after:${TODAY_ISO} newer_than:1d' で取得（最大20件）
- 送信メール: クエリ 'in:sent after:${TODAY_ISO} newer_than:1d' で取得（最大10件）

## ステップ3: Googleカレンダーの本日の予定を取得
- startTime: ${TODAY_ISO}T00:00:00+09:00
- endTime: ${TODAY_ISO}T23:59:59+09:00
- timeZone: Asia/Tokyo
- orderBy: startTime

## ステップ4: 以下のフォーマットで seiya-otomo (U01SC3UBKMX) へ Slack DM を送信

---
【日次レポート】${TODAY} 18:00

📅 *本日のスケジュール*
HH:MM〜HH:MM　イベント名
（予定がなければ「予定なし」）

📨 *Gmail*
[受信] HH:MM　件名　← from: 送信者名
[送信] HH:MM　件名　→ to: 宛先名
（メールがなければ「受送信なし」）

💬 *Slack 投稿*
HH:MM　[#チャンネル名 or DM]　メッセージ内容（先頭60文字）
（投稿がなければ「投稿なし」）

📊 *本日のサマリー*
• スケジュール: X 件
• Gmail 受信: X 件 / 送信: X 件
• Slack 投稿: X 件
---

必ず最後に Slack DM を送信すること。
情報が取得できなかった項目は「取得できませんでした」と記載すること。
" \
      --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
      --output-format text \
      2>&1 | tee -a "$LOG_FILE"

    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
        log "成功"
        SUCCESS=true
        break
    fi

    if [ "$i" -lt "$MAX_RETRIES" ]; then
        log "${RETRY_DELAY}秒後にリトライします..."
        sleep "$RETRY_DELAY"
        RETRY_DELAY=$((RETRY_DELAY * 2))
    fi
done

if [ "$SUCCESS" = false ]; then
    log "全試行失敗。ログを確認してください: $LOG_FILE"
    exit 1
fi

log "日次レポート終了"
