***************************************************************
** 各種レジスタ定義
***************************************************************
***************
** レジスタ群の先頭
***************
.equ REGBASE, 0xFFF000 /* DMAP を使用．*/
.equ IOBASE, 0x00d00000
	
***************
** 割り込み関係のレジスタ
***************
.equ IVR, REGBASE+0x300 /* 割り込みベクタレジスタ */
.equ IMR, REGBASE+0x304 /* 割り込みマスクレジスタ */
.equ ISR, REGBASE+0x30c /* 割り込みステータスレジスタ */
.equ IPR, REGBASE+0x310 /* 割り込みペンディングレジスタ */

***************
** タイマ関係のレジスタ
***************
.equ TCTL1, REGBASE+0x600 /* タイマ１コントロールレジスタ */
.equ TPRER1, REGBASE+0x602 /* タイマ１プリスケーラレジスタ */
.equ TCMP1, REGBASE+0x604 /* タイマ１コンペアレジスタ */
.equ TCN1, REGBASE+0x608 /* タイマ１カウンタレジスタ */
.equ TSTAT1, REGBASE+0x60a /* タイマ１ステータスレジスタ */

***************
** UART1（送受信）関係のレジスタ
***************
.equ USTCNT1, REGBASE+0x900 /* UART1 ステータス/コントロールレジスタ */
.equ UBAUD1, REGBASE+0x902 /* UART1 ボーコントロールレジスタ */
.equ URX1, REGBASE+0x904 /* UART1 受信レジスタ */
.equ UTX1, REGBASE+0x906 /* UART1 送信レジスタ */

***************
** LED
***************
.equ LED7, IOBASE+0x000002f /* ボード搭載の LED 用レジスタ */
.equ LED6, IOBASE+0x000002d /* 使用法については付録 A.4.3.1 */
.equ LED5, IOBASE+0x000002b
.equ LED4, IOBASE+0x0000029
.equ LED3, IOBASE+0x000003f
.equ LED2, IOBASE+0x000003d
.equ LED1, IOBASE+0x000003b
.equ LED0, IOBASE+0x0000039

***************************************************************
** スタック領域の確保
***************************************************************
.section .bss
.even
SYS_STK:
	.ds.b 0x4000 /* システムスタック領域 */
	.even
SYS_STK_TOP: /* システムスタック領域の最後尾 */

task_p: 
	.ds.l 0x1 /*大域変数task_pの設定*/
	.even


***************************************************************
** 初期化
** 内部デバイスレジスタには特定の値が設定されている．
** その理由を知るには，付録 B にある各レジスタの仕様を参照すること．
***************************************************************
.section .text
.even
boot:
	/* スーパーバイザ & 各種設定を行っている最中の割込禁止 */
	move.w #0x2700,%SR
	lea.l SYS_STK_TOP, %SP /* Set SSP */

	****************
	** 割り込みコントローラの初期化
	****************
	move.b #0x40, IVR /* ユーザ割り込みベクタ番号を */
				/* 0x40+level に設定． */
	move.l #0x00ffffff,IMR /* 全割り込みマスク */

	****************
	** 送受信 (UART1) 関係の初期化 (割り込みレベルは 4 に固定されている)
	****************
	move.w #0x0000, USTCNT1 /* リセット */
	move.w #0xe100, USTCNT1 /* 送受信可能, パリティなし, 1 stop, 8 bit, */
				/* 送受割り込み禁止 */
	move.w #0x0038, UBAUD1 /* baud rate = 230400 bps */

	****************
	** タイマ関係の初期化 (割り込みレベルは 6 に固定されている)
	*****************
	move.w #0x0004, TCTL1 /* restart, 割り込み不可, */
				/* システムクロックの 1/16 を単位として計時， */
	/* タイマ使用停止 */



	
	****************
	** 割り込みベクタの設定
	****************
	move.l #uart1_interrupt, 0x110 /* UART1割り込みベクタ設定 */

	****************
	** 送受信 (UART1) 関係の変更
	****************
	move.w #0xe10c, USTCNT1 /* 送受信可能, パリティなし, 1 stop, 8 bit, */
				/* 受信割り込み許可、送信割り込み許可 */

	****************
	** 割り込みマスクの設定
	****************
	move.l #0x00ffffff, IMR /* UART1(レベル4)＆タイマ割り込み許可 */

	****************
	** 走行レベルの設定
	****************
	move.w #0x2000, %SR /* スーパバイザモード, 割り込み全許可 */
	jsr Init_Q               /* キューの初期化 */	


