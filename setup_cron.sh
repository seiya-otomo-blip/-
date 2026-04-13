#!/bin/bash
# cron設定スクリプト
# 既存のcronエントリに日次レポートとSlack返信漏れチェックを追加する

SCRIPT_DIR="/home/user/-"

# 既存のcrontabを取得し、重複を避けながら追記する
EXISTING=$(crontab -l 2>/dev/null)

add_cron() {
  local entry="$1"
  if echo "$EXISTING" | grep -qF "$entry"; then
    echo "Already exists: $entry"
  else
    (echo "$EXISTING"; echo "$entry") | crontab -
    echo "Added: $entry"
    EXISTING=$(crontab -l)
  fi
}

echo "=== cron設定を追加しています ==="

add_cron "0 9 * * 1-5 $SCRIPT_DIR/slack_reply_check.sh"
add_cron "0 18 * * 1-5 $SCRIPT_DIR/daily_report.sh"

echo ""
echo "=== 現在のcrontab ==="
crontab -l

echo ""
echo "完了: 以下のスケジュールが設定されました"
echo "  - 毎朝 09:00（平日）: Slack返信漏れチェック"
echo "  - 毎日 18:00（平日）: 日次レポート（Slack/Gmail/Googleカレンダー）"
