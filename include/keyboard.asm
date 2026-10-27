;============================================================================;
; RatOS (C) 2022-2023                                                        ;
; Все права защищены                                                         ;
;============================================================================;

; файл keyboard.asm
; этот код нужен для поддержки клавиатуры

; автор:     xxx_Matvey_xxx и mc_Bagira

; история:   08.01.2023 - дата создания

;============================================================================;
; определения                                                                ;
;============================================================================;

  ; порты ввода\вывода для управления i8042 (клавиатуры)

  IOportKeyboardRegScancode = 0x60 ; порт ввода для получения сканкода клавиши
  IOportKeyboardRegCommand1 = 0x60 ; порт вывода для отправки команд

  IOportKeyboardRegStatus   = 0x64 ; порт ввода для получения статуса клавиатуры
  IOportKeyboardRegCommand2 = 0x64 ; порт вывода для отправки команд

  ; сканкоды клавиш (для IBM-совместимых клавиатур, набор 1)

  keyEnter                  = 0x1C ; enter
  keyBackspace              = 0x0E ; backspace
  keyEscape                 = 0x01 ; ESC
  keyTab                    = 0x0F ; TAB
  keyLCTRL                  = 0x1E ; левый CTRL
  keyLShift                 = 0x2A ; левый shift
  keyRShift                 = 0x36 ; правый shift
  keyLAlt                   = 0x38 ; левый alt
  keySpace                  = 0x39 ; пробел
  keyCapsLock               = 0x3A ; capsLock
  keyF1                     = 0x3B ; F1 (F10 - 0x44)
  keyNumLock                = 0x45 ; numLock
  keyPauseBreak             = 0x45 ; pause/break
  keyScrollLock             = 0x46 ; scrollLock
  keyHome                   = 0x47 ; home
  keyArrowUp                = 0x48 ; стрелка вверх
  keyPageUp                 = 0x49 ; pageUp
  keyArrowLeft              = 0x4B ; стрелка налево
  keyClear                  = 0x4C ; clear
  keyArrowRight             = 0x4D ; стрелка направо
  keyEnd                    = 0x4F ; end
  keyArrowDown              = 0x50 ; стрелка вниз
  keyPageDown               = 0x51 ; pageDown
  keyInsert                 = 0x52 ; insert
  keyDelete                 = 0x53 ; delete
  keyF11                    = 0x57 ; F11
  keyF12                    = 0x58 ; F12
  keyWinRight               = 0x5B ; правый win
  keyWinLeft                = 0x5C ; левый win
  keyF13                    = 0x7C ; F13 (F24 - 0X87)
  keyNumPadEnter            = 0x11C ; numPad enter
  keyCtrlRight              = 0x11D ; правый ctrl
  keyPrtSc                  = 0x137 ; prtSc
  keyAltRight               = 0x138 ; правый alt
  keyCtrlPauseBreak         = 0x146 ; ctrl+pause/break
  keyContextMenu            = 0x15D ; contextMenu


