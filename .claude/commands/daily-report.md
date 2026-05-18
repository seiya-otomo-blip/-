---
description: 本日のSlack投稿・Gmail返信・Googleカレンダーを時系列にまとめてSlack DMで通知
---

本日の日次レポートを作成してSlack DMで通知します。

$ARGUMENTS

## 実行手順

今日の日付: !`date '+%Y/%m/%d'`
今日のISO日付: !`date '+%Y-%m-%d'`

### 1. Googleカレンダーのスケジュール取得
本日のカレンダーイベントを全て取得する（開始時刻・終了時刻・タイトル）。

### 2. Slackの自分の投稿取得
seiya-otomo (U01SC3UBKMX) が本日送信したメッセージを検索する。
検索クエリ: `from:seiya-otomo after:!`date '+%Y-%m-%d'``

### 3. Gmailの返信取得
本日受信・送信した返信メールを検索する。
検索クエリ: `after:!`date '+%Y-%m-%d'` (in:sent OR (label:inbox is:read))`

### 4. 時系列レポートをSlack DMで送信
上記を時刻順に並べて seiya-otomo (U01SC3UBKMX) へ以下の形式でDM送信:

```
【📋 日次レポート】YYYY/MM/DD

📅 *スケジュール*
HH:MM〜HH:MM  イベント名

💬 *Slack投稿*
HH:MM  [#チャンネル名] メッセージ概要

📧 *メール返信*
HH:MM  件名 (相手)

⏱ 合計アクティビティ: N件
```

必ず最後にSlack DMを送信すること。