****************
** 割り込みベクタの設定
****************
	move.l #timer_interrupt, 0x118 /* タイマー割り込みベクタ設定 */
	move.w #0xe10c, USTCNT1
	move.l #0x00ff3ff9, IMR

***************
** システムコール番号
***************
	.equ SYSCALL_NUM_GETSTRING, 1
	.equ SYSCALL_NUM_PUTSTRING, 2
	.equ SYSCALL_NUM_RESET_TIMER, 3
	.equ SYSCALL_NUM_SET_TIMER, 4

****************
** TraP0の設定
****************
	move.l #SYSTEM_CALL, 0x080 /* trap0ベクタ設定 */
	
	bra MAIN


/* キューの初期化 */
Init_Q:
	move.l %a0, -(%sp)
	lea.l   BF0_START, %a0
	move.l  %a0, PUT_PTR0
	move.l  %a0, GET_PTR0
	move.b  #0xff, PUT_FLG0
	move.b  #0x00, GET_FLG0

	lea.l   BF1_START, %a0
	move.l  %a0, PUT_PTR1
	move.l  %a0, GET_PTR1
	move.b  #0xff, PUT_FLG1
	move.b  #0x00, GET_FLG1
	move.l (%sp)+,%a0
	rts

/* キュー番号に応じたポインタ・フラグ・バッファを設定 */
SelectQueue:
	move.l  %a6, -(%sp)
	cmpi.l   #0, %d0
	beq     UseQueue0
	cmpi.l   #1, %d0
	beq     UseQueue1

UseQueue0:
	move.l  PUT_PTR0, PUT_PTR
	move.l  GET_PTR0, GET_PTR
	move.b  PUT_FLG0, PUT_FLG
	move.b  GET_FLG0, GET_FLG
	lea.l   BF0_START, %a6
	move.l  %a6, BF_START
	lea.l   BF0_END, %a6
	move.l  %a6, BF_END
	move.l  (%sp)+, %a6
	rts

UseQueue1:
	move.l  PUT_PTR1, PUT_PTR
	move.l  GET_PTR1, GET_PTR
	move.b  PUT_FLG1, PUT_FLG
	move.b  GET_FLG1, GET_FLG
	lea.l   BF1_START, %a6
	move.l  %a6, BF_START
	lea.l   BF1_END, %a6
	move.l  %a6, BF_END
	move.l  (%sp)+, %a6
	rts

/* キュー番号に応じたポインタ・フラグ・バッファを選択して更新する */
UpdateQueuePointers:
	cmpi.l   #0, %d0
	beq     UpdateQueue0
	cmpi.l   #1, %d0
	beq     UpdateQueue1

UpdateQueue0:
	move.l  PUT_PTR, PUT_PTR0
	move.l  GET_PTR, GET_PTR0
	move.b  PUT_FLG, PUT_FLG0
	move.b  GET_FLG, GET_FLG0
	rts

UpdateQueue1:
	move.l  PUT_PTR, PUT_PTR1
	move.l  GET_PTR, GET_PTR1
	move.b  PUT_FLG, PUT_FLG1
	move.b  GET_FLG, GET_FLG1
	rts

*********************************************************
**InQ(no, data)
**入力:キュー番号no(%d0.L), 書き込む8bitデータdata(%d1.B)
**出力:失敗0/成功1(%d0.L)
**********************************************************
INQ:
	move.w %sr, -(%sp)  /*走行レベルを退避*/
	move.w #0x2700, %SR /*走行レベルを7に設定*/
	jsr SelectQueue
	jsr PUT_BUF
	move.w (%sp)+, %sr /*走行レベルの回復*/
	rts


PUT_BUF:
	movem.l %d2/%a1-%a3, -(%sp) /* スタック退避 */
	move.b  PUT_FLG, %d2
	cmp.b   #0x00, %d2
	beq     PUT_BUF_Fail /* キューが満杯のとき */
	movea.l PUT_PTR, %a1
	move.b  %d1, (%a1)+
	move.l   BF_END, %a3
	cmpa.l  %a3, %a1
	bls     PUT_BUF_STEP1
	move.l   BF_START, %a2
	movea.l %a2, %a1

