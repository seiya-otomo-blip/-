# 平日18:00 日次レポート: Slack投稿 / Gメール返信 / Googleカレンダーを時系列でまとめてDM通知
# タスクスケジューラから平日18:00に実行する

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format "yyyy/MM/dd"
$todayIso = Get-Date -Format "yyyy-MM-dd"

$prompt = @"
あなたは日次レポートアシスタントです。本日 $today の活動サマリーを作成し、seiya-otomo (U01SC3UBKMX) 本人へSlack DMで送信してください。

## 取得手順

### 1. Slackの自分の投稿を取得
- 検索クエリ: 'from:seiya-otomo after:$todayIso' で本日のseiya-otomoの投稿を検索
- 投稿日時・チャンネル・内容の概要を記録

### 2. Gmailの返信を取得
- 本日 $todayIso 以降に受信したメールのスレッドを検索 (after:$todayIso)
- 自分が送信した返信メールも含めて取得
- 送信者・件名・日時を記録

### 3. Googleカレンダーのスケジュールを取得
- 本日 $todayIso のカレンダーイベント一覧を取得
- 開始時刻・終了時刻・イベント名を記録

### 4. 時系列で並べてDM送信
上記3つのデータを時刻順に並べ、以下の形式でseiya-otomo (U01SC3UBKMX) へSlack DMを送信:

【日次レポート】$today 18:00

📅 本日のタイムライン
──────────────────
HH:MM [カレンダー] イベント名
HH:MM [Slack] #チャンネル名: 投稿内容の概要
HH:MM [Gmail] 件名 (送信者)
...（時系列順）

📊 サマリー
・カレンダー: N件のイベント
・Slack投稿: N件
・メール受信/返信: N件

必ず最後にSlack DMを送信すること。データが取得できなかった項目は「取得なし」と記載すること。
"@

$allowedTools = "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] $msg"
}

Write-Log "日次レポート開始"

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

Write-Log "日次レポート終了"
