; label1 - если ASCII-символ, label2 - если не ASCII-символ
macro CHECK_ASCII symbol, label1, label2
{
      mov  al, symbol
      call checkASCII

      cmp  ax, 0
      je   label1

      jmp  label2
}

; label1 - если A-Z, label2 - если a-z, label3 - если не вообще ASCII-символ, label4 - если символ не AAZZaazz
macro CHECK_azAZ symbol, label1, label2, label3, label4
{
      mov  al, symbol
      call checkAZaz

      cmp  ax, 0
      je   label1

      cmp  ax, 1
      je   label2

      cmp  ax, 2
      je   label3

      jmp  label4
}

; label1 - если A-Z, label2 - если a-z
macro CHECK_azAZ_SHORT symbol, label1, label2
{
      mov  al, symbol
      call checkAZaz

      cmp  ax, 0
      je   label1

      jmp  label2
}

macro HEX2ASCIIBYTE symbol
{
      mov al, symbol
      call hex2asciiByte
}

macro HEX2ASCIIWORD symbol
{
      mov ax, symbol
      call hex2asciiWord
}

macro HEX2ASCII array, buffer, size
{
      PUSH    ax, bx, cx, dx, si, di

      mov si, array
      mov di, buffer
      mov cx, size
      call hex2ascii

      POP     di, si, dx, cx, bx, ax
}

macro HEX2DEC number, buffer
{
      PUSH    ax, bx, cx, dx, si, di

      mov ax, number
      mov di, buffer
      call hex2dec

      POP     di, si, dx, cx, bx, ax
}