PUT_BUF_STEP1:
	move.l  %a1, PUT_PTR
	cmpa.l  GET_PTR, %a1
	bne     PUT_BUF_STEP2
	move.b  #0x00, PUT_FLG

PUT_BUF_STEP2:
	move.b  #0xff, GET_FLG
	jsr     UpdateQueuePointers
	move.l  #1, %d0  /* 成功したときd0を1にセット */
	bra PUT_BUF_Finish

PUT_BUF_Fail:
	move.l  #0, %d0 /* 失敗したときd0を0にセット */

PUT_BUF_Finish:
	movem.l (%sp)+, %d2/%a1-%a3
	rts


***********************************************************
**OUTQ(no,data)
**入力:キュー番号no(%d0.L)
**出力:失敗0/成功1(%d0.L), 取り出した8bitデータdata(%d1.B)
**********************************************************
OUTQ:
	move.w  %sr, -(%sp) /*走行レベルの退避*/
	move.w  #0x2700, %SR /*走行レベルを7に設定*/
	jsr SelectQueue
	jsr GET_BUF
	move.w  (%sp)+, %sr /*走行レベルの回復*/
	rts


GET_BUF:
	movem.l %d2/%a1-%a3, -(%sp) /* スタック退避 */
	move.b  GET_FLG, %d2
	cmpi.b   #0x00, %d2
	beq     GET_BUF_Fail /* キューが空のとき */
	movea.l GET_PTR, %a1
	move.b  (%a1), %d1
	move.l   BF_END, %a3
	cmpa.l   %a3, %a1
	bls      GET_BUF_INCREMENT
	move.l   BF_START, %a2
	movea.l  %a2, %a1
	bra GET_BUF_STEP1

GET_BUF_INCREMENT:
	addq.l #1,%a1
	bra GET_BUF_STEP1

GET_BUF_STEP1:
	move.l  %a1, GET_PTR
	cmpa.l  PUT_PTR, %a1
	bne     GET_BUF_STEP2
	move.b  #0x00, GET_FLG

GET_BUF_STEP2:
	move.b  #0xff, PUT_FLG
	jsr     UpdateQueuePointers
	move.l  #1, %d0 /* 成功したときd0を1にセット */
	bra     GET_BUF_Finish 

GET_BUF_Fail:
	move.l  #0, %d0 /* 失敗したときd0を0にセット */
GET_BUF_Finish:
	movem.l (%sp)+, %d2/%a1-%a3
	rts

.section .data
.even
.equ  B_SIZE,  256
	
/*受信用のキュー*/
BF0_START:  .ds.b  B_SIZE-1
BF0_END:    .ds.b  1
PUT_PTR0:   .ds.l  1
GET_PTR0:   .ds.l  1
PUT_FLG0:   .ds.b  1
GET_FLG0:   .ds.b  1

/*送信用のキュー*/
BF1_START:  .ds.b  B_SIZE-1
BF1_END:    .ds.b  1
PUT_PTR1:   .ds.l  1
GET_PTR1:   .ds.l  1
PUT_FLG1:   .ds.b  1
GET_FLG1:   .ds.b  1

PUT_PTR:    .ds.l  1  /* 共通ポインタ */
GET_PTR:    .ds.l  1  /* 共通ポインタ */
PUT_FLG:    .ds.b  1  /* 共通フラグ */
GET_FLG:    .ds.b  1  /* 共通フラグ */
BF_START:   .ds.l  1  /* バッファ開始ポインタ */
BF_END:     .ds.l  1  /* バッファ終了ポインタ */


***************************************************************
** 現段階での初期化ルーチンの正常動作を確認するため，最後に ’a’ を
** 送信レジスタ UTX1 に書き込む．’a’ が出力されれば，OK.
***************************************************************
.section .text
.even
MAIN:
	move.b #'1',LED7
	
** 走行モードとレベルの設定 (「ユーザモード」への移行処理)
	move.w #0x0000, %SR | USER MODE, LEVEL 0
	lea.l USR_STK_TOP,%SP | user stack の設定
** システムコールによる RESET_TIMER の起動
	move.l #SYSCALL_NUM_RESET_TIMER,%D0
	trap #0
