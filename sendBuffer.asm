sendBufferAsm:

    push {r4,r5,r6,r7,lr}
    
    mov r4, r0 ; save buff
    mov r6, r1 ; save pin
    
    mov r0, r4
    bl BufferMethods::length
    mov r5, r0
    
    mov r0, r4
    bl BufferMethods::getBytes
    mov r4, r0
    
    ; setup pin as digital
    mov r0, r6
    movs r1, #1
    bl pins::digitalWritePin
    
    ; load pin address
    mov r0, r6
    bl pins::getPinAddress

    ldr r0, [r0, #8] ; get mbed DigitalOut from MicroBitPin
    ldr r1, [r0, #4] ; r1-mask for this pin
    ldr r2, [r0, #16] ; r2-clraddr
    ldr r3, [r0, #12] ; r3-setaddr
    
    cpsid i ; disable irq

    b .sendbyte

.sendbyte:
    ldrb r0, [r4, #0]   ; r0 = *r4
    movs r6, #0x01      ; reset mask
    
.startbit:
    str r1, [r2, #0]    ; pin := lo  C6
    movs r7, 0
    
.delay1:
    adds r7, #1
    cmp r7, #25
    bne .delay1
    b .databit
    
.databit:
    tst r6, r0          ; r6 & r0
    bne .bit1           ; if (r6 & r0 != 0)
    b .bit0             ; else
    
.bit1:
    str r1, [r3, #0]   ; pin := hi
    movs r7, 0
    
.delay2:
    adds r7, #1
    cmp r7, #25
    bne .delay2
    b .nextbit
    
.bit0:
    str r1, [r2, #0]   ; pin := lo
    movs r7, 0
    
.delay3:
    adds r7, #1
    cmp r7, #25
    bne .delay3
    b .nextbit

.nextbit:
    cmp r6, #0x80
    bne .setmask
    b .stopbit
    
.setmask:
    lsls r6, r6, #1    ; r6 <<= 1
    b .databit       ; if (r6 != 0)
    
.stopbit:
    str r1, [r3, #0]   ; pin := hi
    movs r7, 0
    
.delay4:
    adds r7, #1
    cmp r7, #25
    bne .delay4
    
    adds r4, #1         ; r4++       C9
    subs r5, #1         ; r5--       C10
    bcc .stop           ; if (r5<0) goto .stop  C11
    b .sendbyte

.stop:    
    str r1, [r3, #0]   ; pin := hi
    cpsie i            ; enable irq

    pop {r4,r5,r6,r7,pc}
