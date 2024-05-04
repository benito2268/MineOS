# kernel entry point
.code32
.section .text.prologue

.set STACK_CANARY, 0x1badf00d

.globl _start
_start:
	leal  stack, %esp
	movl  $STACK_CANARY, %eax
	pushl %esp
	pushl %eax	
	call  kmain

.align 16
.long STACK_CANARY
stack_top:
	.skip 0x4000
stack:

