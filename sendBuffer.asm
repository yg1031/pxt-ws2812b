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
    movs r1, #0
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
    ldrb r0, [r4, #0]
    movs r6, r0
    movs r7, #0xF0
    ands r6, r7
    lsrs r6, r6, #3
    movs r7, #0
    str r1, [r3, #0]
    b .delayhigh1
    
.delayhigh1:
    adds r7, #1
    cmp r7, r6
    bne .delayhigh1
    b .outputlow

.outputlow:
    str r1, [r2, #0]    ; pin := lo  C6
    movs r7, #0
    b .delaylow1

.delaylow1:
    adds r7, #1
    cmp r7, #10
    bne .delaylow1
    b .lowbits
    
.lowbits:
    movs r6, r0
    movs r7, #0x0F
    ands r6, r7
    lsls r6, r6, #1    ; r6 <<= 1
    movs r7, #0
    str r1, [r3, #0]   ; pin := hi
    b .delayhigh2
    
.delayhigh2:
    adds r7, #1
    cmp r7, r6         ;
    bne .delayhigh2
    str r1, [r2, #0]    ; pin := lo  C6
    movs r7, #0
    b .delaylow2

.delaylow2:
    adds r7, #1
    cmp r7, #10
    bne .delaylow2
    b .nextbyte

.nextbyte:    
    adds r4, #1         ; r4++       C9
    subs r5, #1         ; r5--       C10
    bcc .stop           ; if (r5<0) goto .stop  C11
    b .sendbyte

.stop:    
    str r1, [r2, #0]   ; pin := lo
    cpsie i            ; enable irq

    pop {r4,r5,r6,r7,pc}
