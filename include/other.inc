;============================================================================;
; RatOS (C) 2022-2023                                                        ;
; Все права защищены                                                         ;
;============================================================================;

; файл other.inc
; этот код нужен для поддержки корректной работы прерываний

; автор:     xxx_Matvey_xxx и mc_Bagira

; история:   08.01.2023 - дата создания

;============================================================================;
; определения                                                                ;
;============================================================================;

  ; порты ввода\вывода для управления PIC

  IOportPIC1RegCommand     = 0x20 ; OCW2, OCW3, ICW1 (для записи)
  IOportPIC1RegStatus      = 0x20 ; OCW3 (для чтения)

  IOportPIC2RegCommand     = 0xA0 ; см. выше ^
  IOportPIC2RegStatus      = 0xA0 ; ...

  IOportPIC1MaskingInterr  = 0x21 ; OCW1 (для чтения и записи)
  IOportPIC2MaskingInterr  = 0xA1 ; см. выше ^

  IOportPIC1InitController = 0x21 ; ICW2, ICW3, ICW4 (для записи)
  IOportPIC2InitController = 0xA1 ; см. выше ^

  ; команды для отправки EOI контроллеру PIC

  commandNonSpecificEOI    = 0x20 ; отправка неспецифичного EOI

  ; номера векторов прерываний

  ; ---------------------> ведущий контроллер PIC

  interruptTimer           = 8    ; IRQ0 - таймер (PIT)
  interruptKeyboard        = 9    ; IRQ1 - клавиатура
  interruptSlavePIC        = 10   ; IRQ2 - подчинненый контроллер PIC
  interruptCOM1            = 11   ; IRQ3 - COM1\COM4 порты
  interruptCOM2            = 12   ; IRQ4 - COM2\COM3 порты
  interruptLPT2            = 13   ; IRQ5 - LPT2 порт
  interruptFloppy          = 14   ; IRQ6 - контроллер дискет (флоппи)
  interruptLPT1            = 15   ; IRQ7 - LPT1 порт

  ; ---------------------> подчинненый контроллер PIC

  interruptRTCTimer        = 0x70 ; IRQ8 - RTC таймер
  interruptReserv1         = 0x71 ; IRQ9 - свободно
  interruptReserv2         = 0x72 ; IRQ10 - свободно
  interruptReserv3         = 0x73 ; IRQ11 - свободно
  interruptMouse           = 0x74 ; IRQ12 - мышь
  interruptCoproccesor     = 0x75 ; IRQ13 - математический сопроцессор
  interruptHardDrive1      = 0x76 ; IRQ14 - контроллер жесткого диска 1
  interruptHardDrive2      = 0x77 ; IRQ15 - контроллер жесткого диска 2

  ; ---------------------> прерывания для RatOS

  videoInterrupt           = 0x40 ; прерывание для поддержки видео
  diskInterrupt            = 0x41 ; прерывание для поддержки работы диска
  RatOSInterrupt           = 0x42 ; прерывание для служебных нужд RatOS
  RatOS1Interrupt          = 0x43 ; прерывание для дополнительных нужд RatOS
  programmInterrupt        = 0x44 ; прерывание для поддержки внутренней API

  ; ---------------------> BIOS-прерывания

  interruptDivideByZero    = 0    ; исключение деления на ноль
  interruptSingleStep      = 1    ; одиночный шаг
  interruptNonMaskable     = 2    ; немаскированное прерывание
  interruptBreakpoint      = 3    ; точка останова (отладка)
  interruptOverflow        = 4    ; исключение переполнения

  interruptPrintScreen     = 5    ; снимок экрана

  interruptInvalidOpcode   = 6    ; исключение неверный опкод
  interruptCoproccesorNotFound = 7 ; исключение сопроцессор не найден

  ; interruptVBIOS         = 0x10 ; видео подсистема

  interruptEquipmentDetermination = 0x11 ; определение оборудования
  interruptMemorySize      = 0x12 ; размер ОЗУ

  ; interruptDiskBios      = 0x13 ; дисковая подсистема

  interruptSerialComm      = 0x14 ; последовательная связь

  interruptSystemServices  = 0x15 ; системные сервисы и управление кассет
  interruptKeyboardServices = 0x16 ; клавиатурные сервисы

  interruptParallelPrinter = 0x17 ; параллельный принтер

  interruptROMBasic        = 0x18 ; ROM BASIC загрузчик
  interruptBootstrapLoader = 0x19 ; загрузчик начальной загрузки

  interruptTimeOfDay       = 0x1A ; время суток

  interruptCtrlBreak       = 0x1B ; определяемый пользователем обработчик ctrl-break
  interruptClockTick       = 0x1C ; определяемый пользователем обработчик тактовых импульсов

  interruptVideoParameterPointer = 0x1D ; 6845 указатель параметров видео
  interruptDisketteParameterPointer = 0x1E ; указатель параметров дискеты (базовая таблица)

  interruptGraphicsCharacterTable = 0x1F ; таблица графических символов

  interruptHardDriveBIOS   = 0x40 ; жесткий диск
  interruptFixedDisk0ParametersPointer = 0x41 ; указатель параметров фиксированного диска 0

  interruptRelocatedVideoHandler = 0x42 ; перемещенный обработчик видео (EGA/VGA/PS)
  interruptUserFontTable   = 0x43 ; таблица пользовательских шрифтов (EGA/VGA/PS)
  interruptFirstGraphicsCharacters = 0x44 ; первые 128 графических символов (также Netware)

  interruptFixedDisk1ParametersPointer = 0x46 ;  указатель параметров фиксированного диска 1

  interruptPCjrCordlessKeyboard = 0x48 ; Перевод беспроводной клавиатуры PCjr
  interruptPCjrNonkeyboard = 0x49 ; таблица перевода скан-кода без клавиатуры PCjr

  interruptUserAlarm       = 0x4A ; пользовательская сигнализация (AT,CONV,PS/2)
  interruptPeriodicAlarm   = 0x50 ; периодическая тревога от таймера (PS/2)

