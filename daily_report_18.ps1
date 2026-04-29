# 日次レポート通知スクリプト (Windows PowerShell版)
# タスクスケジューラから平日18:00に実行する
# 収集対象: Slack投稿・Gmail返信・Googleカレンダー → 時系列でSlack DMに通知

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report_18.log"
$maxRetries = 3
$retryDelaySec = 30

# MCP toolbox server IDs
$SLACK_ID  = "e59ce691-91d7-47bc-a81b-1f5cc340e15a"
$GMAIL_ID  = "ec8b2c1c-d01c-4297-8a5e-afc11958c457"
$GCAL_ID   = "4abecda0-f819-4c96-8704-7e8adce94aab"

$allowedTools = @(
    "mcp__${SLACK_ID}__slack_search_public_and_private",
    "mcp__${SLACK_ID}__slack_read_thread",
    "mcp__${SLACK_ID}__slack_send_message",
    "mcp__${SLACK_ID}__slack_search_users",
    "mcp__${SLACK_ID}__slack_read_channel",
    "mcp__${GMAIL_ID}__search_threads",
    "mcp__${GMAIL_ID}__get_thread",
    "mcp__${GCAL_ID}__list_calendars",
    "mcp__${GCAL_ID}__list_events"
) -join ","

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] $msg"
}

# 平日（月〜金）のみ実行
$dow = (Get-Date).DayOfWeek
if ($dow -eq "Saturday" -or $dow -eq "Sunday") {
    Write-Log "土日のためスキップ"
    exit 0
}

$today     = Get-Date -Format "yyyy/MM/dd"
$todayISO  = Get-Date -Format "yyyy-MM-dd"

$prompt = @"
あなたは日次レポートアシスタントです。本日 ${today} の活動を以下の手順でまとめ、seiya-otomo (user_id: U01SC3UBKMX) にSlack DMで送信してください。

## 収集手順

### 1. Slackの自分の投稿を取得
- 検索クエリ: 'from:@seiya-otomo after:${todayISO}' で本日のseiya-otomoの投稿を検索
- チャンネル投稿・スレッド返信を含む
- 各投稿について: 時刻・チャンネル名・メッセージ概要を記録

### 2. Gmailの返信を取得
- 本日受信した返信メール（スレッドに返信が来たもの）を検索
  - 検索クエリ: 'after:${todayISO} in:inbox'
- 各メールについて: 時刻・送信者・件名・概要を記録

### 3. Googleカレンダーのスケジュールを取得
- まず list_calendars でカレンダー一覧を取得
- 本日 ${todayISO} のイベントを list_events で取得
- 各イベントについて: 開始時刻・終了時刻・タイトルを記録

## レポート形式

収集した情報を時系列（古い順）に並べて、以下の形式でSlack DMを送信してください:

---
【日次レポート】${today} 18:00

📅 本日のタイムライン
────────────────────
HH:MM [種別] 内容の概要
HH:MM [種別] 内容の概要
...

種別の凡例:
- [カレンダー] Googleカレンダーのイベント
- [Slack] Slackへの自分の投稿
- [Gmail] 受信したメールの返信

📊 サマリー
- カレンダー: N件のイベント
- Slack投稿: N件
- Gmail返信受信: N件

何もない種別は「なし」と記載してください。
---

必ずSlack DMをU01SC3UBKMXへ送信して完了としてください。
"@

Write-Log "日次レポート生成開始"

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

Write-Log "日次レポート生成終了"
