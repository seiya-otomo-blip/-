#!/bin/bash
# 日次レポート用スケジュールをセットアップするスクリプト
# 実行: sudo bash setup_cron.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/daily_report_18.sh"
CRON_D_FILE="/etc/cron.d/daily-report-18"
LOG_FILE="${SCRIPT_DIR}/daily_report_18.log"

echo "=== 日次レポート スケジュールセットアップ ==="
echo "スクリプト: ${SCRIPT_PATH}"
echo ""

# --- 方法1: crontab コマンドが使える場合 ---
if command -v crontab &>/dev/null; then
    echo "[方法1] crontab に登録します..."
    CRON_JOB="0 18 * * 1-5 ${SCRIPT_PATH} >> ${LOG_FILE} 2>&1"
    (crontab -l 2>/dev/null | grep -v "daily_report_18"; echo "${CRON_JOB}") | crontab -
    echo "登録完了:"
    crontab -l | grep "daily_report_18"

# --- 方法2: /etc/cron.d/ に配置する場合 ---
elif [ -d "/etc/cron.d" ]; then
    echo "[方法2] /etc/cron.d/daily-report-18 に配置します..."
    cat > "${CRON_D_FILE}" << EOF
# 日次レポート - 平日18:00 (JST)
SHELL=/bin/bash
PATH=/opt/node22/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 18 * * 1-5 root ${SCRIPT_PATH} >> ${LOG_FILE} 2>&1
EOF
    chmod 644 "${CRON_D_FILE}"
    echo "配置完了: ${CRON_D_FILE}"

# --- 方法3: systemd timer ---
elif command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null 2>&1; then
    echo "[方法3] systemd timer を有効化します..."
    systemctl daemon-reload
    systemctl enable --now daily-report-18.timer
    systemctl list-timers daily-report-18.timer

else
    echo "[エラー] スケジューラが見つかりません。"
    echo ""
    echo "手動セットアップ手順:"
    echo "  Linux: crontab -e を開き以下を追加:"
    echo "    0 18 * * 1-5 ${SCRIPT_PATH} >> ${LOG_FILE} 2>&1"
    echo ""
    echo "  Windows: タスクスケジューラで以下を設定:"
    echo "    スクリプト: daily_report_18.ps1"
    echo "    トリガー: 毎日 18:00、平日のみ"
    exit 1
fi

echo ""
echo "セットアップ完了。次の平日18:00に自動実行されます。"
echo "ログ: ${LOG_FILE}"
