***********************************
**作成者：梶原、松木
**コーディング：梶原, チェック：松木
************************************
.section .text

start:
    jsr Init_Q
    move.l  #LENGTH, %d4
    move.l  #LENGTH, %d5
    lea.l   Data_to_Que, %a0 
    lea.l   InQ_result, %a1  
    lea.l   Output,   %a2
    lea.l   OutQ_result, %a3

    /* INQを繰り返す */
LOOP1:
    subq.w   #1, %d4
    bcs      LOOP2
    move.b   (%a0)+, %d1   /*入力するデータ*/
    move.w   #1, %d0       /* キュー番号 0 */
    jsr      INQ          /* サブルーチン呼び出し */
    move.l   %d0, (%a1)+
    bra      LOOP1


    /* OUTQを繰り返す */
LOOP2:
    subq.w   #1, %d5
    bcs      End_of_program
    move.w   #1, %d0      /* キュー番号 0 */
    jsr      OUTQ         /* サブルーチン呼び出し */
    move.l   %d0, (%a3)+
    cmp.b    #0, %d0
    beq      LOOP2
    move.b   %d1, (%a2)+
    bra      LOOP2

End_of_program:
    stop     #0x2700

/* キューの初期化 */
Init_Q:
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
    rts

/* キュー番号に応じたポインタ・フラグ・バッファを設定 */
SelectQueue:
    cmp.w   #0, %d0
    beq     UseQueue0
    cmp.w   #1, %d0
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
    rts

/* キュー番号に応じたポインタ・フラグ・バッファを選択して更新する */
UpdateQueuePointers:
    cmp.w   #0, %d0
    beq     UpdateQueue0
    cmp.w   #1, %d0
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
    bls     PUT_BUF_INCREMENT /*終端に達していないときインクリメント*/
    move.l  BF_START, %a2
    movea.l %a2, %a1
    bra     PUT_BUF_STEP1

PUT_BUF_INCREMENT:
    addq.l #1, %a1
	
PUT_BUF_STEP1:
    move.l  %a1, PUT_PTR
    cmpa.l  GET_PTR, %a1
    bne     PUT_BUF_STEP2
    move.b  #0x00, PUT_FLG /*GET_FLG = PUT_FLGのときキューは満杯*/

PUT_BUF_STEP2:
    move.b  #0xff, GET_FLG
    jsr     UpdateQueuePointers
    move.b  #1, %d0  /* 成功したときd0を1にセット */
    bra PUT_BUF_Finish

PUT_BUF_Fail:
    move.l  #0, %d0 /* 失敗したときd0を0にセット */

PUT_BUF_Finish:
    movem.l (%sp)+, %a3-%a1/%d2
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
    cmp.b   #0x00, %d2
    beq     GET_BUF_Fail /* キューが空のとき */
    movea.l GET_PTR, %a1
    move.b  (%a1), %d1
    move.l   BF_END, %a3
    cmpa.l   %a3, %a1
    bls      GET_BUF_INCREMENT /*終端に達していないときインクリメント*/
    move.l   BF_START, %a2
    movea.l  %a2, %a1
    bra      GET_BUF_STEP1	

GET_BUF_INCREMENT:
    addq.l #1, %a1

GET_BUF_STEP1:
    move.l  %a1, GET_PTR
    cmpa.l  PUT_PTR, %a1
    bne     GET_BUF_STEP2  
    move.b  #0x00, GET_FLG /*GET_BUF = PUT_BUFのときキューは空*/

GET_BUF_STEP2:
    move.b  #0xff, PUT_FLG
    jsr     UpdateQueuePointers
    move.l  #1, %d0 /* 成功したときd0を1にセット */
    bra     GET_BUF_Finish 

GET_BUF_Fail:
    move.b  #0, %d0 /* 失敗したときd0を0にセット */

GET_BUF_Finish:
    movem.l (%sp)+, %d2/%a1-%a3
    rts

.section .data
    .equ  B_SIZE,  10
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


.equ   LENGTH,   12 /*キューに入れるデータの個数*/
Data_to_Que:  .dc.b   1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12/*INQで読み込むためのデータ領域*/
Output:       .ds.b  B_SIZE+2 /*OUT_Qの出力先*/
InQ_result:   .ds.l  10  /*INQの戻り値(0 or 1)*/
OutQ_result:  .ds.l  10  /*OUTQの戻り値(0 or 1)*/
.end
