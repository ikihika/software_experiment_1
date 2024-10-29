**********************************
**作成者：松木、梶原
**コーディング：松木、チェック：梶原	
**********************************	
	.include "queue.s"

	.section .text
***********************************************
**チャネルchの受信キューからsizeバイトのデータを取り出しp番地以降にコピーする
**入力：チャネルch(%d1.L)
**	書き込み先の先頭アドレスp(%d2.L)
**	取り出すデータ数size(%d3.L)
**戻り値：じっさいに取り出したデータ数sz(%d0.L)
	***********************************************


GETSTRING:
	movem.l	%d4/%a1,-(%sp)	/* レジスタの退避 */
	cmpi.l	#0,%d1
	bne	END_GETSTRING	/* チャネルが0以外ならEND_GETSTRINGへ */
	move.l	#0,%d4		/* szの値をレジスタd4に格納 */
	move.l	%d2,%a1		/* pを%a1に格納 */
GET_LOOP:
	cmp.l	%d4,%d3
	beq	Input		/* size=szならInputへ */
	move.l	#0,%d0		/* キュー番号を0に設定 */
	jsr	OUTQ		/* 出力：失敗0/成功1(%d0)、8bitのdata(%d1) */
	cmpi.l	#0,%d0
	beq	Input		/* OUTQの復帰値が0ならInputへ */
	move.l	%d1,(%a1)	/* i番地にdata(OUTQの出力値)をcopy */
	addi.l	#1,%d4		/* sz++ */
	addq.l	#1,%a1		/* i++ */
	bra	GET_LOOP
	
Input:
	move.l	%d4,%d0		/* sz(%d4)の値を%d0に格納 */

END_GETSTRING:
	movem.l	(%sp)+,%d4/%a1	/* レジスタの回復 */
	rts

	