** システムコールによる SET_TIMER の起動
	move.l #SYSCALL_NUM_SET_TIMER, %D0
	move.w #50000, %D1
	move.l #TT, %D2
	trap #0

******************************
* sys_GETSTRING, sys_PUTSTRING のテスト
* ターミナルの入力をエコーバックする
******************************
LOOP:
	
	move.l #SYSCALL_NUM_GETSTRING, %D0
	move.l #0, %D1 | ch = 0
	move.l #BUF, %D2 | p = #BUF
	move.l #256, %D3 | size = 256
	trap #0
	
	move.l %D0, %D3 | size = %D0 (length of given string)
	move.l #SYSCALL_NUM_PUTSTRING, %D0
	move.l #0, %D1 | ch = 0
	move.l #BUF,%D2 | p = #BUF
	trap #0

	move.b #'4',LED4
	
	bra LOOP

******************************
* タイマのテスト
* ’******’ を表示し改行する．
* ５回実行すると，RESET_TIMER をする．
******************************
TT:
	move.b #'5',LED3
	movem.l %d0-%d7/%a0-%a6,-(%SP)
	cmpi.w #5,TTC | TTC カウンタで 5 回実行したかどうか数える
	beq TTKILL | 5 回実行したら，タイマを止める
	move.l #SYSCALL_NUM_PUTSTRING,%d0
	move.l #0, %d1 | ch = 0
	move.l #TMSG, %d2 | p = #TMSG
	move.l #8, %d3 | size = 8
	trap #0
	addi.w #1,TTC | TTC カウンタを 1 つ増やして戻る
	bra TTEND

TTKILL:
	move.b #'7',LED1
	move.l #SYSCALL_NUM_RESET_TIMER,%d0
	trap #0
	
TTEND:
	move.b #'6',LED2
	movem.l (%SP)+,%d0-%d7/%a0-%a6
	rts
	
.section .text
.even
uart1_interrupt:
	movem.l %d0-%d5/%a0-%a6, -(%sp)   /* レジスタの退避 */

	
	

check_send:
	move.w  UTX1, %d0                 /* UTX1の内容をd0に一時的に保存 */
	andi.w #0x8000,%d0                  /* 送信レジスタの15ビット目をチェック */
	cmpi.w #0x8000,%d0
	bne    check_receive             /* 送信割り込みでなければ受信チェックへ */

	/* 送信割り込みの場合 */

	moveq.l #0, %d1                   /* ch = 0 を設定 */
	jsr     INTERPUT                  /* INTERPUTを呼び出し */

check_receive:
	move.w  URX1, %d3                 /* URX1の内容をd3に一時的に保存 */
	move.b  %d3, %d2                  /* d3の下位8bit(データ部分)をd2にコピー */
	andi.w #0x2000,%d3		  /* 受信レジスタの13ビット目をチェック */
	cmpi.w #0x2000,%d3
	bne     end_interrupt             /* 受信割り込みでなければ終了 */
	

	/* 受信割り込みの場合 */
	moveq.l #0, %d1 /* ch = 0 を設定 */
	jsr     INTERGET                  /* INTERGETを呼び出し */

end_interrupt:
	movem.l (%sp)+, %d0-%d5/%a0-%a6   /* レジスタの復帰 */
	rte                               /* 割り込みからの復帰 */

.section .text
.even
timer_interrupt:
	move.b #'8',LED1
	movem.l %d0-%d7/%a0-%a6, -(%sp)/*レジスタ退避*/

	move.w TSTAT1, %d0
	andi.w #0x0001,%d0                  
	cmpi.w #0x0001,%d0
	bne  end_interrupt1

	move.l #0x00000000, TSTAT1
	jsr CALL_RP

end_interrupt1:
	movem.l (%sp)+, %d0-%d7/%a0-%a6/*レジスタ回復*/
	rte

****************************************************************
*** 初期値のあるデータ領域
****************************************************************
.section .data
TMSG:
	.ascii "******\r\n" | \r: 行頭へ (キャリッジリターン)
	.even | \n: 次の行へ (ラインフィード)
TTC:
	.dc.w 0
	.even	

****************************************************************
*** 初期値の無いデータ領域
****************************************************************
.section .bss
BUF:
	.ds.b 256 | BUF[256]
	.even
USR_STK:
	.ds.b 0x4000 | ユーザスタック領域
	.even
