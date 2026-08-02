#include "video.h"

void kernel_main(void);

__attribute__((section(".text.boot")))
void _start(void) {
    kernel_main();
    for (;;) {
        __asm__ volatile("hlt");
    }
}

void kernel_main(void) {
    video_init();

    video_set_color(VGA_COLOR_LIGHT_CYAN, VGA_COLOR_BLACK);
    video_write("Welcome to Titan Kernel!\n");

    video_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    video_write("32-bit Protected Mode\n");

    video_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    video_write("Kernel loaded successfully!\n\n");

    video_set_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    video_write("This kernel is written in C and built with GCC and NASM by Adoniyas\n");

    for (;;) {
        __asm__ volatile("hlt");
    }
}
