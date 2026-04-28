# デイリーレポート通知スクリプト (Windows PowerShell版)
# タスクスケジューラから毎日18時（平日のみ）に実行する
# トリガー設定: 毎日 18:00、月〜金のみ実行

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format 'yyyy/MM/dd'
$todayISO = Get-Date -Format 'yyyy-MM-dd'

$prompt = @"
あなたはデイリーレポートアシスタントです。以下の手順を実行し、seiya-otomo本人(user_id: U01SC3UBKMX)へSlack DMでレポートを送信してください。

【本日の日付】$today

## 手順

### 1. Googleカレンダーのスケジュール取得
- 本日 $todayISO のカレンダーイベントを全て取得する
- list_calendars で利用可能なカレンダーを確認してからlist_eventsを実行すること
- 開始時刻・終了時刻・イベント名・場所（あれば）を記録

### 2. Slackの自分の投稿を取得
- seiya-otomo (user_id: U01SC3UBKMX) が本日 $todayISO に投稿したメッセージを検索
- 検索クエリ例: 'from:seiya-otomo after:$todayISO'
- チャンネル名・投稿時刻・メッセージ概要を記録

### 3. Gmailの返信・受信メールを取得
- 本日 $todayISO に受信したメールスレッドを検索
- 検索クエリ例: 'after:$todayISO is:inbox' または 'after:$todayISO in:inbox'
- 件名・送信者・受信時刻を記録（最大10件）

### 4. Slack DMで本人へ送信
取得した情報を時系列順（古い順）に並べて、以下の形式でseiya-otomo(U01SC3UBKMX)へDM送信すること:

【デイリーレポート】$today 18:00

📅 本日のカレンダー
（イベントがあれば「HH:MM イベント名」の形式で列挙、なければ「予定なし」）

💬 Slackの投稿
（投稿があれば「HH:MM [#チャンネル名] メッセージ概要」の形式で列挙、なければ「投稿なし」）

📧 Gmailの返信・受信
（メールがあれば「HH:MM 件名 / 送信者」の形式で列挙、なければ「受信なし」）

必ず最後にSlack DMを送信すること。
"@

$allowedTools = "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Slack__slack_read_channel,mcp__Slack__slack_read_thread,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] $msg"
}

Write-Log "デイリーレポート開始"

$success = $false
for ($i = 1; $i -le $maxRetries; $i++) {
    Write-Log "実行試行 $i/$maxRetries"
    try {
        $output = & $claudePath -p $prompt --allowedTools $allowedTools --output-format text 2>&1
        Write-Log $output
        if ($LASTEXITCODE -eq 0) {
            Write-Log "成功"
            $success = $true
            break
        }
    } catch {
        Write-Log "エラー: $_"
    }

    if ($i -lt $maxRetries) {
        Write-Log "${retryDelaySec}秒後にリトライします..."
        Start-Sleep -Seconds $retryDelaySec
        $retryDelaySec = $retryDelaySec * 2
    }
}

if (-not $success) {
    Write-Log "全試行失敗。ログを確認してください: $logFile"
}

Write-Log "デイリーレポート終了"
