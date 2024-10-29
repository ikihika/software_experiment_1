*	.include "shokika.s"
	.section .text
***************************************************************
** タイマ割り込みを付加にし、タイマも停止する。
** 入力：なし
** 戻り値：なし
***************************************************************

RESET_TIMER:
	move.w #0x0004, TCTL1
	rts

***************************************************************
** タイマ割り込み時に呼び出すべきルーチンを設定する。
** タイマ割り込み周期 t を設定し，t * 0.1 msec 秒毎に割り込みが発生するようにする。
** タイマ使用を許可し，タイマ割り込みを許可する。
** 入力：タイマ割り込み発生周期 t → %D1.w
**　　　割り込み時に起動するルーチンの先頭アドレス p → %D2.L
** 戻り値：なし
**************************************************************
	
SET_TIMER:
	movem.l %d1-%d2/%a0, -(%sp)
	lea.l task_p, %a0
	move.l %d2, (%a0)
	move.w #0x00ce, TPRER1
	move.w %d1, TCMP1
	move.w #0x0015, TCTL1
	movem.l (%sp)+,%d1-%d2/%a0
	rts

***************************************************************
** タイマ割り込み時に処理すべきルーチンを呼び出す。
** 入力：なし
** 戻り値：なし
**************************************************************
	
CALL_RP:
	movem.l %a0, -(%sp)
	movea.l task_p, %a0
	jmp (%a0)
	movem.l (%sp)+, %a0
	rts
	
*	.section .bss
*task_p:
*	.ds.l 1
*	.even