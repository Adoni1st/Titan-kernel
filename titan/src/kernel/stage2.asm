; Titan Kernel - Stage 2 Bootloader

[BITS 16]
[ORG 0x7E00]

KERNEL_TMP_SEGMENT  equ 0x1000     
KERNEL_TMP_LINEAR   equ 0x10000
KERNEL_FINAL_LINEAR equ 0x100000
KERNEL_STACK_TOP    equ 0x90000

ROOTDIR_SEGMENT     equ 0x2000      
FAT_SEGMENT         equ 0x2200      

start:
   mov [BootDrive], dl
    xor ax, ax
    mov ds, ax

    mov si, msgStage2
    call print_string

    xor bx, bx
    mov bl, [NumberOfFATs]
    mov ax, bx
    mov cx, [SectorsPerFAT]
    mul cx                    
    add ax, [ReservedSectors] 
    mov [RootDirLBA], ax

    mov ax, [RootDirEntries]
    mov cx, 32
    mul cx
    add ax, 511
    adc dx, 0
    mov cx, 512
    div cx
    mov [RootDirSectors], ax

    mov ax, [RootDirLBA]
    add ax, [RootDirSectors]
    mov [DataAreaLBA], ax

    mov ax, ROOTDIR_SEGMENT
    mov es, ax
    mov ax, [RootDirLBA]
    mov cx, [RootDirSectors]
    xor bx, bx
    call read_sectors_lba_es   

    mov cx, [RootDirEntries]
    xor di, di
.search_loop:
    push cx
    mov cx, 11
    mov si, kernelName
    push di
    repe cmpsb
    pop di
    je .found
    pop cx
    add di, 32
    loop .search_loop
    jmp disk_error

.found:
    pop cx
    mov ax, [es:di + 26]        
    mov [KernelCluster], ax
    mov eax, [es:di + 28]      
    mov [KernelSize], eax

    mov ax, FAT_SEGMENT
    mov es, ax
    mov ax, [ReservedSectors]
    mov cx, [SectorsPerFAT]
    xor bx, bx
    call read_sectors_lba_es

    mov ax, KERNEL_TMP_SEGMENT
    mov es, ax
    xor bx, bx

.load_cluster:
    mov ax, [KernelCluster]
    cmp ax, 0x0FF8
    jae .done_loading

    sub ax, 2
    xor cx, cx
    mov cl, [SectorsPerCluster]
    mul cx
    add ax, [DataAreaLBA]
    mov cx, 1
    call read_sectors_lba_es

    add bx, 512
    jnc .no_seg_fix
    mov ax, es
    add ax, 0x1000
    mov es, ax
    xor bx, bx
.no_seg_fix:

    mov ax, [KernelCluster]
    mov cx, ax
    shr ax, 1
    add ax, cx             
    mov si, ax
    push es
    mov ax, FAT_SEGMENT
    mov es, ax
    mov ax, [es:si]
    pop es
    test cx, 1
    jz .even
    shr ax, 4
    jmp .store_next
.even:
    and ax, 0x0FFF
.store_next:
    mov [KernelCluster], ax
    jmp .load_cluster

.done_loading:
    mov si, msgKernelLoaded
    call print_string

    mov ax, 0x2401
    int 0x15

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:protected_mode_entry

read_sectors_lba_es:
    push ax
    push bx
    push cx
    push dx

.next_sector:
    push ax
    push cx

    xor dx, dx
    div word [SectorsPerTrack]
    inc dx
    mov cx, dx
    xor dx, dx
    div word [NumberOfHeads]
    mov ch, al
    mov dh, dl
    mov dl, [BootDrive]

    mov ah, 0x02
    mov al, 1
    mov si, 3
.retry:
    push ax
    int 0x13
    pop ax
    jnc .read_ok
    dec si
    jz disk_error
    xor ah, ah
    int 0x13
    jmp .retry
.read_ok:

    pop cx
    pop ax
    inc ax
    add bx, 512
    loop .next_sector

    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_error:
    mov si, msgError
    call print_string
    cli
    hlt
    jmp $

print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

[BITS 32]
protected_mode_entry:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, KERNEL_STACK_TOP

    mov esi, KERNEL_TMP_LINEAR
    mov edi, KERNEL_FINAL_LINEAR
    mov ecx, [KernelSize]
    add ecx, 3
    shr ecx, 2   
    cld
    rep movsd

    call KERNEL_FINAL_LINEAR

.hang:
    cli
    hlt
    jmp .hang

[BITS 16]
gdt_start:
gdt_null:
    dq 0
gdt_code:
    dw 0xFFFF       
    dw 0x0000      
    db 0x00        
    db 10011010b    
    db 11001111b    
    db 0x00      
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b    
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

BytesPerSector      dw 512
SectorsPerCluster   db 1
ReservedSectors     dw 1
NumberOfFATs        db 2
RootDirEntries      dw 224
SectorsPerFAT       dw 9
SectorsPerTrack     dw 18
NumberOfHeads       dw 2

msgStage2       db "Entered Stage 2.", 13, 10, 0
msgKernelLoaded db "Kernel loaded, entering protected mode...", 13, 10, 0
msgError        db "Disk error in Stage 2!", 13, 10, 0
kernelName      db "KERNEL  BIN"

BootDrive       db 0
RootDirLBA      dw 0
RootDirSectors  dw 0
DataAreaLBA     dw 0
KernelCluster   dw 0
KernelSize      dd 0

times 1024-($-$$) db 0
