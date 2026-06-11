#!/bin/bash
# 日次レポート: Slack投稿・Gmailの返信・Googleカレンダーを時系列で集約し、Slack DMに通知
# 毎日18:00（平日のみ）実行
# cron設定例: 0 9 * * 1-5 /path/to/daily_report.sh  (JST 18:00 = UTC 09:00)

export PATH="/opt/node22/bin:$PATH"

TODAY=$(date '+%Y/%m/%d')
TODAY_ISO=$(date '+%Y-%m-%d')
YESTERDAY_ISO=$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d')

claude -p "
あなたは日次レポートアシスタントです。本日（${TODAY}）の活動を以下の手順で集約し、Slack DMに送信してください。

## 手順

### 1. Slackの自分の投稿を取得
- from:<@U01SC3UBKMX> after:${TODAY_ISO} で本日の自分の投稿を検索
- パブリック・プライベート全チャンネル対象
- 投稿した時刻・チャンネル・内容（要約）を取得

### 2. GmailのメールスレッドでTOにいる返信を取得
- Gmail検索: 'to:me newer_than:1d' で本日受信した自分宛メールを取得
- 各スレッドで自分が返信したものと、未返信のものを区別
- 件名・送信者・受信時刻・要約を取得

### 3. Googleカレンダーのスケジュール取得
- 本日（${TODAY_ISO}）の全イベントを取得（開始時刻〜終了時刻）
- イベント名・時刻・参加者を取得

### 4. 時系列に並べてSlack DMに送信
上記3つのデータを時刻順に統合し、以下のフォーマットでSeiya Otomo本人（user_id: U01SC3UBKMX）へSlack DMを送信する。

---
【日次レポート】${TODAY}

📅 **本日のスケジュール・活動ログ（時系列）**

HH:MM | [種別] 内容
例:
09:00 | [予定] ○○ミーティング（参加者: 〇〇, △△）
10:15 | [Slack] #general に「〇〇について」投稿
11:30 | [予定] ○○レビュー
13:00 | [Gmail受信] 件名: 〇〇 from: ✗✗ ← 要返信
14:20 | [Gmail返信] 件名: △△ to: □□
...

---
📊 **サマリー**
- Slack投稿: N件
- Gmail受信（要返信）: N件 / Gmail返信済み: N件
- 予定: N件
---

種別アイコン:
- [予定]: 📅
- [Slack]: 💬
- [Gmail受信]: 📨（要返信は ⚠️ を付ける）
- [Gmail返信]: 📤

必ず最後にSlack DMを U01SC3UBKMX 宛に送信すること。
" \
  --allowedTools "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars" \
  --output-format text \
  2>&1 | tee -a /home/user/-/daily_report.log
