#!/bin/bash
# 日次レポート: Slack投稿・Gメール返信・Googleカレンダーを時系列で集計し、Slack DMに通知
# 毎日18:00（平日のみ）GitHub Actionsから実行

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポート作成アシスタントです。本日（${TODAY}）の活動サマリーを時系列で作成し、seiya-otomo（user_id: U01SC3UBKMX）へSlack DMで送信してください。

## 収集する情報

### 1. Slack: 自分の投稿
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}' で本日の自分の投稿を取得
- チャンネル投稿・DM・スレッド返信を含める
- 各メッセージの時刻・チャンネル・内容（50文字程度に要約）を記録

### 2. Gmail: 受信した返信
- 本日受信したメール（自分宛の返信・新規メール）を検索
- 検索クエリ: newer_than:1d （今日届いたもの）
- 送信者・件名・受信時刻を記録

### 3. Googleカレンダー: 本日のスケジュール
- 本日（${TODAY_ISO}）のカレンダーイベントをすべて取得
- イベント名・開始時刻・終了時刻・場所/会議URLを記録

## レポート形式

以下のフォーマットでSlack DMを送信すること（送信先: U01SC3UBKMX）:

---
📊 *日次レポート ${TODAY}*

🗓 *本日のスケジュール（カレンダー）*
• HH:MM〜HH:MM イベント名
（イベントがない場合は「予定なし」と記載）

💬 *Slackの自分の投稿*
• HH:MM [#チャンネル名] メッセージ概要
（投稿がない場合は「投稿なし」と記載）

📧 *Gmailの受信メール（返信含む）*
• HH:MM 送信者名 - 件名
（メールがない場合は「受信なし」と記載）

---

※ すべてJST（日本標準時）で表示すること。
※ 各セクションは時刻の昇順で並べること。
※ 情報が取得できない場合は「取得できませんでした」と記載してスキップすること。
※ 必ずSlack DMを送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_read_channel,mcp__Slack__slack_send_message,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
