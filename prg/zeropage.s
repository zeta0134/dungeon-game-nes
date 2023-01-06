        .setcpu "6502"
        .include "zeropage.inc"
        .zeropage
; General purpose registers, used as sort of a quick stack alternative.
; Clobbered frequently.
R0: .byte $00
R1: .byte $00
R2: .byte $00
R3: .byte $00
R4: .byte $00
R5: .byte $00
R6: .byte $00
R7: .byte $00
R8: .byte $00
R9: .byte $00

R10: .byte $00
R11: .byte $00
R12: .byte $00
R13: .byte $00
R14: .byte $00
R15: .byte $00
R16: .byte $00
R17: .byte $00
R18: .byte $00
R19: .byte $00

R20: .byte $00
R21: .byte $00
R22: .byte $00
R23: .byte $00
R24: .byte $00
R25: .byte $00
R26: .byte $00
R27: .byte $00
R28: .byte $00
R29: .byte $00

R30: .byte $00
R31: .byte $00
R32: .byte $00

; Gameplay and graphics globals
GameloopCounter: .byte $00
LastNmi: .byte $00
NmiSoftDisable: .byte $00