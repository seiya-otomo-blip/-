#!/bin/bash
# 日次レポート: 今日のSlack投稿・Gmail送信・Googleカレンダー予定を時系列で取得し Slack DM で通知
# cron: 0 9 * * 1-5 (UTC 9:00 = JST 18:00, 平日のみ)

export PATH="/opt/node22/bin:$PATH"
export TZ="Asia/Tokyo"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
LOG="/home/user/-/daily_report.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート開始" >> "$LOG"

claude -p "あなたは日次レポートアシスタントです。本日 ${TODAY} の活動サマリーを作成し、Slack DMで通知してください。

以下の手順を順番に実行してください：

## 1. Googleカレンダーの予定を取得
- startTime: ${TODAY_ISO}T00:00:00+09:00
- endTime: ${TODAY_ISO}T23:59:59+09:00
- timeZone: Asia/Tokyo
- 全イベントの「開始時刻・終了時刻・タイトル・場所・出席者」を記録する

## 2. Slackの自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}' で今日の自分の投稿を検索
- sort: timestamp（古い順）
- 各投稿の「時刻・チャンネル・メッセージ本文（先頭80文字）・リンク」を記録する

## 3. Gmailの送信メールを取得
- 検索クエリ: 'in:sent after:${TODAY_ISO//-//}' で今日送信したメールを取得
- 各メールの「送信時刻・件名・宛先」を記録する
- get_thread で詳細が必要な場合は取得する

## 4. 時系列で整理して Slack DM 送信
収集した情報をすべて時刻順に並べ、以下のフォーマットで seiya-otomo (U01SC3UBKMX) へ Slack DM を送信する：

---
【日次レポート】${TODAY}

📅 **タイムライン**
HH:MM-HH:MM 📆 [カレンダー] イベント名
HH:MM 💬 [Slack] #チャンネル名: メッセージ概要
HH:MM 📧 [Gmail] 件名 → 宛先名
（時系列順に全件列挙。時刻不明のものは最後にまとめる）

📊 **サマリー**
- 📆 カレンダー: N 件
- 💬 Slack 投稿: N 件
- 📧 Gmail 送信: N 件
---

各カテゴリが 0 件の場合も「0件」と明記する。
必ず最後に Slack DM を送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events" \
  --output-format text \
  2>&1 | tee -a "$LOG"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日次レポート終了 (exit: $?)" >> "$LOG"
