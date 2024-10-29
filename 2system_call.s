*	.include "putstring.s"
*	.include "getstring.s"
	.include "timer.s"
	.section .text

**trap0の遷移先を設定しないと使えないよ**
	
***************************************************************
** 呼び出すべきシステムコールを，%D0 (システムコール番号 1-4 を格納) を用いて判別する。
** 目的のシステムコールを呼び出す。
** 入力：システムコール番号 → %D0.L
** 戻り値：システムコール呼び出しの結果 → %D0.L
**************************************************************
SYSTEM_CALL:
	movem.l %a0, -(%sp)
	
*	lea.l GET_STRING, %a0
	subi.l #1,%d0
	beq CALL_Finish

*	lea.l PUT_STRING, %a0
	subi.l #1,%d0
	beq CALL_Finish
	
	lea.l RESET_TIMER, %a0
	subi.l #1,%d0
	beq CALL_Finish

	lea.l SET_TIMER, %a0

CALL_Finish:
	jmp (%a0)
	movem.l (%sp)+,%a0
	rte

	
	
