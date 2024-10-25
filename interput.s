***************************************
**作成者：梶原、松木
**コーディング：梶原、チェック：松木
**************************************
.include "queue.s"
.section .text

**********************************
**INTERPUT(ch)
**入力:チャネルch(%d1.L)
**戻り値:なし
*********************************	
INTERPUT:
	move.l %d0, -(%sp) /*スタック退避*/
	move.w #0x2700, %SR /*走行レベルを7に設定*/
	cmpi.l #0, %d1
	bne    END_INTERPUT /*チャネルが０以外のとき何もせずに復帰*/
	move.l #1, %d0      /*送信キューを選択*/
	jsr    OUTQ         /*OUTQを実行*/
	cmpi.b #0, %d0
	beq    MASK         /*キューが空のときマスクを実行*/
	addi.w  #0x0800, %d1/*上位8bitのヘッダ付与*/
	move.w  %d1, UTX1   /*UTX1にデータ送信*/
	bra    END_INTERPUT

MASK:
	andi.w #0xFFFB, USTCNT1 /*送信割り込みの禁止*/


END_INTERPUT:
	move.l (%sp)+, %d0 
	rts
