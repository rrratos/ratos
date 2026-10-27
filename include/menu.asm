;============================================================================;
; RatOS (C) 2022-2023                                                        ;
; Все права защищены                                                         ;
;============================================================================;

; файл main.asm
; этот код нужен для запуска ОС

; автор: xxx_Matvey_xxx и mc_Bagira

; история: 17.03.2023 - дата создания

; алгоритм: рисуем графический интерфейс, подготавливаем работу программы, и
;           ждем действия пользователя

;

bufferCMline rb 3680
saveCMline:
                mov     si, bufferCMline
                mov     di, 320
                mov     cx, 3680
                push    es
                push    0xB800
                pop     es
                .loop:
                        mov      al, [es:di]
                        mov      [si], al
                        inc      di
                        inc      di
                        inc      si

                        dec      cx
                        jz       .exit
                        jmp      .loop
                .exit:
                pop     es
                ret

redrawCMline:
                mov     di, 320
                mov     si, bufferCMline
                mov     cx, 3680
                push    es
                push    0xb800
                pop     es
                .loop:
                        mov     al, [si]
                        mov     [es:di], al

                        inc     si
                        inc     di
                        inc     di

                        dec     cx
                        jz      .exit
                        jmp     .loop

                .exit:
                        pop     es
                        ret

actionToolComp:
                call    saveCMline

                mov     [.currentXY], (2 shl 8) or 2
                mov     cx, (2 shl 8) or 2

                mov     ah, (lightGray shl 4) or darkGray
                mov     bx, 20
                call    setAttribytesSymb

                .loop:
                call    getKeyLoop

                cmp     byte [scancodeKey], 0x2
                je      .up

                cmp     byte [scancodeKey], 0x3
                je      .down

                cmp     byte [scancodeKey], keyEnter
                je      .enter

                cmp     byte [scancodeKey], keyF1
                je      .exit

                jmp    .loop

.up:
                test    [.flags], 1b
                jnz      .loop

                shr     [.flags], 1

                mov     ah, (darkGray shl 4) or lightGray
                mov     cx, [.currentXY]
                ;dec     ch
                mov     bx, 20
                call    setAttribytesSymb

                mov     ah, (lightGray shl 4) or darkGray
                mov     cx, [.currentXY]
                dec     ch
                mov     bx, 20
                call    setAttribytesSymb

                dec     byte [.currentXY+1]

                jmp    .loop

.down:
                test    [.flags], 10b
                jnz      .loop

                shl     [.flags], 1

                mov     ah, (darkGray shl 4) or lightGray
                mov     cx, [.currentXY]
                ;inc     ch
                mov     bx, 20
                call    setAttribytesSymb

                mov     ah, (lightGray shl 4) or darkGray
                mov     cx, [.currentXY]
                inc     ch
                mov     bx, 20
                call    setAttribytesSymb

                inc     byte [.currentXY+1]

                jmp    .loop

.enter:
                test   [.flags], 1b
                jnz     .actionRun

                ;test   [.flags], 10b
                ;je     .actionParam

                jmp    .loop


.exit:
                call   redrawCMline
                jmp    main.wait

.actionRun:
                mov    si, msgRun
                mov    cx, 0
                mov    ah, lightGreen
                call   print
                jmp $

.flags db 1b
.currentXY dw 0

msgRun db "Runing..", 0
msgRunEnable db "run mode", 0