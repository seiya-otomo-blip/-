#!/bin/bash
# 平日18:00（JST）に実行する日次レポートスクリプト
# Slack投稿・Gmail返信・Googleカレンダーを時系列でまとめてSlack DMに通知

export PATH="/opt/node22/bin:$PATH"
export TZ="Asia/Tokyo"

TODAY=$(TZ="Asia/Tokyo" date '+%Y/%m/%d')
TODAY_ISO=$(TZ="Asia/Tokyo" date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。以下の手順を順番に実行してください。

## 対象ユーザー
- Slack user_id: U01SC3UBKMX (seiya-otomo)
- 今日の日付: ${TODAY}（JST）

## ステップ1: Googleカレンダーのイベント取得
本日（${TODAY_ISO}）のカレンダーイベントをすべて取得する。
- list_calendars でカレンダー一覧を取得
- list_events で今日のイベントを取得（timeMin: ${TODAY_ISO}T00:00:00+09:00, timeMax: ${TODAY_ISO}T23:59:59+09:00）
- 各イベントの開始時刻・終了時刻・タイトル・場所・参加者を記録する

## ステップ2: Slackの自分の投稿を取得
本日 seiya-otomo (U01SC3UBKMX) が送信したメッセージを検索する。
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}'
- スレッドへの返信も含めて取得する
- 各投稿のチャンネル名・時刻・内容を記録する

## ステップ3: GmailのメールをGET
本日送受信したメールを取得する。
- 送信したメール: 検索クエリ 'from:me after:${TODAY_ISO}'
- 受信したメール（返信あり）: 検索クエリ 'in:inbox after:${TODAY_ISO}'
- 各メールの時刻・件名・送受信先・概要を記録する

## ステップ4: 日次レポートを作成してSlack DMに送信
上記で取得した情報を時系列（早い時間順）で整理し、seiya-otomo本人(U01SC3UBKMX)へSlack DMで以下の形式で送信する:

---
【日次レポート】${TODAY}

📅 カレンダー
HH:MM - HH:MM｜イベント名（場所 / 参加者数）
...（イベントがない場合は「予定なし」）

💬 Slack投稿
HH:MM｜#チャンネル名 「メッセージ概要」
...（投稿がない場合は「投稿なし」）

📧 メール
HH:MM｜件名（宛先 or 送信者）
...（メールがない場合は「なし」）

---
時系列順（カレンダー・Slack・メールをすべて混在させて時刻順に並べること）

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__get_event,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
