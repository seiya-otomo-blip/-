#!/bin/bash
# Slackの返信漏れを毎朝チェックし、seiya-otomoへDMで通知するスクリプト

export PATH="/opt/node22/bin:$PATH"

claude -p "
あなたはSlackの返信漏れチェックアシスタントです。以下の手順を実行してください。

1. Slackで @seiya-otomo (user_id: U01SC3UBKMX) 宛に来たメッセージのうち、直近2週間で返信漏れがないか確認する
   - 検索クエリ: 'to:<@U01SC3UBKMX> after:AFTER_DATE' (今日から14日前の日付)
   - チャンネルメンション: '<@U01SC3UBKMX> after:AFTER_DATE' (今日から7日前)
   - 各会話の最後のメッセージがseiya-otomo以外からのもので、返信が必要そうかを判断する
   - スレッドも必要に応じて確認する

2. 返信漏れが見つかった場合、seiya-otomo本人(U01SC3UBKMX)へSlack DMで以下の形式で通知する:
   【返信漏れチェック結果】本日 $(date '+%Y/%m/%d') 9:00

   ⚠️ 返信漏れが N 件あります

   1. [チャンネル/DM名] 送信者: メッセージ概要 (日時)
      リンク: ...

   2. ...

3. 返信漏れが見つからなかった場合も、seiya-otomoへ以下をDMする:
   【返信漏れチェック結果】本日 $(date '+%Y/%m/%d') 9:00
   ✅ 返信漏れはありません！

必ず最後にSlack DMを送信すること。
" \
  --allowedTools "mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_public_and_private,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_thread,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_send_message,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_search_users,mcp__e59ce691-91d7-47bc-a81b-1f5cc340e15a__slack_read_channel" \
  --output-format text \
  2>&1 | tee -a /home/user/-/slack_reply_check.log
