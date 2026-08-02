BUILD_DIR   := build
SRC_DIR     := src

ASM         := nasm
CC          := gcc
LD          := ld
OBJCOPY     := objcopy

CFLAGS      := -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib \
               -Wall -Wextra -O2 -std=gnu11
LDFLAGS     := -m elf_i386 -nostdlib -T $(SRC_DIR)/kernel/kernel.ld

IMG         := $(BUILD_DIR)/main.img

.PHONY: all clean run

all: $(IMG)

$(BUILD_DIR)/bootloader.bin: $(SRC_DIR)/bootloader/bootloader.asm | $(BUILD_DIR)
	$(ASM) -f bin $< -o $@

$(BUILD_DIR)/stage2.bin: $(SRC_DIR)/kernel/stage2.asm | $(BUILD_DIR)
	$(ASM) -f bin $< -o $@

$(BUILD_DIR)/kernel.o: $(SRC_DIR)/kernel/kernel.c $(SRC_DIR)/kernel/video.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/video.o: $(SRC_DIR)/kernel/video.c $(SRC_DIR)/kernel/video.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/kernel.elf: $(BUILD_DIR)/kernel.o $(BUILD_DIR)/video.o $(SRC_DIR)/kernel/kernel.ld
	$(LD) $(LDFLAGS) -o $@ $(BUILD_DIR)/kernel.o $(BUILD_DIR)/video.o

$(BUILD_DIR)/kernel.bin: $(BUILD_DIR)/kernel.elf
	$(OBJCOPY) -O binary $< $@

$(IMG): $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/kernel.bin
	dd if=/dev/zero of=$(IMG) bs=512 count=2880 status=none
	mkfs.fat -F 12 -n "TITANOS" $(IMG) > /dev/null
	dd if=$(BUILD_DIR)/bootloader.bin of=$(IMG) bs=512 count=1 conv=notrunc status=none
	mcopy -i $(IMG) $(BUILD_DIR)/stage2.bin "::STAGE2.BIN"
	mcopy -i $(IMG) $(BUILD_DIR)/kernel.bin "::KERNEL.BIN"
	@echo "Built $(IMG)"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

run: $(IMG)
	qemu-system-i386 -fda $(IMG)

clean:
	rm -rf $(BUILD_DIR)
