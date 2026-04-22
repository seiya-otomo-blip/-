#!/bin/bash
# 日次レポート: 自分のSlack投稿・Gメール返信・Googleカレンダーを時系列で集計し、Slack DMで通知
# cron設定: 0 18 * * 1-5 /home/user/-/daily_report.sh

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
TODAY_GMAIL=$(date '+%Y/%m/%d')
TOMORROW_ISO=$(date -d tomorrow '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。今日 ${TODAY} の活動を3つのソースから収集し、時系列でまとめて seiya-otomo (U01SC3UBKMX) にSlack DMで送信してください。

## ステップ1: Googleカレンダーのスケジュール取得
- 今日 ${TODAY_ISO} のカレンダーイベントを全カレンダーから取得する
- 時刻・タイトル・場所やURLを記録する

## ステップ2: Slackの自分の投稿取得
- seiya-otomo が今日送信したメッセージを検索する
- 検索クエリ: 'from:@seiya-otomo after:${TODAY_ISO}'
- チャンネル名・時刻・メッセージ概要を記録する
- スレッド返信も含めて確認する

## ステップ3: Gmailの受信・送信メール取得
- 今日のメールを検索する
- 検索クエリ: 'after:${TODAY_GMAIL}' で受信トレイと送信済みを取得
- 件名・相手・送受信の区別・時刻を記録する

## ステップ4: 時系列レポートをSlack DMで送信
収集した全情報を時刻順に並べ、seiya-otomo (U01SC3UBKMX) に以下の形式でSlack DMを送信する:

【日次レポート】${TODAY} 18:00

📅 *カレンダー*
HH:MM イベント名（参加者 / 場所・URL）
（予定なし の場合はその旨記載）

💬 *Slack 投稿*
HH:MM [#チャンネル名] メッセージ概要
（投稿なし の場合はその旨記載）

📧 *Gmail*
HH:MM [受信/送信] 件名 — 相手
（メールなし の場合はその旨記載）

---
情報が取得できない場合は「取得できませんでした」と記載すること。
必ず最後に Slack DMを seiya-otomo (U01SC3UBKMX) に送信すること。
" \
  --allowedTools "mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
