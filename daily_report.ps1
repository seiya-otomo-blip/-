# 日次レポート: 平日18時にSlack投稿・Gmail返信・Googleカレンダーを集約してDM通知
# タスクスケジューラから平日18時に実行する

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format "yyyy/MM/dd"
$todayIso = Get-Date -Format "yyyy-MM-dd"
$userId = "U01SC3UBKMX"

$slackMcp = "e59ce691-91d7-47bc-a81b-1f5cc340e15a"
$gmailMcp = "ec8b2c1c-d01c-4297-8a5e-afc11958c457"
$gcalMcp  = "4abecda0-f819-4c96-8704-7e8adce94aab"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] $msg"
    Write-Host "[$ts] $msg"
}

$prompt = @"
あなたは日次レポートアシスタントです。本日 ${today} の活動サマリーを作成し、Slack DMで通知してください。

以下の手順を順番に実行してください:

## 手順1: Googleカレンダーの本日のスケジュールを取得
- 開始時刻: ${todayIso}T00:00:00+09:00
- 終了時刻: ${todayIso}T23:59:59+09:00
- タイムゾーン: Asia/Tokyo
- イベント名・開始時刻・終了時刻・場所・参加者を記録

## 手順2: Slackの自分の投稿を取得
- 検索クエリ: 'from:seiya-otomo after:${todayIso}' で本日の自分の投稿を検索
- 各投稿のチャンネル名・時刻・内容（要約）を記録

## 手順3: Gmailの本日の受信メールを取得
- 検索クエリ: 'newer_than:1d in:inbox' で本日受信したメールを取得（最大20件）
- 件名・送信者・受信時刻を記録

## 手順4: 時系列レポートを作成してSlack DMを送信
上記で取得した全データを時刻の昇順で並べ、以下の形式で seiya-otomo本人（user_id: ${userId}）へ Slack DM を送信すること。

送信するメッセージの形式:
---
【日次レポート】${today} 18:00

📅 本日のタイムライン（時系列）

HH:MM 📆 [カレンダー] イベント名（場所・参加者があれば記載）
HH:MM 💬 [Slack] #チャンネル名 メッセージ内容の要約
HH:MM 📧 [Gmail] 件名 ← from: 送信者名

（データがない時間帯は省略、各種類で0件の場合は「なし」と記載）

📊 本日のサマリー
- 📆 カレンダー予定: N件
- 💬 Slack投稿: N件
- 📧 Gmail受信: N件
---

データが取得できなかった項目は「取得できませんでした」と記載すること。
必ずSlack DMを送信してから終了すること。
"@

$allowedTools = @(
    "mcp__${gcalMcp}__list_events",
    "mcp__${gcalMcp}__list_calendars",
    "mcp__${slackMcp}__slack_search_public_and_private",
    "mcp__${slackMcp}__slack_read_thread",
    "mcp__${slackMcp}__slack_read_channel",
    "mcp__${slackMcp}__slack_search_users",
    "mcp__${slackMcp}__slack_send_message",
    "mcp__${gmailMcp}__search_threads",
    "mcp__${gmailMcp}__get_thread"
) -join ","

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
