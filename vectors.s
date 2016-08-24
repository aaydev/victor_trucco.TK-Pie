
;@-------------------------------------------------------------------------
;@-------------------------------------------------------------------------

.globl _start
_start:
    ldr pc,reset_handler
    ldr pc,undefined_handler
    ldr pc,swi_handler
    ldr pc,prefetch_handler
    ldr pc,data_handler
    ldr pc,unused_handler
    ldr pc,irq_handler
    ldr pc,fiq_handler
reset_handler:      .word reset
undefined_handler:  .word hang
swi_handler:        .word hang
prefetch_handler:   .word hang
data_handler:       .word hang
unused_handler:     .word hang
irq_handler:        .word irq
fiq_handler:        .word fiq

reset:
    mov r0,#0x8000
    mov r1,#0x0000
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}

    ;@ (PSR_IRQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD2
    msr cpsr_c,r0
    mov sp,#0x8000

    ;@ (PSR_FIQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD1
    msr cpsr_c,r0
    mov sp,#0x4000

    ;@ (PSR_SVC_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD3
    msr cpsr_c,r0
    mov sp,#0x8000000

    ;@ SVC MODE, IRQ ENABLED, FIQ DIS
    ;@mov r0,#0x53
    ;@msr cpsr_c, r0

	;@ ---------- Start L1 Cache
	
	;@ R0 = System Control Register
	mrc p15,0,r0,c1,c0,0 
	
	;@ Data Cache (Bit 2)
	orr r0,#0x0004 
	
	;@ Branch Prediction (Bit 11)
	orr r0,#0x0800 
	
	;@ Instruction Caches (Bit 12)
	orr r0,#0x1000 
	
	;@ System Control Register = R0
	mcr p15,0,r0,c1,c0,0 
	;@ ------------------- 
	
	;@ ---------- Enable VFP
	;@ r1 = Access Control Register
	mrc p15, #0, r1, c1, c0, #2 
	
	;@ enable full access for p10,11
	orr r1, r1, #(0xf << 20) 
	
	;@ Access Control Register = r1
	mcr p15, #0, r1, c1, c0, #2 
	mov r1, #0
	
	;@ flush prefetch buffer because of FMXR below
	mcr p15, #0, r1, c7, c5, #4 

	;@ and CP 10 & 11 were only just enabled
	;@ Enable VFP itself
	mov r0,#0x40000000
	
     fmxr fpexc,r0
	;@ ------------------- 
	
    bl notmain
hang: b hang

.globl PUT32
PUT32:
    str r1,[r0]
    bx lr

.globl PUT16
PUT16:
    strh r1,[r0]
    bx lr

.globl PUT8
PUT8:
    strb r1,[r0]
    bx lr

.globl GET32
GET32:
    ldr r0,[r0]
    bx lr

.globl GETPC
GETPC:
    mov r0,lr
    bx lr

.globl BRANCHTO
BRANCHTO:
    bx r0

.globl dummy
dummy:
    bx lr

.globl enable_irq
enable_irq:
    mrs r0,cpsr
    bic r0,r0,#0x80
    msr cpsr_c,r0
    bx lr

irq:
    push {lr}
    bl c_irq_handler
    pop  {lr}
    subs pc,lr,#4
	
.globl enable_fiq
enable_fiq:
    mrs r0,cpsr
    bic r0,r0,#0x40
    msr cpsr_c,r0
    bx lr

fiq:
    push {r0,r1,r2,r3,lr}
    bl c_fiq_handler
    pop  {r0,r1,r2,r3,lr}
    subs pc,lr,#4


;@-------------------------------------------------------------------------
;@-------------------------------------------------------------------------


;@-------------------------------------------------------------------------
;@
;@ Copyright (c) 2012 David Welch dwelch@dwelch.com
;@
;@ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
;@
;@ The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
;@
;@ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;@
;@-------------------------------------------------------------------------
