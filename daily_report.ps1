# 日次活動レポートを毎日18時（平日）にSlack DMで送信するスクリプト（Windows PowerShell版）
# タスクスケジューラから平日18時に実行する

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format 'yyyy/MM/dd'
$todayIso = Get-Date -Format 'yyyy-MM-dd'

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Write-Log "日次レポート生成開始 ($today)"

$prompt = @"
あなたは日次活動レポートアシスタントです。本日 $today の活動サマリーを作成し、Slack DMで送信してください。

以下の手順を順番に実行してください：

## ステップ1: 本日の活動情報を収集

### 【Slack】本日の自分の投稿
- seiya-otomo (user_id: U01SC3UBKMX) が本日送信したメッセージを検索
- 検索クエリ: 'from:seiya-otomo after:$todayIso'
- 各投稿のチャンネル名、時刻（HH:MM形式）、メッセージ概要を記録

### 【Gmail】本日の返信・受信メール
- 本日送信したメール: 検索クエリ 'in:sent after:$todayIso'
- 本日受信した重要メール: 検索クエリ 'in:inbox after:$todayIso -category:promotions'
- 件名、送受信先、時刻を記録

### 【Google カレンダー】本日の予定
- 本日 $todayIso のカレンダーイベントを全て取得
- イベント名、開始時刻（HH:MM形式）、終了時刻を記録

## ステップ2: 時系列レポートを作成

収集した情報を時刻順（古い順）に並べ、以下のフォーマットでレポートを作成してください：

---
【日次活動レポート】$today

📋 本日のサマリー（時系列）

HH:MM 📅 [予定名] (開始〜終了)
HH:MM 💬 [チャンネル名] メッセージ概要
HH:MM 📧 件名（送信先 or 送信者）

📊 集計
• カレンダー予定: X 件
• Slack 投稿: Y 件
• Gmail 送信: Z 件
• Gmail 受信: W 件
---

情報が取得できなかった項目は「なし」と記載すること。

## ステップ3: Slack DMで送信

作成したレポートを seiya-otomo (user_id: U01SC3UBKMX) へ Slack DM で送信する。
必ず最後にSlack DMを送信すること。
"@

$allowedTools = "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__search_threads,mcp__ec8b2c1c-d01c-4297-8a5e-afc11958c457__get_thread,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_events,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__list_calendars,mcp__4abecda0-f819-4c96-8704-7e8adce94aab__get_event"

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
    exit 1
}
