; Titan Kernel - Stage 1 Bootloader

[BITS 16]
[ORG 0x7C00]

STAGE2_LOAD_SEGMENT equ 0x0000
STAGE2_LOAD_OFFSET  equ 0x7E00

jmp short start
nop

OEMLabel            db "TITANOS "   
BytesPerSector      dw 512
SectorsPerCluster   db 1
ReservedSectors     dw 1
NumberOfFATs        db 2
RootDirEntries      dw 224
TotalSectors        dw 2880
MediaDescriptor     db 0xF0
SectorsPerFAT       dw 9
SectorsPerTrack     dw 18
NumberOfHeads       dw 2
HiddenSectors       dd 0
TotalSectorsBig     dd 0
DriveNumber         db 0
Reserved1           db 0
BootSignatureBPB    db 0x29
VolumeID            dd 0x12345678
VolumeLabel         db "TITANOS    " 
FileSystemType       db "FAT12   "    

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [BootDrive], dl

    mov si, msgLoading
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

    mov ax, [RootDirLBA]
    mov cx, [RootDirSectors]
    mov bx, 0x8000
    call read_sectors_lba

    mov cx, [RootDirEntries]
    mov di, 0x8000
.search_loop:
    push cx
    mov cx, 11
    mov si, stage2Name
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
    mov ax, [di + 26]
    mov [Stage2Cluster], ax

    mov ax, [ReservedSectors]
    mov cx, [SectorsPerFAT]
    mov bx, 0x9000
    call read_sectors_lba
    mov [FATBufferSeg], word 0
    mov word [FATBufferOff], 0x9000

    mov ax, STAGE2_LOAD_SEGMENT
    mov es, ax
    mov bx, STAGE2_LOAD_OFFSET

.load_cluster:
    mov ax, [Stage2Cluster]
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

    mov ax, [Stage2Cluster]
    mov cx, ax
    shr ax, 1
    add ax, cx              
    mov si, ax
    mov ax, [0x9000 + si]  
    test cx, 1
    jz .even
    shr ax, 4
    jmp .store_next
.even:
    and ax, 0x0FFF
.store_next:
    mov [Stage2Cluster], ax
    jmp .load_cluster

.done_loading:
    mov si, msgOK
    call print_string

    xor ax, ax
    mov es, ax
    mov dl, [BootDrive]
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

read_sectors_lba:
    push ax
    xor ax, ax
    mov es, ax
    pop ax
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
    div word [NumberOfHeads]     ; ax = cylinder, dx = head
    mov ch, al                   ; low 8 bits of cylinder
    mov dh, dl                   ; head
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
    int 0x13                     ; reset disk
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

msgLoading   db "Loading Titan OS...", 13, 10, 0
msgOK        db "Stage 2 loaded.", 13, 10, 0
msgError     db "Disk error!", 13, 10, 0
stage2Name   db "STAGE2  BIN"

BootDrive       db 0
RootDirLBA      dw 0
RootDirSectors  dw 0
DataAreaLBA     dw 0
Stage2Cluster   dw 0
FATBufferSeg    dw 0
FATBufferOff    dw 0

times 510-($-$$) db 0
dw 0xAA55