;============================================================================;
; код                                                                        ;
;============================================================================;

  ;=============================================================================;
  ;  обработчик аппаратного прерывания IRQ1 - клавиатура                        ;
  ;                                                                             ;
  ;  вход:         нет                                                          ;
  ;                                                                             ;
  ;  выход:        [scancodeKey] - сканкод клавиши *                            ;
  ;                [asciiCodeKey] - ASCII-код клавиши **                        ;
  ;                                                                             ;
  ;  алгоритм:     1) для получения сканкода клавиши, нужно прочитать порт      ;
  ;                   ввода 0x60                                                ;
  ;                2) для получения ASCII-код клавиши, нужно использовать xlat- ;
  ;                   таблицу                                                   ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   1) сканкод бывает трех видов:                                ;
  ;                   1. сканкод нажатой кнопки                                 ;
  ;                   2. сканкод отпускания кнопки (установлен самый старший    ;
  ;                      бит)                                                   ;
  ;                   3. сканкод расширенной кнопки (состоящий из нескольких    ;
  ;                      байт)                                                  ;
  ;                2) ASCII-код у определенных (управляющих и                   ;
  ;                   зарезервированных) клавиш должен быть равен нулю (0x00)   ;
  ;=============================================================================;
  irq1Keyboard:
           ; запоминаем регистры

           push    ax
           push    bx
           push    cx
           push    dx

           ; разблокируем прерывания

           sti

           ; сканкод

           in      al, IOportKeyboardRegScancode
           mov     [scancodeKey], al                     ; сохраняем его

           ; расширенный??

           cmp     al, 0xE0
           je      .extentedScancode

           test    [flagsScancode], 10b
           jnz     .getExtentedScancode

       .cont4:
           and     [flagsScancode], 11111101b

       .cont2:
           ; break-код??

           test    [scancodeKey], 0x80
           jnz     .changeBreak

           and     [flagsScancode], 11111110b

       .cont1:
           ; виртуальный сканкод

           push    ax

           mov     bx, tableXlatScancode2VirtScancode
           xlatb

           mov     [vScancodeKey], al

           ; ASCII-код

           pop     ax
           and     al, 0x7F

           mov     bx, tableXlatScancode2ASCII
           xlatb

           push    ax
           call    checkASCII

           cmp     ax, 1
           je      .change_ASCII

           pop     ax

           mov     [asciiCodeKey], al
           or      [flagsScancode], 1000b

        .cont3:
           ; устанавливаем флаг

           or      [systemFlags], 1b

           HEX2ASCIIBYTE [scancodeKey]
           PRINTW bx, (23 shl 8) or 63, white

           PRINTB [asciiCodeKey], (23 shl 8) or 66, white

           HEX2ASCIIBYTE [vScancodeKey]
           PRINTW bx, (23 shl 8) or 69, white

           ; управляющие кнопки??

           ;cmp     [vScancodeKey], 0x14
           ;je      .controlCapsLock

           ; конец прерывания
        .finish:

           mov     al, commandNonSpecificEOI             ; отправка неспецифичного EOI
           out     IOportPIC1RegCommand, al

           ; восстанавливаем регистры

           pop     dx
           pop     cx
           pop     bx
           pop     ax
           iret

  .changeBreak:
           or      [flagsScancode], 1b
           jmp     .cont1

  .extentedScancode:
           or      [flagsScancode], 10b
           ;and     [flagsScancode], 11111011b

           jmp     .cont3

  .getExtentedScancode:
           mov     bx, tableXlatExtScancode2VirtScancode
           mov     cx, 28
           xor     dx, dx

           .loop:
                   push    bx
                   add     bx, dx

                   cmp     al, [bx]
                   je      ..done

                   pop     bx
                   add     dx, 2

                   dec     cx
                   jz      ..noDone

                   jmp     .loop

           ..done:
                   inc     dx
                   mov     al, [bx]

                   pop     bx

                   mov     [vScancodeKey], al
                   and     [flagsScancode], 11111101b
                   jmp     .cont5

           ..noDone:
                   jmp     .cont3

  .change_ASCII:
           pop     ax

        .cont5:
           mov     [asciiCodeKey], 0
           and     [flagsScancode], 11110111b
           jmp     .cont3

  .controlCapsLock:
           test    [systemFlags], 10b
           jnz     .lowerCase

  .upperCase:
           mov     al, 0xED
           out     0x60, al

           nop

           mov     al,  100b
           out     0x60, al

           or      [systemFlags], 10b
           jmp     .finish

  .lowerCase:
           mov     al, 0xED
           out     0x60, al

           nop

           mov     al,  0
           out     0x60, al

           and     [systemFlags], 11111101b
           jmp     .finish


  ;=============================================================================;
  ;  обработчик аппаратного прерывания IRQ1 - клавиатура                        ;
  ;                                                                             ;
  ;  вход:         нет                                                          ;
  ;                                                                             ;
  ;  выход:        [scancodeKey] - сканкод клавиши *                            ;
  ;                [asciiCodeKey] - ASCII-код клавиши **                        ;
  ;                                                                             ;
  ;  алгоритм:     1) для получения сканкода клавиши, нужно прочитать порт      ;
  ;                   ввода 0x60                                                ;
  ;                2) для получения ASCII-код клавиши, нужно использовать xlat- ;
  ;                   таблицу                                                   ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   1) сканкод бывает трех видов:                                ;
  ;                   1. сканкод нажатой кнопки                                 ;
  ;                   2. сканкод отпускания кнопки (установлен самый старший    ;
  ;                      бит)                                                   ;
  ;                   3. сканкод расширенной кнопки (состоящий из нескольких    ;
  ;                      байт)                                                  ;
  ;                2) ASCII-код у определенных (управляющих и                   ;
  ;                   зарезервированных) клавиш должен быть равен нулю (0x00)   ;
  ;=============================================================================;
  irq1KeyboardShort:
           ; запоминаем регистры

           push    ax
           push    bx
           push    cx
           push    dx

           ; разблокируем прерывания

           sti

           ; сканкод

           in      al, IOportKeyboardRegScancode
           mov     [scancodeKey], al                     ; сохраняем его

           or      [systemFlags], 1b

           mov     bx, tableXlatScancode2ASCII
           xlatb

           push    ax
           call    checkASCII

           cmp     ax, 1
           je      .change_ASCII

           pop     ax

           mov     [asciiCodeKey], al
           mov     cx, 6000
           mov     ah, white
           call    printB
           or      [flagsScancode], 1000b

        .exit:
           mov     al, commandNonSpecificEOI             ; отправка неспецифичного EOI
           out     IOportPIC1RegCommand, al

           ; восстанавливаем регистры

           pop     dx
           pop     cx
           pop     bx
           pop     ax
           iret
        .change_ASCII:
            pop ax
            mov [asciiCodeKey], 0
            jmp .exit




  flagsScancode     db 0          ; 0-(1) break, (0) make
                                  ; 1-(1) расширенный, (0) обычный
                                  ; 2-(1) дополнительный, (0) расширенный\простой
                                  ; 3-(1) клавиша имеет свой ASCII-код, (0) не имеет

 ;---------------------------------------------------------------------------------------
 ;---------------------------------------------------------------------------------------

  ;=============================================================================;
  ;  функция получает и возвращает сканкод и ASCII-код клавиши до тех пор,      ;
  ;  пока любая кнопка нажмется                                                 ;
  ;                                                                             ;
  ;  вход:         нет                                                          ;
  ;                                                                             ;
  ;  выход:        [scancodeKey] - сканкод клавиши *                            ;
  ;                [asciiCodeKey] - ASCII-код клавиши                           ;
  ;                                                                             ;
  ;  алгоритм:     проверяем, была ли нажата\отпущена кнопка через системный    ;
  ;                флаг — systemFlags (обработчик прерывания IRQ1 устанавливает ;
  ;                0-вой бит этого флага каждый раз, пока он запускается).      ;
  ;                Если 0-вой бит установлен, то выходим, если сброшен, то      ;
  ;                продолжаем проверять                                         ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   1) функция не определяет сканкод отпускания клавиши          ;
  ;=============================================================================;
  getKeyLoop:
           ; проверяем 0-вой бит системного флага
           ; цикл
           .loop:
                   test    [systemFlags], 1b
                   jnz      .exit

                   jmp     .loop

           ; выход
           .exit:
                   ;test    byte [scancodeKey], 0x80    ; сканкод отпускания клавиши??
                   ;jnz     .loop                  ; если да, то продолжаем цикл

                   and     [systemFlags], 11111110b   ; сбрасываем бит
                   ret


 ;---------------------------------------------------------------------------------------
 ;---------------------------------------------------------------------------------------

  ;=============================================================================;
  ;  функция получает и возвращает сканкод и ASCII-код клавиши до тех пор,      ;
  ;  пока необходимая клавиша не нажмется                                       ;
  ;                                                                             ;
  ;  вход:         al - сканкод нужной клавиши                                  ;
  ;                                                                             ;
  ;  выход:        [scancodeKey] - сканкод клавиши *                            ;
  ;                [asciiCodeKey] - ASCII-код клавиши                           ;
  ;                                                                             ;
  ;  алгоритм:     проверяем, была ли нажата\отпущена кнопка через системный    ;
  ;                флаг — systemFlags (обработчик прерывания IRQ1 устанавливает ;
  ;                0-вой бит этого флага каждый раз, пока он запускается).      ;
  ;                Если 0-вой бит установлен, то выходим, если сброшен, то      ;
  ;                продолжаем проверять                                         ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   1) функция не определяет сканкод отпускания клавиши          ;
  ;=============================================================================;
  getNeedKeyLoop:
           ; проверяем 0-вой бит системного флага
           ; цикл
           .loop:
                   test    [systemFlags], 1b
                   jnz     .exit

                   jmp     .loop

           ; выход
           .exit:
                   ;test    byte [scancodeKey], 0x80    ; сканкод отпускания клавиши??
                   ;jnz     .loop                  ; если да, то продолжаем цикл

                   cmp     [scancodeKey], al      ; нужная клавиша??
                   jne     .loop                  ; если нет, то продолжаем цикл

                   and     [systemFlags], 11111110b   ; сбрасываем бит
                   ret


 ;---------------------------------------------------------------------------------------
 ;---------------------------------------------------------------------------------------

  ;=============================================================================;
  ;  функция выводит сообщение "command < "                                     ;
  ;                                                                             ;
  ;  вход:         нет                                                          ;
  ;                                                                             ;
  ;  выход:        нет                                                          ;
  ;                                                                             ;
  ;  алгоритм:     вывод сообщения                                              ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   нет                                                          ;
  ;=============================================================================;
  printCM:
           ; запоминаем регистры

           push    ax
           push    cx

           ; выводим сообщение

           ;inc     [currentY]
           ;inc     [currentY]

           mov     [currentX], 2
           mov     cx, word [currentX]

           mov     ah, lightGray
           mov     si, msgCommand
           call    print

           ;add     [currentX], 10

           ; переводим курсор

           mov     cx, word [currentX]
           call    moveCursorPosition

           ; восстанавливаем регистры

           pop     cx
           pop     ax
           ret


 ;---------------------------------------------------------------------------------------
 ;---------------------------------------------------------------------------------------

  ;=============================================================================;
  ;  функция очищает входной буфер клавиатуры                                   ;
  ;                                                                             ;
  ;  вход:         нет                                                          ;
  ;                                                                             ;
  ;  выход:        нет                                                          ;
  ;                                                                             ;
  ;  алгоритм:                                                                  ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   нет                                                          ;
  ;=============================================================================;
  clearInputKeyBuffer:
           ; запоминаем регистр

           push    bx

           ; указатель последнего символа

           movzx   bx, [lastSymbolBuffer]

           ; цикл
           .loop:
                   mov     [bufferKeyboard+bx], 0   ; очищаем буфер

                   dec     bx                       ; количество итераций
                   jz      .exit                    ; выходим, если все очищено

                   jmp     .loop                    ; продолжаем цикл

           ; выход
           .exit:
                   ; очищаем указатель последнего символа

                   mov     [lastSymbolBuffer], bl

                   ; восстанавливаем регистр

                   pop     bx
                   ret


 ;---------------------------------------------------------------------------------------
 ;---------------------------------------------------------------------------------------

  ;=============================================================================;
  ;  функция выводит ASCII-символ клавиши                                       ;
  ;                                                                             ;
  ;  вход:         нет                                                          ;
  ;                                                                             ;
  ;  выход:        флаг CF - (1) символ успешно записан                         ;
  ;                          (0) символ не был записан                          ;
  ;                                                                             ;
  ;  алгоритм:     проверяем, является ли ASCII-символ:                         ;
  ;                           1) цифрой (от "0" до "9");                        ;
  ;                           2) буквой (от "A" до "Z");                        ;
  ;                           3) знаком (любые графические знаки).              ;
  ;                                                                             ;
  ;                выводим символ, если результат проверки положителен          ;
  ;                                                                             ;
  ;  история:      01.01.2023 - дата создания                                   ;
  ;                                                                             ;
  ;  примечание:   нет                                                          ;
  ;=============================================================================;
  printKey:
           ; запоминаем регистры

           push    ax
           push    bx
           push    cx

           mov     al, [asciiCodeKey]

           ; проверяем ASCII-код

           test     [flagsScancode], 1000b
           jz       .exit

           ; break-код??

           test    [flagsScancode], 1b
           jnz      .exit

           ; проверяем регистр букв

           test    [systemFlags], 10b
           jz     .lowerCase

           ; выводим символ
           .print:

           mov     ah, lightGray
           mov     cx, word [currentX]
           call    printB

           ; записываем символ в буфер

           push    bufferKeyboard
           pop     bx

           push    ax

           movzx   ax, [lastSymbolBuffer]
           add     bx, ax

           pop     ax
           mov     [bx], al

           inc     [lastSymbolBuffer]

           ; увеличиваем координату X

           call    checkXY
           mov     word [currentX], cx

           ; перемещаем курсор в следующую позицию

           call    moveCursorPosition

           ; восстанавливаем регистры
           .exit:

           pop     cx
           pop     bx
           pop     ax
           ret

  .check:
           cmp     [asciiCodeKey], 0x7E
           jle     .print

           jmp     .exit

  .lowerCase:
           push    ax
           call    checkAZaz

           cmp     ax, 0
           jne     .doPrint

           pop     ax
           add     al, 0x20
           jmp     .print

  .doPrint:
           pop     ax
           jmp     .print

