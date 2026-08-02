To run the kernel, you have to be on a Linux operating system.

I recommend not using your real hardware to run the kernel, instead use QEMU.

You can either,
1. use the already-built disk image and emulate it using QEMU (recommended)
2. build the disk image yourself after installing all the dependencies, then use QEMU.

## When running the commands, you have to be inside the "Titan Kernel" directory

---

## For the first option (run the prebuilt image):

You still need `qemu-system-x86` and `make` installed, even though nothing
needs to be compiled.

## Ubuntu/Debian
sudo apt install qemu-system-x86 make

make run

## Fedora/RHEL
sudo dnf install qemu-system-x86 make

make run

## Arch Linux
sudo pacman -S qemu-system-x86 make

make run

---

## For the second option (build from source):

No cross-compiler is required for this project. The kernel is built with
your system's regular `gcc` using `-m32 -ffreestanding -nostdlib` and a
custom linker script, then converted to a flat binary with `objcopy`. You
just need 32-bit compilation support enabled, plus `nasm` for the
bootloader/stage2 assembly and `dosfstools`/`mtools` to build the FAT12
floppy image.

## Ubuntu/Debian

First command,

sudo apt install nasm gcc-multilib dosfstools mtools qemu-system-x86 make

Second command,

make clean
make all

Final command,

make run


## Fedora/RHEL

First command,

sudo dnf install nasm glibc-devel.i686 dosfstools mtools qemu-system-x86 make gcc

Second command,

make clean
make all

Final command,

make run


## Arch Linux

Arch's system gcc can already target 32-bit, but it needs the multilib
repository enabled (uncomment the [multilib] section in
/etc/pacman.conf, then `sudo pacman -Sy`) so lib32-glibc is installable.

First command,

sudo pacman -S nasm dosfstools mtools qemu-system-x86 make gcc lib32-glibc

Second command,

make clean
make all

Final command,

make run

---

