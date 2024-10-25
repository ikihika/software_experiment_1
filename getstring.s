*****************************
**作成者：松木、梶原
*****************************	
	.include "queue.s"

	.section .text
***********************************************
**チャネルchの受信キューからsizeバイトのデータを取り出しp番地以降にコピーする
**入力：チャネルch(%d1.L)
**	書き込み先の先頭アドレスp(%d2.L)
**	取り出すデータ数size(%d3.L)
**戻り値：じっさいに取り出したデータ数sz(%d0.L)
***********************************************	

PUTSTRING:
	movem.l	%d1-%d4/%a1,-(%sp)	/* レジスタの退避 */
	cmpi.l	#0,%d1
	bne	END_PUTSTRING	/* チャネルが0以外ならEND_PUTSTRINGへ */
	move.l	#0,%d4		/*szの値をレジスタd4に格納 */
	move.l	%d2,%a1		/* pを%a1に格納 */
LOOP:
	cmp.l	%d4,%d3
	beq	Input		/* size=szならInputへ */
	move.l	#0,%d0		/* キュー番号を0に設定 */
	bra	OUTQ
	cmpi.l	#0,%d0
	beq	END_PUTSTRING	/* OUTQの復帰値が0ならEND_PUTSTRINGへ */
	move.l	%d1,(%a1)	/* i番地にdata(OUTQの出力値)をcopy */
	addi.l	#1,%d4		/* sz++ */
	adda.b	#1,%a1		/* i++ */
	bra	LOOP
	
Input:
	move.l	%d4,%d0		/* sz(%d4)の値を%d0に格納 */

END_PUTSTRING:
	movem.l	(%sp)+,%d1-%d4/%a1	/* レジスタの回復 */
	rts
