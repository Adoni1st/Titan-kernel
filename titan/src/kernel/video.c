#include "video.h"

#define VGA_MEMORY   ((uint16_t *)0xB8000)
#define VGA_WIDTH    80
#define VGA_HEIGHT   25

static uint16_t *const vga_buffer = VGA_MEMORY;
static uint8_t vga_row;
static uint8_t vga_col;
static uint8_t vga_color;

static inline uint16_t vga_entry(char c, uint8_t color) {
    return (uint16_t)(uint8_t)c | ((uint16_t)color << 8);
}

static inline uint8_t vga_make_color(vga_color_t fg, vga_color_t bg) {
    return (uint8_t)fg | ((uint8_t)bg << 4);
}

static void video_scroll(void) {
    for (uint8_t y = 1; y < VGA_HEIGHT; y++) {
        for (uint8_t x = 0; x < VGA_WIDTH; x++) {
            vga_buffer[(y - 1) * VGA_WIDTH + x] = vga_buffer[y * VGA_WIDTH + x];
        }
    }
    for (uint8_t x = 0; x < VGA_WIDTH; x++) {
        vga_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = vga_entry(' ', vga_color);
    }
    vga_row = VGA_HEIGHT - 1;
}

void video_init(void) {
    vga_row = 0;
    vga_col = 0;
    vga_color = vga_make_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    video_clear();
}

void video_clear(void) {
    for (uint16_t y = 0; y < VGA_HEIGHT; y++) {
        for (uint16_t x = 0; x < VGA_WIDTH; x++) {
            vga_buffer[y * VGA_WIDTH + x] = vga_entry(' ', vga_color);
        }
    }
    vga_row = 0;
    vga_col = 0;
}

void video_set_color(vga_color_t fg, vga_color_t bg) {
    vga_color = vga_make_color(fg, bg);
}

static void video_newline(void) {
    vga_col = 0;
    vga_row++;
    if (vga_row >= VGA_HEIGHT) {
        video_scroll();
    }
}

void video_putchar(char c) {
    switch (c) {
        case '\n':
            video_newline();
            return;
        case '\r':
            vga_col = 0;
            return;
        case '\t':
            for (int i = 0; i < 4; i++) {
                video_putchar(' ');
            }
            return;
        default:
            break;
    }

    vga_buffer[vga_row * VGA_WIDTH + vga_col] = vga_entry(c, vga_color);
    vga_col++;
    if (vga_col >= VGA_WIDTH) {
        video_newline();
    }
}

void video_write(const char *str) {
    while (*str) {
        video_putchar(*str++);
    }
}
