# 日次レポート: Slack投稿 / Gmail返信 / Googleカレンダー を集計して Slack DM に通知
# タスクスケジューラから平日 18:00 に実行する

$claudePath = "claude"
$logFile = "$PSScriptRoot\daily_report.log"
$maxRetries = 3
$retryDelaySec = 30

# 平日のみ実行
$weekday = (Get-Date).DayOfWeek
if ($weekday -eq "Saturday" -or $weekday -eq "Sunday") {
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 土日のためスキップ"
    exit 0
}

$today     = Get-Date -Format 'yyyy/MM/dd'
$todayIso  = Get-Date -Format 'yyyy-MM-dd'
$todayGmail = Get-Date -Format 'yyyy/MM/dd'

$prompt = @"
あなたは日次レポート作成アシスタントです。今日（${today}）の活動を3つのソースから時系列で収集し、Slack DM にレポートを送信してください。

## ステップ1: データ収集

### 1-1. Slack 自分の投稿
- 検索クエリ: 'from:<@U01SC3UBKMX> after:${todayIso}'
- sort: timestamp, sort_dir: asc
- 取得した投稿を時刻・チャンネル・内容の形式でリスト化

### 1-2. Gmail 受信・返信
- 検索クエリ: 'after:${todayGmail}' (受信トレイ)
- 送信済みも検索: 'in:sent after:${todayGmail}'
- 件名・送信者/宛先・時刻をリスト化

### 1-3. Google カレンダー
- 本日 ${todayIso}T00:00:00+09:00 〜 ${todayIso}T23:59:59+09:00 のイベントを取得
- timeZone: Asia/Tokyo, orderBy: startTime
- イベント名・開始〜終了時刻をリスト化

## ステップ2: 時系列レポートを Slack DM (U01SC3UBKMX) へ送信

以下の形式で送信する（空セクションは「なし」と記載）:

📋 *日次レポート — ${today}*

━━━━━━━━━━━━━━━━━━━━
📅 *カレンダー*
（時刻 タイトル / 場所 の形式で列挙）

━━━━━━━━━━━━━━━━━━━━
💬 *Slack 自分の投稿*
（時刻 [チャンネル] メッセージ概要 の形式で列挙）

━━━━━━━━━━━━━━━━━━━━
📧 *Gmail（受信・送信）*
（時刻 件名 / From または To の形式で列挙）

━━━━━━━━━━━━━━━━━━━━
_以上、本日の活動サマリーでした_ 🙌

必ず最後に Slack DM を送信すること。
"@

$allowedTools = "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel,mcp__Gmail__search_threads,mcp__Gmail__get_thread,mcp__Google-Calendar__list_events"

$success = $false
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    try {
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 実行開始 (試行 $attempt/$maxRetries)"
        & $claudePath -p $prompt --allowedTools $allowedTools --output-format text 2>&1 | Tee-Object -Append -FilePath $logFile
        if ($LASTEXITCODE -eq 0) {
            $success = $true
            Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完了"
            break
        }
    } catch {
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') エラー: $_"
    }
    if ($attempt -lt $maxRetries) {
        $delay = $retryDelaySec * [Math]::Pow(2, $attempt - 1)
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ${delay}秒後にリトライ..."
        Start-Sleep -Seconds $delay
    }
}

if (-not $success) {
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 全試行失敗"
    exit 1
}
