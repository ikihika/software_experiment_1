***************************************************************
** システムコールインタフェース
** システムコール番号 → %D0.L
** システムコールの引数 → %D1 以降
** 呼び出し例
** move.l 1, %D0    | GETSTRING
** move.l #0, %D1   | ch = 0
** move.l #BUF, %D2 | p = #BUF
** move.l #256, %D3 | size = 256
** trap #0
***************************************************************
.section .text
.even

system_call_interface:
	move.l %D0, %D7        /* システムコール番号を %D7 に退避 */

	cmpi.l #1, %D0         /* システムコール番号が 1 (GETSTRING) か確認 */
	beq call_getstring     /* GETSTRING へジャンプ */

	cmpi.l #2, %D0         /* システムコール番号が 2 (PUTSTRING) か確認 */
	beq call_putstring     /* PUTSTRING へジャンプ */

	cmpi.l #3, %D0         /* システムコール番号が 3 (RESET_TIMER) か確認 */
	beq call_reset_timer   /* RESET_TIMERへジャンプ */

	cmpi.l #4, %D0         /* システムコール番号が 3 (SET_TIMER) か確認 */
	beq call_set_timer     /* SET_TIMERへジャンプ */

	bra error_call         /* 無効なシステムコールの場合 */

call_getstring:
    /* GETSTRINGの処理 */
	jsr GETSTRING          /* GETSTRING の処理ルーチンにジャンプ */
	bra return_to_user     /* ユーザプログラムに戻る */

call_putstring:
    /* PUTSTRINGの処理 */
	jsr PUTSTRING          /* PUTSTRING の処理ルーチンにジャンプ */
	bra return_to_user     /* ユーザプログラムに戻る */

call_reset_timer:
    /* RESET_TIMERの処理 */
	jsr RESET_TIMER        /* その他のシステムコールの処理ルーチンにジャンプ */
	bra return_to_user     /* ユーザプログラムに戻る */

call_set_timer:
    /* SET_TIMERの処理 */
	jsr SET_TIMER          /* その他のシステムコールの処理ルーチンにジャンプ */
	bra return_to_user     /* ユーザプログラムに戻る */

error_call:
    /* 無効なシステムコール番号に対するエラーハンドリング */
	move.l #-1, %D0        /* エラーコードを %D0 にセット (例: -1) */
	bra return_to_user     /* ユーザプログラムに戻る */

return_to_user:
	rte                    /* 割り込み処理終了、元のプログラムに戻る */
