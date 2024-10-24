*************************************
**作成者：梶原, 松木
************************************
.include "queue.s"
.section .text


************************************************************************************
**PUTSTRING(ch, p, size)
**入力:チャネルch(%d0.l), 読み込み先の先頭アドレスp(%d2.l), 送信するデータ数size(%d3.l)
**戻り値:実際に送信したデータ数sz(%d0.l)
*************************************************************************************

PUTSTRING:
	movem.l %a0-%a1, -(%sp)
	cmpi.l #0, %d0
	bne    END_PUTSTRING  /*チャネルが０以外のとき何もせずに復帰*/
	lea.l  sz, %a0        /*szが送信したデータ数を保持*/
	move.l #0, (%a0)
	move.l %d2, %a1
	bra    PUT_LOOP


PUT_LOOP:
	cmpi.l #0, %d3
	beq    SET_SIZE       /*sizeが０のときPUTSTRINGを終了*/
	cmp.l  (%a0), %d3
	beq    ANMASK         /*sz = sizeのときアンマスク*/
	move.l #1, %d0        /*送信キューを指定*/
	move.b (%a1), %d1     /*送信するデータを指定*/
	jsr    INQ
	cmpi.l #0, %d0     
	beq    ANMASK         /*INQが失敗のとき*/
	addai.b  #1,  %a1     /*次のバイトに移動*/
	addi.l #1, (%a0)      /*szをインクリメント*/
	bra    LOOP1


ANMASK:
	ori.w #0x2000, 0xFFF900/*アンマスクの実行*/
	

SET_SIZE:
	move.l (%a0), %d0 /*戻り値の設定*/
	
END_PUTSTRING:
	movem.l (%sp)+, %a0-%a1
	rts


.section .data
sz:	.ds.l  1  /*実際に送信したデータ数を保持*/
