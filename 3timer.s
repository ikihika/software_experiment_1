
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
task_p: 
	.ds.l 0x1 /*大域変数task_pの設定*/
	.even
SYS_STK_TOP: /* システムスタック領域の最後尾 */

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
*	move.l #uart1_interrupt, 0x110 /* UART1割り込みベクタ設定 */

	****************
	** 送受信 (UART1) 関係の変更
	****************
	move.w #0xe100, USTCNT1 /* 送受信可能, パリティなし, 1 stop, 8 bit, */
				/* 受信割り込み許可、送信割り込み許可 */

	****************
	** 割り込みマスクの設定
	****************
	move.l #0x00ffffff, IMR /* UART1(レベル4)＆タイマ割り込み許可 */

	****************
	** 走行レベルの設定
	****************
	move.w #0x2000, %SR /* スーパバイザモード, 割り込み全許可 */


****************
** 割り込みベクタの設定
****************
	move.l #timer_interrupt, 0x118 /* タイマー割り込みベクタ設定 */

***************
** システムコール番号
***************
*	.equ SYSCALL_NUM_GETSTRING, 1
*	.equ SYSCALL_NUM_PUTSTRING, 2
	.equ SYSCALL_NUM_RESET_TIMER, 3
	.equ SYSCALL_NUM_SET_TIMER, 4

****************
** TraP0の設定
****************
	move.l #SYSTEM_CALL, 0x080 /* タイマー割り込みベクタ設定 */
	
	bra MAIN



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
	move.b #'2',LED7
** システムコールによる RESET_TIMER の起動
	move.l #SYSCALL_NUM_RESET_TIMER,%D0
	trap #0
	move.b #'5',LED7
** システムコールによる SET_TIMER の起動
	move.l #SYSCALL_NUM_SET_TIMER, %D0
	move.w #50000, %D1
	move.l #TT, %D2
	trap #0


LOOP:
	move.b #'5',LED3 /*COUNT=0まで待機*/
	bra LOOP

******************************
* タイマのテスト
* ’******’ を表示し改行する．
* ５回実行すると，RESET_TIMER をする．
******************************
TT:
	move.b #'2',LED6
	movem.l %d0-%d7/%a0-%a6,-(%SP)
	cmpi.w #5,TTC | TTC カウンタで 5 回実行したかどうか数える
	beq TTKILL | 5 回実行したら，タイマを止める
*	move.l #SYSCALL_NUM_PUTSTRING,%d0
*	move.l #0, %d1 | ch = 0
*	move.l #TMSG, %d2 | p = #TMSG
*	move.l #8, %d3 | size = 8
*	trap #0

TTKILL:
	move.b #'3',LED5
	move.l #SYSCALL_NUM_RESET_TIMER,%d0
	trap #0
	
TTEND:
	move.b #'4',LED4
	movem.l (%SP)+,%d0-%d7/%a0-%a6
	rts
	
.section .text
.even
timer_interrupt:
	movem.l %d0-%d7/%a0-%a6, -(%sp)/*レジスタ退避*/

	move.w  TSTAT1, %d0
	btst #0, %d0
	beq end_interrupt

	move.w #0x0000, TSTAT1
	jsr CALL_RP

end_interrupt:
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
	move.w #0x0004, TCTL1
	move.b #'7',LED7
	rts

SET_TIMER:
	movem.l %d1-%d2/%a0, -(%sp)
	lea.l task_p, %a0
	move.l %d2, (%a0)
	move.w #0x00ce, TPRER1
	move.w %d1, TCMP1
	move.w #0x0015, TCTL1
	movem.l (%sp)+,%d1-%d2/%a0
	rts

CALL_RP:
	movem.l %a0, -(%sp)
	movea.l task_p, %a0
	jmp (%a0)
	movem.l (%sp)+, %a0
	rts

************
*systemcall
***********
SYSTEM_CALL:
	move.b #'3',LED7
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
	move.b #'4',LED7
	jsr (%a0)
	move.b #'6',LED7
	movem.l (%sp)+,%a0
	rte	
