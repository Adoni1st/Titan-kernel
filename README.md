# Titan Kernel

Hi, I'm Adoniyas, a high school student. This project is the result of my exploration into how computers really work, from the boot process to the kernel.

The kernel has no applicable functionality; however,it serves as a proof of concept that demonstrates bootstrapping, CPU mode switching,and basic hardware interaction. It implements a VGA text mode driver that writes directly to memory-mapped I/O at 0xB8000, supports clearing the screen, printing characters and strings, and handling control characters (\n, \r, \t).

Resources I mainly relied on:
    "Writing a Simple Operating System — from Scratch" by Nick Blundell, 
    OsDev Wiki: https://wiki.osdev.org/Expanded_Main_Page, 
    Youtube: https://www.youtube.com/@olivestemlearning, 
    Youtube: https://www.youtube.com/@dragonzapeducation, 

Verified booting successfully in QEMU, producing:

```
Welcome to Titan Kernel!
32-bit Protected Mode
Kernel loaded successfully!

This kernel is written in C and built with GCC and NASM by Adoniyas
```


Through out development, I have tried to mark the essential technical concepts I learned. I have listed them below in chronological order.



    How to use ram with assembly.

    The order of input entry to functions through registers (RDI, RSI, RDX, RCX, R8, R9).

    GAS with intel syntax was messy and difficult to keep track of, so I switched to nasm.

    All arithmetic operations, and how to handle overflows/carries.

    How to implement logics and their uses.

    Shifting and its uses.

    Comparison, loops and conditional jumping.

    How to interact with C functions inside assembly code, both custom and standard library ones.

    The main differences in assembly code of 64-bit and 32-bit assembly (the data entry (stack vs registers), the syscall rules (int 80h vs syscall), and more).

    How to make a simple bootloader.

    The syntax of makefiles and assembled my bootloader using it.

    How to print a string from the bootloader by using a different interrupt from usual (experimented with the results in QEMU).

    How hard disk is structured and how it is used by the OS (CHS and LBA). Used the terminology to briefly understand SSD.

    How to convert CHS to LBA and vice versa.

    About the FAT12 (a file system for floppy disks).

    To create a virtual floppy disk, format it with FAT12, and how to load my boot loader into it.

    How to load the kernel into the FAT12 with a bootloader.

    To read from disk in BIOS using BIOS interrupts.

    How to parse the root directory to find a file by name.

    How VGA text mode works (hardware memory mapped at 0xB8000).

    How to clear the screen.

    Cursor management (X/Y positioning, scrolling).

    The difference between video_putchar() handling normal chars vs control chars (\n, \r, \t).

    How to implement a simple scroll mechanism when cursor exceeds screen height.

    About A20 gate and its use.

    About the Global Descriptor Table (GDT) and its role in protected mode.

    The structure of GDT entries.

    How to define code (0x08) and data (0x0A) segments in the GDT.

    About multi-stage boot loading.

    The difference in memory limit of 16-bit real mode and 32-bit protected mode.




# How it boots, stage by stage

*BIOS → Stage 1 (`bootloader.asm`, loaded at `0x7C00`)*
The BIOS loads sector 0 of the floppy to `0x7C00` and jumps to it. This sector contains a standard FAT12 BIOS Parameter Block (BPB) used
for the disk to be a valid FAT12 volume 

1. Sets up the segments.
2. Loads the FAT12 root directory  into a scratch buffer.
3. Linearly scans the 32-byte directory entries for the 11-byte padded name `STAGE2  BIN`.
4. Reads that entry's first cluster number (offset 26) and follows the FAT12 cluster chain to load the full file to `0x0000:0x7E00`.
5. Jumps to `0x0000:0x7E00`.

**Stage 2 (`stage2.asm`, loaded at `0x7E00`)**
Still 16-bit real mode. Repeats the same FAT12 walk to find and load
`KERNEL.BIN`, this time into a temporary buffer at `0x10000`,because offset addressing can't reach `0x100000` directly without extra tricks. 

Then:
1. Enables the A20 line via the BIOS (`int 0x15, ax=0x2401`) so memory above 1MB is actually addressable.
2. Loads a flat GDT.
3. Sets the PE bit in `CR0` and far-jumps into 32-bit code.
4. In protected mode: sets up data segments and a stack at `0x90000`,
   copies the kernel image from `0x10000` up to its real load address
   `0x100000`, and calls into it.

**Kernel (`kernel.c`, linked to run at `0x100000`)**
`kernel.ld` places a `.text.boot` section at the very start of the image, so the flat binary produced by `objcopy` begins with `_start` at byte 0 (i.e. address `0x100000`). This lets stage2 jump straight to `0x100000` without needing any ELF/symbol information. 

`_start` calls `kernel_main()`, which initializes the VGA
driver and prints the banner in a few different colors, then both
functions fall into a `hlt` loop.

`video.c` implements a simple driver over the memory-mapped VGA text
buffer at `0xB8000` (80x25, one `uint16_t` per cell: low byte is the
character, high byte is the fg/bg color attribute), with scrolling and `\n`/`\r`/`\t` handling.

