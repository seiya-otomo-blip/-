# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列集約してDM通知
# タスクスケジューラ設定: 平日(月〜金) 18:00 に実行

$claudePath = "claude"

$today = Get-Date -Format "yyyy/MM/dd"
$todayIso = Get-Date -Format "yyyy-MM-dd"
$yesterdayIso = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

$prompt = @"
あなたは日次レポート作成アシスタントです。本日 ${today} の活動サマリーを作成し、seiya-otomo(U01SC3UBKMX)のSlack DMに送信してください。

## 手順

### 1. Googleカレンダーのスケジュール取得
- 本日 ${todayIso}T00:00:00 〜 ${todayIso}T23:59:59 の全イベントを取得する
- startTime: ${todayIso}T00:00:00、endTime: ${todayIso}T23:59:59、orderBy: startTime

### 2. Gmailの返信取得
- 本日受信したメールスレッドを検索する
- クエリ: 'after:${todayIso} is:inbox'
- 最大20件取得し、返信済み・未返信を区別して整理する

### 3. Slackの自分の投稿取得
- seiya-otomo(U01SC3UBKMX)が本日投稿したメッセージを検索する
- 検索クエリ: 'from:seiya-otomo after:${yesterdayIso}'
- 投稿内容とチャンネル名を取得する

### 4. 時系列レポートを作成してSlack DMに送信
以下のフォーマットでまとめ、U01SC3UBKMX宛にDMを送信すること:

【日次レポート】${today} 18:00

📅 *本日のスケジュール*
<時刻順にイベント一覧>
（予定なしの場合は「予定なし」と記載）

📨 *Gmail受信サマリー*
・受信数: N件
・未返信: N件
<未返信スレッドがあれば件名と送信者を最大5件列挙>

💬 *Slack投稿サマリー*
・投稿数: N件
<チャンネル別に投稿数をまとめ、主な投稿内容を1行で記載>

---
必ず最後に mcp__Slack__slack_send_message でU01SC3UBKMX宛にDMを送信すること。
"@

$logFile = "$PSScriptRoot\daily_report.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "[$timestamp] 日次レポート開始"

& $claudePath -p $prompt `
    --allowedTools "mcp__Google-Calendar__list_events,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users" `
    --output-format text 2>&1 | Add-Content -Path $logFile

Add-Content -Path $logFile -Value "[$timestamp] 日次レポート完了"