USR_STK_TOP: | ユーザスタック領域の最後尾

*******
**timer
*******
	.section .text

RESET_TIMER:
	move.b #'2',LED6
	move.w #0x0004, TCTL1
	rts

SET_TIMER:
	move.b #'3',LED5 
	move.l %d2, task_p
	move.w #0x00ce, TPRER1
	move.w %d1, TCMP1
	move.w #0x0015, TCTL1
	rts

CALL_RP:
	movem.l %a0, -(%sp)
	move.b #'8',LED0
	move.l task_p, %a0
	jsr (%a0)
	move.b #'9',LED0
	movem.l (%sp)+, %a0
	rts

************
*systemcall
***********
SYSTEM_CALL:
	movem.l %a0, -(%sp)
	
	lea.l GETSTRING, %a0
	cmpi.l #1,%d0
	beq CALL_Finish

	lea.l PUTSTRING, %a0
	cmpi.l #2,%d0
	beq CALL_Finish
	
	lea.l RESET_TIMER, %a0
	cmpi.l #3,%d0
	beq CALL_Finish

	lea.l SET_TIMER, %a0

CALL_Finish:
	jsr (%a0)
	movem.l (%sp)+,%a0
	rte

	
*********************************
**INTERPUT(ch)
**入力:チャネルch(%d1.L)
**戻り値:なし
*********************************	
INTERPUT:
	move.l %d0, -(%sp) /*スタック退避*/
	move.w %sr, -(%sp)
	move.w #0x2700, %SR /*走行レベルを7に設定*/
	cmpi.l #0, %d1
	bne    END_INTERPUT /*チャネルが０以外のとき何もせずに復帰*/
	move.l #1, %d0      /*送信キューを選択*/
	jsr    OUTQ         /*OUTQを実行*/
	cmpi.l #0, %d0
	beq    MASK         /*キューが空のときマスクを実行*/
	andi.w #0x00ff,%d1
	addi.w #0x800,%d1
	move.w  %d1, UTX1/*上位8bitのヘッダ付与*/
	bra    END_INTERPUT

MASK:
	addq.b #1,%d6
	andi.b #0x0f,%d6
	andi.w #0xfffb, USTCNT1 /*送信割り込みの禁止*/

END_INTERPUT:
	move.w (%sp)+, %sr
	move.l (%sp)+, %d0
	rts


*************************************
**作成者：梶原, 松木
**コーディング：梶原, チェック：松木
************************************
.section .text
.even
************************************************************************************
**PUTSTRING(ch, p, size)
**入力:チャネルch(%d0.l), 読み込み先の先頭アドレスp(%d2.l), 送信するデータ数size(%d3.l)
**戻り値:実際に送信したデータ数sz(%d0.l)
*************************************************************************************

PUTSTRING:
	movem.l %d4/%a1, -(%sp)
	cmpi.l #0, %d1
	bne    END_PUTSTRING  /*チャネルが０以外のとき何もせずに復帰*/
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
	addq.l #1, %a1       /*次のバイトに移動*/
	addi.l #1, %d4        /*szをインクリメント*/
	bra    PUT_LOOP


ANMASK:
	ori.w #0x0004, USTCNT1/*アンマスクの実行*/
	

SET_SIZE:
	move.l %d4, %d0 /*戻り値の設定*/
	
END_PUTSTRING:
	movem.l (%sp)+, %d4/%a1
	rts

*************************************************
**受信データを受信キューに格納する
**入力：チャネルch(%d1.l)
**      受信データdata(%d2.b)
**出力：なし
*************************************************

INTERGET:
        cmpi.l  #0,%d1		/* ch≠0ならなにもせず復帰 */
        bne     END_INTERGET
        move.b  %d2,%d1		/* INQの入力d1に受信データを格納 */
	move.l	#0,%d0		/* キュー番号を0にする */
        jsr     INQ

END_INTERGET:
        rts


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
	move.b	%d1,(%a1)	/* i番地にdata(OUTQの出力値)をcopy */
	addi.l	#1,%d4		/* sz++ */
	addq.l	#1,%a1		/* i++ */
	bra	GET_LOOP
	
Input:
	move.l	%d4,%d0		/* sz(%d4)の値を%d0に格納 */

END_GETSTRING:
	movem.l	(%sp)+,%d4/%a1	/* レジスタの回復 */
	rts