;============================================================================;
; переменные                                                                 ;
;============================================================================;
  scancodeKey       db 0  ; сканкод клавиши

  vScancodeKey      db 0          ; виртуальный сканкод клавиши
  asciiCodeKey      db 0          ; ASCII-код клавиши



  lastSymbolBuffer  db 0          ; смещение относительно буфера клавиатуры
  bufferKeyboard    rb 128        ; буфер обмена клавиатуры


;============================================================================;
; xlat-таблица для перевода сканкода в виртуальный сканкод                   ;
;============================================================================;
  tableXlatScancode2VirtScancode:
                           db   0     ; (0) нуль
                           db 0x1b

                           db   '1'   ; (2)
                           db   '2'   ; (3)
                           db   '3'   ; (4)
                           db   '4'   ; (5)
                           db   '5'   ; (6)
                           db   '6'   ; (7)
                           db   '7'   ; (8)
                           db   '8'   ; (9)
                           db   '9'   ; (10)
                           db   '0'   ; (11)

                           db 0xbd
                           db 0xbb
                           db 0x08
                           db 0x09

                           db 0x51
                           db 0x57
                           db 0x45
                           db 0x52
                           db 0x54
                           db 0x59
                           db 0x55
                           db 0x49
                           db 0x4f
                           db 0x50

                           db 0xdb
                           db 0xdd

                           db 0x0d
                           db 0xa2

                           db 0x41
                           db 0x53
                           db 0x44
                           db 0x46
                           db 0x47
                           db 0x48
                           db 0x4a
                           db 0x4b
                           db 0x4c

                           db 0xba
                           db 0xde
                           db 0xc0

                           db 0xa0

                           db 0xdc
                           db 0x5a
                           db 0x58
                           db 0x43
                           db 0x56
                           db 0x42
                           db 0x4e
                           db 0x4d

                           db 0xBC
                           db 0xbe

                           db 0xbf
                           db 0xa1

                           db 0x6a
                           db 0xa4

                           db 0x20
                           db 0x14

                           rept 9 tmp       ; F1-F10
                           {
                                db (tmp+0x70)
                           }

                           db 0x90
                           db 0x91

                           db 0x67
                           db 0x68
                           db 0x69

                           db 0x6d

                           db 0x64
                           db 0x65
                           db 0x66

                           db 0x6b

                           db 0x61
                           db 0x62
                           db 0x63
                           db 0x60

                           db 0x6e

                           db 0x7a
                           db 0x7b

                           times 3 db 0

                           db 0x5b
                           db 0x5c

                           times 32 db 0

                           rept 12 tmp       ; F13-F24
                           {
                                db (tmp+0x7C)
                           }

                           times 149 db 0

                           db 0x0d
                           db 0xa3

                           times 26 db 0

                           db 0x2c
                           db 0xa5

                           times 14 db 0
                           db 0x03

                           times 23 db 0
                           db 0x5d

  tableXlatExtScancode2VirtScancode:
                           db 0x5B, 0x5B
                           db 0x5C, 0x5C
                           db 0x38, 0xA5
                           db 0x5D, 0x5D
                           db 0x1D, 0xA3
                           db 0x4B, 0x25
                           db 0xD0, 0x28
                           db 0xC8, 0x26
                           db 0xCD, 0x27
                           db 0x1C, 0x1C
                           db 0xB5, 0x6F
                           db 0xC5, 0x90
                           db 0xC9, 0x21
                           db 0x51, 0x22
                           db 0xC7, 0x24
                           db 0x4F, 0x23
                           db 0x47, 0x24
                           db 0x52, 0x2D
                           db 0x53, 0x2E
                           db 0x37, 0x2C
                           db 0x6D, 0xB5
                           db 0x22, 0xB3
                           db 0x20, 0xAD
                           db 0x30, 0xAF
                           db 0x2E, 0xAE
                           db 0x66, 0xAB
                           db 0xEC, 0xB4
                           db 0x32, 0xAC


