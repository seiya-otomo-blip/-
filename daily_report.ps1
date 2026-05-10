# 日次レポート: 毎日18:00（平日のみ）にSlack/Gmail/Googleカレンダーを集計してDMで通知
# タスクスケジューラに登録: 0 18 * * 1-5

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format 'yyyy/MM/dd'
$todayIso = Get-Date -Format 'yyyy-MM-dd'

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] $msg"
}

$prompt = @"
あなたは日次活動レポートアシスタントです。本日（${today}）の活動を以下の手順で集計し、Slack DMで報告してください。

## ステップ1: Googleカレンダーの予定を取得
- 本日 ${todayIso}T00:00:00 〜 ${todayIso}T23:59:59 の全予定を取得する
- 各予定の開始時刻・終了時刻・タイトル・説明を記録する

## ステップ2: Slackの自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${todayIso} before:${todayIso}' で本日の投稿を検索
- チャンネル名・投稿時刻・メッセージ概要を記録する
- スレッドへの返信も含める

## ステップ3: Gmailの送受信を取得
- 本日送信したメール: クエリ 'in:sent after:${todayIso} before:${todayIso}'
- 本日受信した返信（未読含む）: クエリ 'after:${todayIso} before:${todayIso} -in:sent'
- 各メールの時刻・件名・送受信相手を記録する

## ステップ4: 時系列でまとめてSlack DMに送信
以下のフォーマットで seiya-otomo（U01SC3UBKMX）へSlack DMを送信すること:

【日次レポート】${today}

📅 カレンダー
HH:MM [予定タイトル]（所要時間）
...（時系列順）

💬 Slack投稿
HH:MM [#チャンネル名] メッセージ概要
...（時系列順）

📧 Gmail
HH:MM [送信/受信] 件名（相手）
...（時系列順）

---
以上、本日の活動サマリーでした。

※ データが取得できなかった項目は「データなし」と記載すること。
※ 必ず最後にSlack DMを送信すること。
"@

$allowedTools = "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_read_thread,mcp__Slack__slack_send_message,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events"

Write-Log "日次レポート開始"

$success = $false
$delay = $retryDelaySec

for ($i = 1; $i -le $maxRetries; $i++) {
    Write-Log "実行試行 $i/$maxRetries"
    try {
        $output = & $claudePath -p $prompt --allowedTools $allowedTools --output-format text 2>&1
        Write-Log $output
        if ($LASTEXITCODE -eq 0) {
            Write-Log "日次レポート送信成功"
            $success = $true
            break
        }
    } catch {
        Write-Log "エラー: $_"
    }

    if ($i -lt $maxRetries) {
        Write-Log "${delay}秒後にリトライします..."
        Start-Sleep -Seconds $delay
        $delay = $delay * 2
    }
}

if (-not $success) {
    Write-Log "全試行失敗。ログを確認: $logFile"
}

Write-Log "日次レポート終了"
