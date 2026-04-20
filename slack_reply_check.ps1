# Slack返信漏れチェック & Slack DM通知スクリプト (Windows PowerShell版)
# タスクスケジューラから毎朝9時に実行する

$claudePath = "claude"
$logFile = "$PSScriptRoot\slack_reply_check.log"
$maxRetries = 3
$retryDelaySec = 30

$prompt = @"
あなたはSlackの返信漏れチェックアシスタントです。以下の手順を実行してください。

1. Slackで @seiya-otomo (user_id: U01SC3UBKMX) 宛に来たメッセージのうち、直近2週間で返信漏れがないか確認する
   - 検索クエリ: 'to:<@U01SC3UBKMX>' で直近14日分を検索
   - チャンネルメンション: '<@U01SC3UBKMX>' で直近7日分を検索
   - 各会話の最後のメッセージがseiya-otomo以外からのもので、返信が必要そうかを判断する
   - スレッドも必要に応じて確認する

2. 返信漏れが見つかった場合、seiya-otomo本人(U01SC3UBKMX)へSlack DMで以下の形式で通知する:
   【返信漏れチェック結果】本日 $(Get-Date -Format 'yyyy/MM/dd') 9:00
   返信漏れが N 件あります
   1. [チャンネル/DM名] 送信者: メッセージ概要 (日時) リンク: ...

3. 返信漏れが見つからなかった場合も、seiya-otomoへ以下をDMする:
   【返信漏れチェック結果】本日 $(Get-Date -Format 'yyyy/MM/dd') 9:00
   返信漏れはありません！

必ず最後にSlack DMを送信すること。
"@

$allowedTools = "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] $msg"
}

Write-Log "チェック開始"

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
        # リトライごとに待機時間を2倍に（指数バックオフ）
        $retryDelaySec = $retryDelaySec * 2
    }
}

if (-not $success) {
    Write-Log "全試行失敗。ログを確認してください: $logFile"
}

Write-Log "チェック終了"
