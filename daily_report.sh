#!/bin/bash
# 日次レポート: Slack投稿 / Gmail返信 / Googleカレンダー を集計して Slack DM に通知
# 実行タイミング: 平日 18:00（cron または タスクスケジューラ経由）

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=月 〜 7=日

# 平日のみ実行
if [ "$WEEKDAY" -ge 6 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') 土日のためスキップ" >> /home/user/-/daily_report.log
  exit 0
fi

claude -p "
あなたは日次レポート作成アシスタントです。今日（${TODAY}）の活動を3つのソースから時系列で収集し、Slack DM にレポートを送信してください。

## ステップ1: データ収集（並行して取得）

### 1-1. Slack 自分の投稿
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${TODAY_ISO}'
- sort: timestamp, sort_dir: asc
- 取得した投稿を時刻・チャンネル・内容の形式でリスト化

### 1-2. Gmail 受信・返信
- 検索クエリ: 'after:${TODAY_ISO//-//}' (受信トレイ)
- 送信済みも検索: 'in:sent after:${TODAY_ISO//-//}'
- 件名・送信者/宛先・時刻をリスト化

### 1-3. Google カレンダー
- 本日 ${TODAY_ISO}T00:00:00+09:00 〜 ${TODAY_ISO}T23:59:59+09:00 のイベントを取得
- timeZone: Asia/Tokyo, orderBy: startTime
- イベント名・開始〜終了時刻・場所をリスト化

## ステップ2: 時系列レポートを Slack DM (U01SC3UBKMX) へ送信

以下の形式で送信する（空セクションは「なし」と記載）:

📋 *日次レポート — ${TODAY}*

━━━━━━━━━━━━━━━━━━━━
📅 *カレンダー*
（時刻 タイトル / 場所 の形式で列挙）

━━━━━━━━━━━━━━━━━━━━
💬 *Slack 自分の投稿*
（時刻 [チャンネル] メッセージ概要 の形式で列挙）

━━━━━━━━━━━━━━━━━━━━
📧 *Gmail（受信・送信）*
（時刻 件名 / From または To の形式で列挙）

━━━━━━━━━━━━━━━━━━━━
_以上、本日の活動サマリーでした_ 🙌

必ず最後に Slack DM を送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
