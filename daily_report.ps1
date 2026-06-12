# 日次レポートを平日18:00に実行し、seiya-otomo(U01SC3UBKMX)へSlack DMで通知するスクリプト
# タスクスケジューラ設定:
#   トリガー: 毎日 18:00、繰り返しなし、平日のみ（月〜金）
#
# MCP tool名について:
#   Slack:          e59ce691-91d7-47bc-a81b-1f5cc340e15a (既存設定から)
#   Gmail/Calendar: claude mcp list で確認したIDを環境変数 GMAIL_MCP_ID / GCAL_MCP_ID に設定

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

# MCP サーバーID設定
$slackMcpId = "e59ce691-91d7-47bc-a81b-1f5cc340e15a"
$gmailMcpId  = if ($env:GMAIL_MCP_ID) { $env:GMAIL_MCP_ID } else { "Gmail" }
$gcalMcpId   = if ($env:GCAL_MCP_ID)  { $env:GCAL_MCP_ID }  else { "Google-Calendar" }

$today    = Get-Date -Format "yyyy/MM/dd"
$todayIso = Get-Date -Format "yyyy-MM-dd"

$prompt = @"
あなたは日次レポートアシスタントです。以下の手順を順番に実行してください。

今日の日付: ${today}
自分のSlack user_id: U01SC3UBKMX

## STEP 1: Slackの本日の自分の投稿を取得
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${todayIso}'
- 投稿チャンネル・内容の概要・タイムスタンプ（時刻）を記録する
- スレッド返信も含めて取得する

## STEP 2: Gmailの本日受信した返信メールを取得
- 検索クエリ: 'newer_than:1d in:inbox'
- 件名・送信者・受信時刻を記録する（本文は不要、件名と送信者のみ）

## STEP 3: Googleカレンダーの本日のスケジュールを取得
- 本日 ${todayIso}T00:00:00 〜 ${todayIso}T23:59:59 のイベントを取得
- イベント名・開始時刻・終了時刻・参加者を記録する

## STEP 4: 時系列で整理してSlack DMを送信
上記3つの情報を時刻順（早い順）に並べ、以下の形式でU01SC3UBKMXへSlack DMを送信してください:

---
【日次レポート】${today}

📅 本日のスケジュール・活動サマリー
━━━━━━━━━━━━━━━━━━━━

[時刻] 絵文字 内容 (種別)
例:
09:00–10:00 📅 朝会 _(Google Calendar)_
10:15 💬 #general にメッセージ投稿: 「XXXについて...」 _(Slack)_
11:30 📧 田中さんから返信: 件名「Re: XXX」 _(Gmail)_
...

（データがない種別は「なし」と表記）

━━━━━━━━━━━━━━━━━━━━
📊 本日のサマリー
• 📅 予定: N件
• 💬 Slack投稿: N件
• 📧 受信メール返信: N件
---

必ず最後にSlack DM（channel_id: U01SC3UBKMX）を送信すること。
"@

$allowedTools = @(
    "mcp__${slackMcpId}__slack_search_public_and_private",
    "mcp__${slackMcpId}__slack_read_channel",
    "mcp__${slackMcpId}__slack_read_thread",
    "mcp__${slackMcpId}__slack_send_message",
    "mcp__${slackMcpId}__slack_search_users",
    "mcp__${gmailMcpId}__search_threads",
    "mcp__${gmailMcpId}__get_thread",
    "mcp__${gcalMcpId}__list_events",
    "mcp__${gcalMcpId}__list_calendars"
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
