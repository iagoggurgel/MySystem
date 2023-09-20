org 0x7c00                          ; carregado pela BIOS no endereço 0x7c00

bits 16                             ; modo real de 16 bits

start:      jmp main

;*************************************************;
;	Organização do disco
;*************************************************;

TIMES 0Bh-$+start DB 0

bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	    DB 2
bpbRootEntries: 	    DW 224
bpbTotalSectors: 	    DW 2880
bpbMedia: 	            DB 0xF0
bpbSectorsPerFAT: 	    DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors: 	    DD 0
bpbTotalSectorsBig:     DD 0
bsDriveNumber: 	        DB 0
bsUnused: 	            DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "MOS FLOPPY "
bsFileSystem: 	        DB "FAT12   "


msg_welcome db "Bem-vindo ao meu sistema operacional!", 0
msg_error db "Erro na leitura do disco!", 0


;************;
;  Print     ;

Print:

    lodsb
    or al, al
    jz PrintDone
    mov ah, 0eh
    int 10h
    jmp Print
PrintDone:
    ret

floppyError:
    mov si, msg_error
    call Print
    jmp waitAndReboot

waitAndReboot:
    mov ah, 0
    int 0x16
    jmp 0xFFFF:0

.halt:
    cli
    hlt

;
; Disk Routines
;

; Converte endereço LBA para endereço CHS
; Paramêtros:
; - ax : LBA address
; Returns:
; - cx[0 - 5 bits]: sector number
; - cx[6 - 15]: cylinder number
; - dh: head number


lbaToChs:

    push ax
    push dx

    xor dx, dx
    div word [bpbSectorsPerTrack]

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bpbHeadsPerCylinder]
    
    mov dh, dl
    mov ch, al
    shl al, 6
    or cl, ah
    
    pop ax
    mov dl, al
    pop ax
    ret

diskRead:

    push ax
    push bx
    push cx
    push dx
    push di


    push cx
    call lbaToChs
    pop ax

    mov ah, 0x02
    mov di, 3


.retry:
    pusha
    stc 
    int 0x13
    jnc .done

    popa
    call diskReset

    dec di
    test di, 0
    jnz .retry

.fail:
    jmp floppyError

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

diskReset:
    pusha
    mov ah, 0
    stc 
    int 0x13
    jc floppyError
    popa
    ret

main: 

    xor ax, ax ; limpa ax
    mov ds, ax ; move conteúdo de ax para ds
    mov es, ax

    mov ss, ax
    mov sp, 0x7c00

    mov [bsDriveNumber], dl
    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call diskRead

    mov si, msg_welcome
    call Print

    xor ax, ax
    int 0x12

    cli     ; limpa interrupções
    hlt     ; para o sistema

times 510 - ($-$$) db 0     ; o programa deve atingir 512 bytes então colocamos zero no que não for usado.

dw 0xAA55