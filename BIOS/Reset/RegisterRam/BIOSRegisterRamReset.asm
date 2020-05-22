; Game Boy Advance 'Bare Metal' BIOS Functions Register Ram Reset demo by krom (Peter Lemon):

format binary as 'gba'
include 'LIB\FASMARM.INC'
include 'LIB\LCD.INC'
include 'LIB\MEM.INC'
include 'LIB\DMA.INC'
include 'LIB\TIMER.INC'

macro PrintString Source, Destination, Length, Palette { ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  local .LoopChar
  imm32 r8,Source       ; Source Address
  mov r9,VRAM           ; Video RAM
  imm32 r10,Destination ; Destination Address
  add r9,r10            ; Video RAM += Destination Address
  mov r10,Length        ; String Length
  mov r11,Palette*4096  ; Palette Number << 12
  .LoopChar:
    ldrb r12,[r8],1 ; Load Character, Increment String Source Address
    orr r12,r11     ; OR Palette Number
    strh r12,[r9],2 ; Store Character To Map Data, Increment VRAM Destination Address
    subs r10,1      ; Decrement String Length, Compare String Length To Zero
    bne .LoopChar   ; IF(String Length != 0) Loop Character
}

macro PrintValue Source, Destination, Length, Palette { ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number
  local .LoopChar
  imm32 r7,Source      ; Source Address
  mov r8,VRAM          ; Video RAM
  imm32 r9,Destination ; Destination Address
  add r8,r9            ; Video RAM += Destination Address
  mov r9,Length-1      ; Value Length - 1
  mov r10,Palette*4096 ; Palette Number << 12
  mov r11,"$"          ; Load Character
  orr r11,r10          ; OR Palette Number
  strh r11,[r8],2      ; Store Character To Map Data, Increment VRAM Destination Address
  .LoopChar:
    ldrb r11,[r7,r9] ; Load Character
    lsr r12,r11,4    ; Hi Nibble
    cmp r12,9        ; Compare Hi Nibble To 9
    addle r12,$30    ; IF(Hi Nibble <= 9) Hi Nibble += ASCII Number
    addgt r12,$37    ; IF(Hi Nibble > 9)  Hi Nibble += ASCII Letter
    orr r12,r10      ; OR Palette Number
    strh r12,[r8],2  ; Store Character To Map Data, Increment VRAM Destination Address
    and r11,$F       ; Lo Nibble
    cmp r11,9        ; Compare Lo Nibble To 9
    addle r11,$30    ; IF(Lo Nibble <= 9) Lo Nibble += ASCII Number
    addgt r11,$37    ; IF(Lo Nibble > 9)  Lo Nibble += ASCII Letter
    orr r11,r10      ; OR Palette Number
    strh r11,[r8],2  ; Store Character To Map Data, Increment VRAM Destination Address
    subs r9,1        ; Decrement Value Length, Compare Value Length To Zero
    bge .LoopChar    ; IF(Value Length >= 0) Loop Character
}

org $8000000
b copycodeIWRAMEND
times $80000C0-($-0) db 0

copycodeIWRAMEND:
  adr r0,startcodeIWRAMEND
  imm32 r1,IWRAM+$7E00
  imm32 r2,endcopyIWRAMEND
  clpIWRAMEND:
    ldr r3,[r0],4
    str r3,[r1],4
    cmp r1,r2
    bmi clpIWRAMEND
  imm32 r0,startIWRAMEND
  bx r0

copycode:
  adr r0,startcode
  mov r1,IWRAM
  imm32 r2,endcopy
  clp:
    ldr r3,[r0],4
    str r3,[r1],4
    cmp r1,r2
    bmi clp
  imm32 r0,start
  bx r0

startcodeIWRAMEND:
  org IWRAM+$7E00

startIWRAMEND:
  mov r0,00000010b ; Clear IWRAM

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMERIWRAM
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control


  mov r0,00001000b ; Clear VRAM

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMERVRAM
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  imm32 r0,copycode
  bx r0

TIMERIWRAM: dw 0
TIMERVRAM:  dw 0

endcopyIWRAMEND: ; End Of Program Copy Code


org startcodeIWRAMEND + (endcopyIWRAMEND - (IWRAM+$7E00))
startcode:
  org IWRAM

