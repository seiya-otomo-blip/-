# 日次活動レポートを毎日18:00（平日のみ）にSlack DMへ通知するスクリプト（Windows PowerShell版）
# タスクスケジューラ設定: 毎日18:00、月〜金のみ実行

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format "yyyy/MM/dd"

$prompt = @"
あなたは日次活動レポートアシスタントです。本日（$today）の活動を時系列でまとめてSlack DMに送信してください。

## 手順

### 1. Slack 自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:$today' で本日の自分の投稿を取得
- チャンネルごとに整理し、投稿時刻・チャンネル名・内容の概要を記録する

### 2. Gmail 返信メールを取得
- 本日送受信した返信メール（スレッドのやりとり）を検索する
- 検索クエリ: 'newer_than:1d' で直近1日のメールを取得
- 件名・相手・送受信時刻・概要を記録する

### 3. Google Calendar スケジュールを取得
- 本日（$today）のカレンダーイベントを全て取得する
- 開始時刻・終了時刻・イベント名・参加者を記録する

### 4. 時系列レポートを作成してSlack DMに送信
以下のフォーマットで seiya-otomo(U01SC3UBKMX) 本人のDMに送信する:

---
📋 *日次活動レポート* $today

🗓 *本日のスケジュール（Googleカレンダー）*
• HH:MM〜HH:MM  イベント名（参加者）
• ...（時刻順）
（予定なしの場合は「予定なし」と記載）

💬 *Slack 投稿*
• HH:MM  #チャンネル名: 投稿内容の概要
• ...（時刻順）
（投稿なしの場合は「投稿なし」と記載）

📧 *メール返信*
• HH:MM  件名（to/from: 相手名）
• ...（時刻順）
（返信なしの場合は「返信なし」と記載）
---

必ず最後にSlack DMをU01SC3UBKMXへ送信すること。
"@

$allowedTools = "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events"

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
