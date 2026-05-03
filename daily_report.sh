#!/bin/bash
# 平日18時の日次レポート
# Slack投稿・Gmail返信・Googleカレンダーを時系列で集約し、自分のSlack DMに送信する

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y年%m月%d日')
TODAY_ISO=$(date '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。今日（${TODAY}）の活動を集約してSlack DMで報告してください。

以下の手順を順番に実行してください：

1. **Googleカレンダーのスケジュールを取得**
   - 今日 ${TODAY_ISO} のイベント一覧を取得する

2. **Slackの自分の投稿を取得**
   - ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
   - 本日送信したSlackメッセージを検索（検索クエリ: 'from:seiya-otomo after:${TODAY_ISO}'）
   - チャンネル投稿・スレッド返信を含む

3. **Gmailの返信メールを取得**
   - 本日送信した返信メールを検索（検索クエリ: 'in:sent after:${TODAY_ISO}'）
   - 件名・宛先・概要を取得

4. **取得した情報を時系列に整理して、seiya-otomo本人 (U01SC3UBKMX) へSlack DMで送信**

送信フォーマット:
【日次レポート】${TODAY}

📅 本日のスケジュール
（時刻順に列挙）

💬 Slack投稿（N件）
（時刻順に列挙：チャンネル名 / 投稿概要）

📧 メール対応（N件）
（時刻順に列挙：件名 / 宛先 / 概要）

件数が0件の場合も「0件」と明記すること。必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