start:
  PrintString TitleTEXT, 4096, 24, 4 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString LineBreakTEXT, 4160, 30, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString RegRamResetTEXT, 4224, 23, 5 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TestTEXT, 4274, 4, 3 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  imm32 r0,00000001b ; Clear WRAM

  PrintString InputTEXT, 4292, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 4304, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 4314, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString WRAMTEXT, 4338, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMER
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  PrintString OutputTEXT, 4354, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 4368, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMER, 4386, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMER ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$A0FA ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILA  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 4402, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDA
  TestFAILA:
    PrintString FailTEXT, 4402, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDA:


  imm32 r0,00000010b ; Clear IWRAM

  PrintString InputTEXT, 4420, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 4432, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 4442, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString IWRAMTEXT, 4464, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  PrintString OutputTEXT, 4482, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 4496, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMERIWRAM, 4514, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMERIWRAM ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$342A ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILB  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 4530, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDB
  TestFAILB:
    PrintString FailTEXT, 4530, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDB:


  imm32 r0,00000100b ; Clear VPAL

  PrintString InputTEXT, 4548, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 4560, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 4570, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString VPALTEXT, 4594, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMER
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  PrintString OutputTEXT, 4610, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 4624, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMER, 4642, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMER ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$039A ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILC  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 4658, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDC
  TestFAILC:
    PrintString FailTEXT, 4658, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDC:


  imm32 r0,00001000b ; Clear VRAM

  PrintString InputTEXT, 4676, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 4688, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 4698, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString VRAMTEXT, 4722, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  PrintString OutputTEXT, 4738, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 4752, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMERVRAM, 4770, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMERVRAM ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$FCFA ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILD  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 4786, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDD
  TestFAILD:
    PrintString FailTEXT, 4786, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDD:


  imm32 r0,00010000b ; Clear OAM

  PrintString InputTEXT, 4804, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 4816, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 4826, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString OAMTEXT, 4852, 3, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMER
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  PrintString OutputTEXT, 4866, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 4880, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMER, 4898, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMER ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$029A ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILE  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 4914, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDE
  TestFAILE:
    PrintString FailTEXT, 4914, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDE:


  imm32 r0,00100000b ; Reset SIO Registers

  PrintString InputTEXT, 4932, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 4944, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 4954, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString SIOTEXT, 4980, 3, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMER
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  PrintString OutputTEXT, 4994, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 5008, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMER, 5026, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMER ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$0154 ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILF  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 5042, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDF
  TestFAILF:
    PrintString FailTEXT, 5042, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDF:


  imm32 r0,01000000b ; Reset SOUND Registers

  PrintString InputTEXT, 5060, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 5072, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 5082, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString SOUNDTEXT, 5104, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMER
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  PrintString OutputTEXT, 5122, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 5136, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMER, 5154, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMER ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$0185 ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILG  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 5170, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDG
  TestFAILG:
    PrintString FailTEXT, 5170, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDG:


  imm32 r0,10000000b ; Reset OTHER Registers

  PrintString InputTEXT, 5188, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString R0TEXT, 5200, 4, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  imm32 r9,VALUE
  str r0,[r9]
  PrintValue VALUE, 5210, 4, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  PrintString OTHERTEXT, 5232, 5, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number

  mov r10,IO ; GBA I/O Base Offset
  orr r11,r10,TM0CNT             ; Timer 0 Control Register
  mov r12,TM_ENABLE or TM_FREQ_1 ; Timer 0 Enable, Frequency/1
  str r12,[r11]                  ; Start Timer 0

  swi $010000 ; BIOS Function

  ldr r10,[r11] ; Load  Timer 0 Value
  imm32 r9,TIMER
  str r10,[r9]  ; Store Timer 0 Value
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer 0 Control

  PrintString OutputTEXT, 5250, 6, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintString TimerTEXT, 5264, 8, 0 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  PrintValue TIMER, 5282, 2, 2 ; Print Value: Source Address, VRAM Destination, Value Length, Palette Number

  imm32 r9,TIMER ; Load Result
  ldr r4,[r9]
  lsl r4,16
  lsr r4,16
  imm16 r9,$01AB ; Load Test Check
  cmp r4,r9      ; Compare Result
  bne TestFAILH  ; IF(Check != Result) FAIL, ELSE PASS
  PrintString PassTEXT, 5298, 4, 2 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  b TestENDH
  TestFAILH:
    PrintString FailTEXT, 5298, 4, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number
  TestENDH:


  PrintString LineBreakTEXT, 5312, 30, 1 ; Print String: Source Address, VRAM Destination, String Length, Palette Number


  mov r0,IO
  mov r1,MODE_0
  orr r1,BG0_ENABLE
  str r1,[r0]

  imm16 r1,0000001000000000b ; BG Tile Offset = 0, Tiles 4BPP, BG Map Offset = 4096, Map Size = 32x32 Tiles
  str r1,[r0,BG0CNT]

  mov r0,VPAL        ; Load Color Mem Address
  imm32 r1,$7FFF7C00 ; Load  BG Font White Palette & Blue BG Color Zero
  str r1,[r0],32     ; Store BG Font Palette To Color Mem, Increment Color Mem Address To Next 4BPP Palette
  imm32 r1,$001F0000 ; Load  BG Font Red Palette
  str r1,[r0],32     ; Store BG Font Palette To Color Mem, Increment Color Mem Address To Next 4BPP Palette
  imm32 r1,$03E00000 ; Load  BG Font Green Palette
  str r1,[r0],32     ; Store BG Font Palette To Color Mem, Increment Color Mem Address To Next 4BPP Palette
  imm32 r1,$03FF0000 ; Load  BG Font Yellow Palette
  str r1,[r0],32     ; Store BG Font Palette To Color Mem, Increment Color Mem Address To Next 4BPP Palette
  imm32 r1,$7C1F0000 ; Load  BG Font Purple Palette
  str r1,[r0],32     ; Store BG Font Palette To Color Mem, Increment Color Mem Address To Next 4BPP Palette
  imm32 r1,$7FE00000 ; Load  BG Font Cyan Palette
  str r1,[r0],32     ; Store BG Font Palette To Color Mem, Increment Color Mem Address To Next 4BPP Palette
  DMA32 FONTIMG, VRAM, 1024 ; DMA BG 4BPP 8x8 Tile Font Character Data To VRAM

