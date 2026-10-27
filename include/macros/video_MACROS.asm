macro PRINT msg, coordXY, colour
{
      PUSH    ax, bx, cx, dx, si, di

      mov     ah, colour
      mov     cx, coordXY
      mov     si, msg
      call    print

      POP     di, si, dx, cx, bx, ax
}

macro PRINTB symbol, coordXY, colour
{
      PUSH    ax, bx, cx, dx, si, di

      mov     ah, colour
      mov     al, symbol
      mov     cx, coordXY
      call    printB

      POP     di, si, dx, cx, bx, ax
}

macro PRINTW symbol, coordXY, colour
{
      PUSH    ax, bx, cx, dx, si, di

      mov     ah, colour
      mov     bx, symbol
      mov     cx, coordXY
      call    printW

      POP     di, si, dx, cx, bx, ax
}

macro PRINTD symbol, coordXY, colour
{
      PUSH    ax, bx, cx, dx, si, di

      mov     ebx, symbol

      push    ebx
      xor     bx, bx

      shr     ebx, 16
      mov     ah, colour
      mov     cx, coordXY
      call    printW

      pop     ebx
      call    printW

      POP     di, si, dx, cx, bx, ax
}

macro PRINTS msg, size, coordXY, colour
{
      PUSH    ax, bx, cx, dx, si, di

      mov     ah, colour
      mov     cx, coordXY
      mov     si, msg
      mov     bx, size
      call    printS

      POP     di, si, dx, cx, bx, ax
}