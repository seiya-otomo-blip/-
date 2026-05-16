# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列で集約し、Slack DMに通知
# スケジュール: 毎日 18:00（平日のみ）
# タスクスケジューラ登録例:
#   schtasks /create /tn "DailyReport" /tr "powershell -File C:\path\daily_report.ps1" /sc weekly /d MON,TUE,WED,THU,FRI /st 18:00

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format 'yyyy/MM/dd'
$todayISO = Get-Date -Format 'yyyy-MM-dd'
$yesterdayISO = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')

$prompt = @"
あなたは日次業務レポート作成アシスタントです。本日 ${today} の活動を以下の手順で収集し、時系列でまとめてください。

## 収集手順

### 1. Googleカレンダー: 本日のスケジュール取得
- 本日（${todayISO}T00:00:00+09:00 〜 ${todayISO}T23:59:59+09:00）の全イベントを取得する
- 時刻・イベント名・参加者・場所を記録する

### 2. Slack: 自分の本日の投稿を取得
- ユーザー: seiya-otomo (user_id: U01SC3UBKMX)
- 検索クエリ: 'from:seiya-otomo after:${yesterdayISO}' でチャンネル投稿を検索
- DM送信も含め、投稿時刻・チャンネル・内容を記録する

### 3. Gmail: 本日の返信・受信メールを取得
- 検索クエリ: 'after:${todayISO} (in:sent OR label:inbox)' で本日のメールを取得
- 送信メールと重要な受信メールを時刻順に記録する

## レポート送信
上記を時系列に並べ、以下の形式でSeiya-otomo本人（user_id: U01SC3UBKMX）にSlack DMで送信してください：

---
【日次レポート】${today} 18:00

📅 本日のスケジュール（Googleカレンダー）
HH:MM イベント名 [参加者/場所があれば]
（イベントがない場合は「予定なし」）

💬 本日のSlack投稿
HH:MM [#チャンネル名 or DM] 投稿内容の要約（30文字以内）
（投稿がない場合は「投稿なし」）

📧 本日のGmail
HH:MM [送/受] 件名 (相手)
（メールがない場合は「メールなし」）

---
合計: スケジュールN件 / Slack投稿N件 / メールN件
---

必ず最後にSlack DMを seiya-otomo(U01SC3UBKMX) に送信すること。
"@

$slackId = "e59ce691-91d7-47bc-a81b-1f5cc340e15a"
$gmailId = "ec8b2c1c-d01c-4297-8a5e-afc11958c457"
$calId   = "4abecda0-f819-4c96-8704-7e8adce94aab"

$allowedTools = @(
    "mcp__${calId}__list_events",
    "mcp__${calId}__list_calendars",
    "mcp__${calId}__get_event",
    "mcp__${slackId}__slack_search_public_and_private",
    "mcp__${slackId}__slack_search_public",
    "mcp__${slackId}__slack_read_channel",
    "mcp__${slackId}__slack_read_thread",
    "mcp__${slackId}__slack_send_message",
    "mcp__${slackId}__slack_search_users",
    "mcp__${gmailId}__search_threads",
    "mcp__${gmailId}__get_thread",
    "mcp__${gmailId}__list_labels"
) -join ","

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
