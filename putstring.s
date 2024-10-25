*************************************
**作成者：梶原, 松木
**コーディング：梶原, チェック：松木
************************************
.include "queue.s"
.section .text


************************************************************************************
**PUTSTRING(ch, p, size)
**入力:チャネルch(%d0.l), 読み込み先の先頭アドレスp(%d2.l), 送信するデータ数size(%d3.l)
**戻り値:実際に送信したデータ数sz(%d0.l)
*************************************************************************************

PUTSTRING:
	movem.l %d4/%a0-%a1, -(%sp)
	cmpi.l #0, %d0
	bne    END_PUTSTRING  /*チャネルが０以外のとき何もせずに復帰*/
	move.l #0, (%a0)
	move.l %d2, %a1
	move.l #0, %d4       /*sz(%d4)*/
	bra    PUT_LOOP


PUT_LOOP:
	cmpi.l #0, %d3
	beq    SET_SIZE       /*sizeが０のときPUTSTRINGを終了*/
	cmp.l  %d4, %d3      
	beq    ANMASK         /*sz = sizeのときアンマスク*/
	move.l #1, %d0        /*送信キューを指定*/
	move.b (%a1), %d1     /*送信するデータを指定*/
	jsr    INQ
	cmpi.l #0, %d0     
	beq    ANMASK         /*INQが失敗のとき*/
	addi.l #1, %a1       /*次のバイトに移動*/
	addi.l #1, %d4        /*szをインクリメント*/
	bra    PUT_LOOP


ANMASK:
	ori.w #0x0020, 0xFFF900/*アンマスクの実行*/
	

SET_SIZE:
	move.l %d4, %d0 /*戻り値の設定*/
	
END_PUTSTRING:
	movem.l (%sp)+, %d4/%a0-%a1
	rts

