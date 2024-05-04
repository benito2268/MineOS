#compiler tools
TARGET = MineOS.bin
BOOT   = boot.bin
ISO    = MineOS.iso

CCDIR = ~/opt/cross/bin

CC = $(CCDIR)/i686-elf-gcc
LD = $(CCDIR)/i686-elf-ld
AS = $(CCDIR)/i686-elf-as

CFLAGS = -ffreestanding -O2 -g -nostdlib -fno-pie -fno-stack-protector
LDFLAGS = -Tldscript.ld -nostdlib
BOOTFLAGS = --oformat=binary -Ttext 0x7c00 -nostdlib
ASFLAGS =

BOOTFILES = boot.S
CFILES = $(wildcard *.c)
ASMFILES = $(filter-out $(BOOTFILES), $(wildcard *.S))

OBJS = $(CFILES:.c=.o) $(ASMFILES:.S=.o)
BOOTOBJS = $(BOOTFILES:.S=.o)

all: $(TARGET)

.PHONY: clean qemu-mon-connect

%.o: %.S
	$(AS) $(ASFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BOOT): $(BOOTOBJS)
	$(LD) $(BOOTFLAGS) -o $@ $^

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

iso: $(TARGET) $(BOOT)
	dd if=/dev/zero of=MineOS.iso bs=512 count=2880
	dd if=$(BOOT) of=MineOS.iso conv=notrunc bs=512 seek=0 count=1
	dd if=$(TARGET) of=MineOS.iso conv=notrunc bs=512 seek=1 count=2048

qemu-nox: $(TARGET)
	qemu-system-i386 -drive format=raw,file=$(ISO) --monitor stdio -nographic

qemu: $(TARGET)
	qemu-system-i386 --monitor stdio $(ISO)

qemu-mon-connect:
	socat -,echo=0,icanon=0 unix-connect:qemu-monitor-socket	

clean:
	rm *.o
	rm *iso
	rm $(TARGET)
	rm $(BOOT)
