.include "queue.s"
.section .text

**********************************
**INTERPUT(ch)
**入力:チャネルch(%d0.L)
**戻り値:なし
*********************************	
INTERPUT:
	move.l %d0, -(%sp) /*スタック退避*/
	move.w 0x2700, %SR /*走行レベルを7に設定*/
	cmpi.b #0, %d1
	bne    END_INTERPUT /*チャネルが０以外のとき何もせずに復帰*/
	move.b #1, %d0      /*送信キューを選択*/
	jsr    OUTQ         /*OUTQを実行*/
	cmpi.b #0, %d0
	beq    MASK         /*キューが空のときマスクを実行*/
	move.b %d1, 0xFFF906 /*UTX1*にキューのデータを送信*/
	ori.w  #0x8400, 0xFFF906/*上位8bitのヘッダ付与*/
	bra    END_INTERPUT

MASK:
	andi.w #0xDFFF, 0xFFF900 /*送信割り込みの禁止*/


END_INTERPUT:
	move.l (%sp)+, %d0 
	rts
