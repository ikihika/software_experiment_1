uart1_interrupt:
    movem.l %d0-%d7/%a0-%a6, -(%sp)   /* レジスタの退避 */

check_send:
    move.w  UTX1, %d0                 /* UTX1の内容をd0に一時的に保存 */
    btst    #15, %d0                  /* 送信レジスタの15ビット目をチェック */
    beq     check_receive             /* 送信割り込みでなければ受信チェックへ */

    /* 送信割り込みの場合 */
    moveq.l #0, %d1                   /* ch = 0 を設定 */
    jsr     INTERPUT                  /* INTERPUTを呼び出し */
    bra     end_interrupt

check_receive:
    move.w  URX1, %d3                 /* URX1の内容をd0に一時的に保存 */
    move.b  %d3, %d2                  /* d3の下位8bit(データ部分)をd2にコピー */
    btst    #13, %d3                  /* 受信レジスタの13ビット目をチェック */
    beq     end_interrupt             /* 受信割り込みでなければ終了 */

    /* 受信割り込みの場合 */
    moveq.l #0, %d1                   /* ch = 0 を設定 */
    jsr     INTERGET                  /* INTERGETを呼び出し */

end_interrupt:
    movem.l (%sp)+, %d0-%d7/%a0-%a6   /* レジスタの復帰 */
    rte                               /* 割り込みからの復帰 */
