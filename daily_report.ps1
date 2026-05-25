# 日次レポート: Slack投稿・Gmail返信・Googleカレンダーを時系列で取得し、Slack DMで通知
# 実行タイミング: 平日 18:00（Windowsタスクスケジューラ経由）

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

$today = Get-Date -Format 'yyyy/MM/dd'
$todaySearch = Get-Date -Format 'yyyy-MM-dd'

$prompt = @"
あなたは日次レポートアシスタントです。本日（${today}）の活動サマリーを作成し、seiya-otomo(U01SC3UBKMX)へSlack DMで送信してください。

以下の手順を順番に実行してください：

## Step 1: Slackの自分の投稿を取得
- 検索クエリ: 'from:seiya-otomo after:${todaySearch}' で本日の自分の投稿を検索
- チャンネル投稿・スレッドへの返信を含む
- 投稿時刻・チャンネル名・メッセージ概要を記録する

## Step 2: Gmailの返信を取得
- 本日受信した返信メール・重要なスレッドを検索 (after:${todaySearch})
- 件名・送信者・受信時刻を記録する

## Step 3: Googleカレンダーのスケジュールを取得
- 本日（${todaySearch}）のカレンダーイベントをすべて取得
- イベント名・開始時刻・終了時刻を記録する

## Step 4: 時系列レポートを作成してSlack DMで送信
Step 1〜3で取得した情報を時系列（時刻順）に並べ替え、以下の形式で seiya-otomo(U01SC3UBKMX) へDM送信する:

【日次レポート】${today} 18:00

📅 本日のタイムライン
─────────────────────
[時刻] [種別アイコン] 内容

種別アイコン:
  💬 Slack投稿
  📧 Gmail返信・受信
  🗓️ カレンダーイベント

例:
09:00 🗓️ 朝会（#general）
10:30 💬 [#dev] PR #123 についてコメント
11:15 📧 [件名: 〇〇の件] 山田さんから返信
─────────────────────
📊 サマリー
  Slack投稿: N件
  Gmail返信: N件
  カレンダー: N件

必ず最後にSlack DMを送信すること。
"@

$allowedTools = "mcp__Slack__slack_search_public_and_private,mcp__Slack__slack_search_public,mcp__Slack__slack_read_thread,mcp__Slack__slack_read_channel,mcp__Slack__slack_send_message,mcp__Slack__slack_search_users,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events,mcp__Google-Calendar__list_calendars"

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
