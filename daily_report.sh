#!/bin/bash
# 日次レポート自動実行スクリプト
# スケジュール: 毎平日 18:00
# 実行内容: Slack投稿・Gmail返信・Googleカレンダーを時系列で収集し、Slack DMに送信

set -euo pipefail

# 曜日チェック（1=月〜5=金のみ実行）
DOW=$(date +%u)
if [ "$DOW" -gt 5 ]; then
  echo "Weekend - skipping daily report."
  exit 0
fi

# ログファイル
LOG_DIR="$(cd "$(dirname "$0")" && pwd)/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/daily_report_$(date +%Y%m%d).log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting daily report..." | tee -a "$LOG_FILE"

# Claude Code CLI を使って日次レポートを実行
# --print (-p) フラグ: 非対話モードで単一プロンプトを実行して結果を出力
claude --print "$(cat <<'PROMPT'
以下の手順で本日の日次レポートを作成し、自分のSlack DMに送信してください。

## 実行手順

1. **本日の日付**を確認する（Asia/Tokyo タイムゾーン）

2. **Googleカレンダー**から本日のイベントを時系列で取得する
   - timeZone: Asia/Tokyo
   - startTime: 本日00:00:00
   - endTime: 本日23:59:59

3. **Gmail**から本日の関連メールを取得する
   - 検索クエリ: `after:<本日の日付YYYY/M/D> before:<翌日の日付YYYY/M/D>`
   - システム通知（jinjer勤怠/kintone/HERP/プロモーション）は除外
   - 自分が送信したメール、宛先・CCに含まれる業務メールを含める

4. **Slack**から本日の自分の投稿を時系列で取得する
   - 検索: `from:<@U01SC3UBKMX>`
   - after パラメータ: 本日0:00のUnixタイムスタンプ（JST）

5. 取得したデータを以下の形式でまとめ、**自分のSlack DM（channel_id: U01SC3UBKMX）**に送信する

## レポート形式

```
📋 *日次レポート｜YYYY年M月D日（曜日）*
━━━━━━━━━━━━━━━━━━━━

📅 *本日のスケジュール（時系列）*
• HH:MM〜HH:MM　イベント名
...

━━━━━━━━━━━━━━━━━━━━

📧 *本日のGmail（返信・関係メール）*
• HH:MM　送信者→宛先「件名・概要」
...

━━━━━━━━━━━━━━━━━━━━

💬 *本日のSlack投稿（時系列）*
• HH:MM　宛先/チャンネル「メッセージ概要」
...

━━━━━━━━━━━━━━━━━━━━
_Claude Codeによる自動生成（毎平日18:00）_
```

注意:
- 時刻はすべてJST（Asia/Tokyo）で表示
- メッセージ全体が5000文字を超える場合は重要度の高いものに絞る
- Slackのメッセージはslack_send_messageツールで送信すること（channel_id: U01SC3UBKMX）
PROMPT
)" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Daily report completed successfully." | tee -a "$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Daily report failed with exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
fi

exit $EXIT_CODE
