# bootstrap code
# ben staehle
# 3/20/24

.code16
.org 0x0

.text

.globl _start
.set STACK_TOP, 0x3000

_start:
	# place the stack somewhere in free mem
	cli

	mov  %cs, %ax
	mov  %ax, %ds
	mov  %ax, %es
	mov  %ax, %fs
	mov  %ax, %gs
	mov  %ax, %ss

	movw  $STACK_TOP, %bp
	movw  %bp, %sp

	movb  %dl, drive_num

	sti

	leaw greet_str, %si
	call print

    # wait for user to press a key
	xorb %ah, %ah
	int  $0x16
	call cls
	
	# load kernel at 0x10000
	# kernel code is placed directly after
    # boot loader and start code
	call do_disk_io

	# set the video mode
	# 320 x 200 with 16 colors
	# xorb %ah, %ah
	# movb $0x13, %al
	# int  $0x10

	# enable the a20 line
	cli

	#call  a20_wait0
	#movb  $0xd0, %al
	#outb  $0x64
	#call  a20_wait1
	#xorw  %ax, %ax
	#inb   $0x60

	#pushw %ax
	#call  a20_wait0
	#movb  $0xd1, %al
	#outb  $0x64
	#call  a20_wait0
	#popw  %ax
	#orw   $2, %ax
	#outb  $0x60

	# enable 32 bit protected mode
	movl  %cr0, %eax
	orl   $1, %eax
	movl  %eax, %cr0
	
	# set a GDT and jump to main
	jmp flush_preftch

flush_preftch:
	lidt  idt
	lgdt  gdtp

	# set segments for our shiny new gdt
	movw  $(gdt_kdata - gdt), %ax
	movw  %ax, %ds
	movw  %ax, %es
	movw  %ax, %fs
	movw  %ax, %gs
	movw  %ax, %ss

	# reset out shiny new 32 bit stack pointer
	movl  $0x3000, %ebp
	movl  %ebp, %esp
	ljmp  $0x8, $start32

.code32
start32:
	movl  $0x10000, %eax
	jmpl  *%eax
	jmp   .

.code16
print:
	pusha
print_loop:
	movb  $0x0e, %ah
	lodsb
	cmpb  $0x0, %al
	je    print_done
	int   $0x10
	jmp   print_loop	
print_done:
	popa
	ret

cls:
	pusha
	xorb  %ah,  %ah
	movb  $0x3, %al
	int   $0x10
	popa
	ret

# load (%cx * num_sectors) sectors from the disk into
# 0x10000 using LBA mode - should be plenty for the kernel
do_disk_io:
	pusha
	movw  $20, %cx
	movb  drive_num, %dl
	leaw  dap, %si
	movw  $0x1000, segment
	movw  $1, sector

disk_loop:	
	movb  $0x42, %ah
	int   $0x13
	jc    disk_error
	
	addw  $64, sector
	addw  $0x8000, offset
	jnc   disk_same_seg

	addw  $0x1000, segment
	movw  $0x0000, offset

disk_same_seg:
	loop disk_loop

	popa
	ret

# doesn't return
disk_error:
	call  cls
	leaw  diskerr_str, %si
	call  print
	cli
	jmp   .

a20_wait0:
	xorw  %ax, %ax
	inb   $0x64
	btw   $1, %ax
	jc    a20_wait0
	ret

a20_wait1:
	xorw  %ax, %ax
	inb   $0x64
	btw   $0, %ax
	jc    a20_wait1
	ret

greet_str:   .asciz "Minesweeper Time!\n\r Press a key to boot..."
diskerr_str: .asciz "Disk Error!"

drive_num:   .word 0x0000

# space for a Disk Address Packet
.align 4
dap:
    .byte 0x10
    .byte 0x00
num_sectors:
    .word 0x0040
offset:
    .word 0x0000
segment:
    .word 0x0000
sector:
    .quad 0x00000000
# define the GDT and a pointer to it
# segments are set to page granularity
# and limit set to 0xfffff to give access to
# entire 4 GiB address space
.align 16
gdtp:
	.word gdt_end - gdt - 1
	.long gdt

.align 16
gdt:
	gdt_null: .quad 0
	gdt_kcode:
		.word 0xffff
		.word 0x0000
		.byte 0x00
		.byte 0b10011010
		.byte 0b11001111
		.byte 0x00
	gdt_kdata:
		.word 0xffff
		.word 0x0000
		.byte 0x00
		.byte 0b10010010
		.byte 0b11001111
		.byte 0x00
gdt_end:

# define an empty idt for now
idt:
	.word 0x0000
	.long 0x00000000

.fill 510 - (. - _start), 1 ,0x0

# actually 0x55aa but x86 is little endian :)
.word 0xaa55