;============================================================================;
; xlat-таблица для перевода сканкода в ASCII-код                             ;
;============================================================================;
  tableXlatScancode2ASCII:
                           db   0     ; (0) нуль

                           db   0     ; (1) ESC

                           db   '1'   ; (2)
                           db   '2'   ; (3)
                           db   '3'   ; (4)
                           db   '4'   ; (5)
                           db   '5'   ; (6)
                           db   '6'   ; (7)
                           db   '7'   ; (8)
                           db   '8'   ; (9)
                           db   '9'   ; (10)
                           db   '0'   ; (11)

                           db   '-'   ; (12) или shift+- = '_'
                           db   '='   ; (13) или shift+= = '+'

                           db   0     ; (14) backspace
                           db   0     ; (15) TAB

                           db   'Q'   ; (16)
                           db   'W'   ; (17)
                           db   'E'   ; (18)
                           db   'R'   ; (19)
                           db   'T'   ; (20)
                           db   'Y'   ; (21)
                           db   'U'   ; (22)
                           db   'I'   ; (23)
                           db   'O'   ; (24)
                           db   'P'   ; (25)

                           db   '['   ; (26) или shift+[ = '{'
                           db   ']'   ; (27) или shift+] = '}'

                           db   0     ; (28) enter
                           db   0     ; (29) левый ctrl

                           db   'A'   ; (30)
                           db   'S'   ; (31)
                           db   'D'   ; (32)
                           db   'F'   ; (33)
                           db   'G'   ; (34)
                           db   'H'   ; (35)
                           db   'J'   ; (36)
                           db   'K'   ; (37)
                           db   'L'   ; (38)

                           db   ';'   ; (39) или shift+; = ':'
                           db   0x27  ; (40) (') или shift+' = '"'
                           db   '~'   ; (41) или shift+~ = '"'

                           db   0     ; (42) левый shift

                           db   '|'   ; (43)
                           db   'Z'   ; (44)
                           db   'X'   ; (45)
                           db   'C'   ; (46)
                           db   'V'   ; (47)
                           db   'B'   ; (48)
                           db   'N'   ; (49)
                           db   'M'   ; (50)

                           db   '<'   ; (51) или shift+< = ','
                           db   '.'   ; (52) или shift+. = '>'

                           db   '/'   ; (53) numpad

                           db   0     ; (54) правый shift

                           db   '*'   ; (55) numpad

                           db   0     ; (56) левый alt

                           db   ' '   ; (57)

                           db   0     ; (58) capslock

                           db   0     ; (59) F1
                           db   0     ; (60) F2
                           db   0     ; (61) F3
                           db   0     ; (62) F4
                           db   0     ; (63) F5
                           db   0     ; (64) F6
                           db   0     ; (65) F7
                           db   0     ; (66) F8
                           db   0     ; (67) F9
                           db   0     ; (68) F10

                           db   0     ; (69) numlock (или pause, break)
                           db   0     ; (70) scrol lock

                           db   '7'   ; (71) numpad (или home)

                           db   '8'   ; (72) numpad (или клавиша "вверх")
                           db   '9'   ; (73) numpad (или pageup)

                           db   '-'   ; (74) numpad

                           db   '4'   ; (75) numpad (или клавиша "влево")
                           db   '5'   ; (76) numpad (или clear)

                           db   '6'   ; (77) numpad (или клавиша "вправо")
                           db   '+'   ; (78) numpad

                           db   '1'   ; (79) numpad (или end)

                           db   '2'   ; (80) numpad (или клавиша "вниз")
                           db   '3'   ; (81) numpad (или pagedown)

                           db   '0'   ; (82) numpad (или insert)
                           db   '.'   ; (83) numpad или shift+numpad. = клавиша del

                           db   0     ; (87) F11
                           db   0     ; (88) F12

                           times 3 db 0     ; зарезервировано

                           db   0     ; (91) левый win
                           db   0     ; (92) правый win

                           times 32 db 0     ; зарезервировано

                           db   0     ; (124) F13
                           db   0     ; (125) F14
                           db   0     ; (126) F15
                           db   0     ; (127) F16
                           db   0     ; (128) F17
                           db   0     ; (129) F18
                           db   0     ; (130) F19
                           db   0     ; (131) F20
                           db   0     ; (132) F21
                           db   0     ; (133) F22
                           db   0     ; (134) F23
                           db   0     ; (135) F24

                           times 149 db 0     ; зарезервировано

                           db   0     ; (284) numpad enter
                           db   0     ; (285) правый ctrl

                           times 26 db 0     ; зарезервировано

                           db   0     ; (311) PrtSc
                           db   0     ; (312) правый alt

                           times 14 db 0     ; зарезервировано

                           db   0     ; (326) ctrl+pause/break

                           times 23 db 0     ; зарезервировано

                           db   0     ; (349) context menu



;============================================================================;
; файл "actionsKey.asm"                                                      ;
;============================================================================;
  include "%ProjectTEST%\CommandLine\actionsKey.asm"


;============================================================================;
; файл "actionsCommand.asm"                                                  ;
;============================================================================;
  include "%ProjectTEST%\CommandLine\actionsCommand.asm"