Loop:
  b Loop

VALUE: dw 0
TIMER: dw 0

endcopy: ; End Of Program Copy Code

; Static Data (ROM)
org startcode + (endcopy - IWRAM)
FONTIMG: file 'Font8x8.img'      ; Include BG 4BPP 8x8 Tile Font Character Data (4096 Bytes)
TitleTEXT:       db "GBA BIOS Reset Functions"       ; Include BG Map Text Data (24 Bytes)
LineBreakTEXT:   db "------------------------------" ; Include BG Map Text Data (30 Bytes)
RegRamResetTEXT: db "Register RAM Reset $01:"        ; Include BG Map Text Data (23 Bytes)

InputTEXT:  db "INPUT"    ; Include BG Map Text Data (5 Bytes)
OutputTEXT: db "OUTPUT"   ; Include BG Map Text Data (6 Bytes)
R0TEXT:     db "R0 ="     ; Include BG Map Text Data (4 Bytes)
TimerTEXT:  db "TIMER0 =" ; Include BG Map Text Data (8 Bytes)

TestTEXT:   db "TEST" ; Include BG Map Text Data (4 Bytes)
PassTEXT:   db "PASS" ; Include BG Map Text Data (4 Bytes)
FailTEXT:   db "FAIL" ; Include BG Map Text Data (4 Bytes)

WRAMTEXT:   db "WRAM"  ; Include BG Map Text Data (4 Bytes)
IWRAMTEXT:  db "IWRAM" ; Include BG Map Text Data (5 Bytes)
VPALTEXT:   db "VPAL"  ; Include BG Map Text Data (4 Bytes)
VRAMTEXT:   db "VRAM"  ; Include BG Map Text Data (4 Bytes)
OAMTEXT:    db "OAM"   ; Include BG Map Text Data (3 Bytes)
SIOTEXT:    db "SIO"   ; Include BG Map Text Data (3 Bytes)
SOUNDTEXT:  db "SOUND" ; Include BG Map Text Data (5 Bytes)
OTHERTEXT:  db "OTHER" ; Include BG Map Text Data (5 Bytes)